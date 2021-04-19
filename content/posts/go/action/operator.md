---
title: "我无语了，Go 中 +-*/ 四个运算符竟然可以连着用"
date: 2021-03-31T20:30:00+08:00
toc: true
isCJKLanguage: true
tags:
  - Go
  - 面试题
---

大家好，我是站长 polarisxu。

我计划把类似这样的文章归为：奇淫技巧，你认同吗？

看到 Go101（玩 twtter 的可以关注他） 发了一条消息，`+-*/` 这四个竟然可以连着写：

```go
package main

func main() {
    v := new(int)
    *v = 2
    println(5/+-*v)
}
```

我看到后，试着运行了一下，竟然输出了 -2 。。。我忍不住“卧槽”。。。

我不得不说，Go101 扣的真细节。

于是我尝试着找一些线索，看看为什么可以这样写。

## 01 直接看汇编

遇到一些不解的地方，有时候借助汇编也许能得到答案：

```bash
go tool compile -S main.go
```

看关键的几行汇编：

```bash
	0x001d 00029 (main.go:6)	PCDATA	$1, $0
	0x001d 00029 (main.go:6)	NOP
	0x0020 00032 (main.go:6)	CALL	runtime.printlock(SB)
	0x0025 00037 (main.go:6)	MOVQ	$-2, (SP)
	0x002d 00045 (main.go:6)	CALL	runtime.printint(SB)
	0x0032 00050 (main.go:6)	CALL	runtime.printnl(SB)
	0x0037 00055 (main.go:6)	CALL	runtime.printunlock(SB)
```

从 `MOVQ	$-2, (SP)` 看出，直接编译器直接计算出 -2 了。。。（可以进一步加上 -N 来禁止优化，但没有没有看出额外特别的）

## 02 看规范

之前的一些题解，我总是在 Go 语言规范中找到解释，因此这次也不例外。

在运算符章节，Go 中有如下几个一元运算符：

```go
unary_op = "+" | "-" | "!" | "^" | "*" | "&" | "<-" .
```

其中，+、- 和 * 同时也是算术运算符中的加、减和乘。

接着，在运算符优先级处提到：一元运算符有最高的优先级。

我们分析题目中的表达式：`5/+-*v`。5 后面 /，很显然，这是除法。而 + 前面没有操作数，因此是一个一元运算符；同理 - 和 `*` 也是一元运算符。而一元运算符有最高的优先级，因此这个表达式优先计算 `+-*v` 的值。那这个东西为什么又合法呢？

在规范中有这么一句话：

> 对于整数操作数，一元运算符 `+` , `-` 和 `^` 有如下定义：（省略了 ^ 的解释）
>
> +x    　　　　              是 0 + x
> -x    取其负值               是 0 - x

也就是说，`+-*v` 相当于：`0+(0-(*v))`。（为什么一元运算符左结合，因为一元，必须得有运算数，得跟着运算数走）

这样一来，结果变成了求 5/-2 的值，结果自然是 -2（别跟我说应该是 2.5）。

（规范参考 Bekcpear 翻译版：<https://hao.studygolang.com/golang_spec.html>）

## 03 其他语言的行为

看到这，我不禁想看看其他语言怎么实现的。（没有指针的语言，就只能包含 /+- 了）

**C 语言**

```c
#include <stdio.h>

int main()
{
		int i = 2;
  	int *p = &i;
  	printf("%d\n", 5/+-*p);
  	return 0;
}
```

结果也是 -2。

**Java**

```java
public class HelloWorld {
    public static void main(String []args) {
       System.out.println(5/+-2);
    }
}
```

结果也是 -2。

**PHP**

```php
<?php
echo 5/+-2;
```

结果是 -2.5。（弱类型语言嘛）

**Python**

```python
5/+-2
```

结果是 -3。（Python 对 / 的处理和别的语言还是不太一样）

**JS**

```javascript
5/+-2
```

结果和 PHP 一样，-2.5。

最后看看 **Rust**

```rust
fn main() {
    println!(5/+-2);
}
```

编译器告诉我：

```bash
error: expected expression, found `+`
```

Rust 果然不一样！我们不一样、不一样。。。

## 04 总结

奇淫技巧，如果能顺便学一点知识，那是极好的。当然，最关键的是希望有探索精神，找到其中的原因，举一反三，也许这点比较重要。
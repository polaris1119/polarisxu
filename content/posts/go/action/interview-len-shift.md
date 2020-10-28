---
title: "这么一道“简单”的题，为什么结果出乎我的意料"
date: 2020-09-27T14:52:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Golang
  - 面试题
---

今天在[《Go语言爱好者周刊：第62期》](https://mp.weixin.qq.com/s/xvlAcDBqb77HUzTo7gjuCw)中贴了一道 Go101 的题，原题如下：

```go
package main

const s = "Go101.org"
// len(s) == 9
// 1 << 9 == 512
// 512 / 128 == 4

var a byte = 1 << len(s) / 128
var b byte = 1 << len(s[:]) / 128

func main() {
  println(a, b)
}
```

答案是 4 0。

不少人对这个结果应该很吃惊，因为从答题结果看，不到一半的人答对了。而且，如果只给 `var b byte = 1 << len(s[:]) / 128`，没有 a 对比，我想答对的人会更少。因为有对比，很多人虽然直觉是 4 4，但想到一定有陷阱，所以会重新思考。

好几个群都问，为什么结果会是 4 0，希望我解释下。因此有了此文。

这个小题涉及到几个知识点。

## len 函数的结果

要注意，len 是一个内置函数。在官方标准库文档[关于 len 函数](https://docs.studygolang.com/pkg/builtin/#len)有这么一句：

> For some arguments, such as a string literal or a simple array expression, the result can be a constant. See the Go language specification's "Length and capacity" section for details.

明确支持，当参数是字符串字面量和简单 array 表达式，len 函数返回值是常量，这很重要。

上题中，如果 `const s = "Go101.org”` 改为 `var s = "Go101.org"` 结果又会是什么呢？

```go
package main

var s = "Go101.org"

var a byte = 1 << len(s) / 128
var b byte = 1 << len(s[:]) / 128

func main() {
	println(a, b)
}
```

结果是 0 0。

但改为这样：

```go
package main

var s = [9]byte{'G', 'o', '1', '0', '1', '.', 'o', 'r', 'g'}

var a byte = 1 << len(s) / 128
var b byte = 1 << len(s[:]) / 128

func main() {
	println(a, b)
}
```

结果又是 4 0。

接着看文档那句话的后半句，查看 Go 语言规范中[关于长度和容量的说明](https://hao.studygolang.com/golang_spec.html#id221)。

> 内置函数 len 和 cap 获取各种类型的实参并返回一个 int 类型结果。实现会保证结果总是一个 int 值。
>
> 如果 s 是一个字符串常量，那么 len(s) 是一个常量 。如果 s 类型是一个数组或到数组的指针且表达式 s 不包含 信道接收 或（非常量的） 函数调用的话， 那么表达式 len(s) 和 cap(s) 是常量；这种情况下， s 是不求值的。否则的话， len 和 cap 的调用结果不是常量且 s 会被求值。

可见题目中：

```go
var a byte = 1 << len(s) / 128
var b byte = 1 << len(s[:]) / 128
```

第一句的 len(s) 是常量（因为 s 是字符串常量）；而第二句的 len(s[:]) 不是常量。这是这两条语句的唯一区别：两个 len 的返回结果数值并无差异，都是 9，但一个是常量一个不是。

## 关于位移操作

根据上面的分析，现在问题的关键在于位移运算这里。Go 语言规范中有[这么一句](https://docs.studygolang.com/ref/spec#Operators)：

> The right operand in a shift expression must have integer type or be an untyped constant representable by a value of type uint. If the left operand of a non-constant shift expression is an untyped constant, it is first implicitly converted to the type it would assume if the shift expression were replaced by its left operand alone.

大意是：在位移表达式的右侧的操作数必须为整数类型，或者可以被 uint 类型的值所表示的无类型的常量。如果一个非常量位移表达式的左侧的操作数是一个无类型常量，那么它会先被隐式地转换为假如位移表达式被其左侧操作数单独替换后的类型。

这里的关键在于常量位移表达式。根据上文的分析，`1 << len(s)` 是常量位移表达式，而 `1 << len(s[:])` 不是。

规范上关于常量表达式中，还有[这么一句](https://docs.studygolang.com/ref/spec#Constant_expressions)：

> If the left operand of a constant shift expression is an untyped constant, the result is an integer constant; otherwise it is a constant of the same type as the left operand, which must be of integer type.

大意是：如果常量 位移表达式 的左侧操作数是一个无类型常量，那么其结果是一个整数常量；否则就是和左侧操作数同一类型的常量（必须是 整数类型 ）

因此对于 `var a byte = 1 << len(s) / 128`，因为 `1 << len(s)` 是一个常量位移表达式，因此它的结果也是一个整数常量，所以是 512，最后除以 128，最终结果就是 4。

而对于 `var b byte = 1 << len(s[:]) / 128`，因为 `1 << len(s[:])` 不是一个常量位移表达式，而做操作数是 1，一个无类型常量，根据规范定义它是 byte 类型（根据：如果一个非常量位移表达式的左侧的操作数是一个无类型常量，那么它会先被隐式地转换为假如位移表达式被其左侧操作数单独替换后的类型）。

为什么是 byte 类型，大家可能还是有点晕。这要回到关于常量的说明上。

### 常量

常量是在编译的时候进行计算的。在 Go 语言中，常量分两种：无类型和有类型。Go 规范上说，字面值常量， true , false , iota 以及一些仅包含无类型的恒定操作数的 常量表达式 是无类型的。

那有类型常量是怎么来的呢？一般有两种：显示声明或隐式得到。比如：

```go
const a int32 = 23
const b float32 = 0.1
```

无类型常量都有一个默认类型（无类型常量的默认类型分别是 bool , rune , int , float64 , complex128 或 string）。当在上下文中需要请求该常量为一个带类型的值时，这个 默认类型 便指向该常量隐式转换后的类型。

所以 `var b byte = 1 << len(s[:]) / 128` 中，根据规范定义，1 会隐式转换为 byte 类型，因此 `1 << len(s[:])` 的结果也是 byte 类型，而 byte 类型最大只能表示 255，很显然 512 溢出了，结果为 0，因此最后 b 的结果也是 0。

## 小结

一道很具迷惑性的题目引出这么多小知识点。可能有人要喷：讨论这些有什么用？这也太细节了。我想说的是，Go 语言规范，细节点很多，能多掌握一些没坏处，说不定将来实际工作就遇到了类似的问题呢？！以上的知识点，很细节，但我认为也是挺有价值的。

当然了，你怎么说都行，你都是对的，你开心就好！

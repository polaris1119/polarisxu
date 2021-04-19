---
title: "一道 Go 闭包题，面试官说原来自己答错了：面别人也涨知识"
date: 2021-04-13T18:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 闭包
---

大家好，我是站长 polarisxu。

通常，JS 面试，闭包应该是必考的题目。随着越来越多的语言对函数式范式的支持，闭包问题经常出现。在 Go 语言中也是如此。

本文从一道题引出 Go 中的闭包。这是 Go 语言爱好者周刊第 90 期的一道题目。以下代码输出什么？

```go
package main

import "fmt"

func app() func(string) string {
	t := "Hi"
	c := func(b string) string {
		t = t + " " + b
		return t
	}
	return c
}

func main() {
	a := app()
	b := app()
	a("go")
	fmt.Println(b("All"))
}
```

这道题目答对的人蛮多的：60%。不管你是答对还是答错，如果最后再加一行代码：`fmt.Println(a("All"))`，它输出什么？想看看你是不是蒙对了。（提示：你可以输出 t 的地址，看看是什么情况。）

## 01 什么是闭包

维基百科对[闭包的定义](https://zh.wikipedia.org/wiki/%E9%97%AD%E5%8C%85_(%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%A7%91%E5%AD%A6))：

> 在计算机科学中，闭包（英语：Closure），又称词法闭包（Lexical Closure）或函数闭包（function closures），是在支持头等函数的编程语言中实现词法绑定的一种技术。闭包在实现上是一个结构体，它存储了一个函数（通常是其入口地址）和一个关联的环境（相当于一个符号查找表）。环境里是若干对符号和值的对应关系，它既要包括约束变量（该函数内部绑定的符号），也要包括自由变量（在函数外部定义但在函数内被引用），有些函数也可能没有自由变量。闭包跟函数最大的不同在于，当捕捉闭包的时候，它的自由变量会在捕捉时被确定，这样即便脱离了捕捉时的上下文，它也能照常运行。捕捉时对于值的处理可以是值拷贝，也可以是名称引用，这通常由语言设计者决定，也可能由用户自行指定（如 C++）。

关于（函数）闭包，有几个关键点：

- 函数是一等公民；
- 闭包所处环境，可以引用环境里的值；

问到什么是闭包时，网上一般这么回答的：

> 在支持函数是一等公民的语言中，一个函数的返回值是另一个函数，被返回的函数可以访问父函数内的变量，当这个被返回的函数在外部执行时，就产生了闭包。

所以，上面题目中，函数 app 的返回值是另一个函数，因此产生了闭包。

## 02 Go 中的闭包

Go 中的函数是一等公民，之前写过一篇文章：[函数是一等公民，这到底在说什么？](https://mp.weixin.qq.com/s/H3iuhkvQWonZbi7AzmokSA)

日常开发中，闭包是很常见的。举几个例子。

### 标准库

在 net/http 包中的函数 ProxyURL，实现如下：

```go
// ProxyURL returns a proxy function (for use in a Transport)
// that always returns the same URL.
func ProxyURL(fixedURL *url.URL) func(*Request) (*url.URL, error) {
	return func(*Request) (*url.URL, error) {
		return fixedURL, nil
	}
}
```

它的返回值是另一个函数，签名是：

```go
func(*Request) (*url.URL, error)
```

在返回的函数中，引用了父函数（ProxyURL）的参数 fixedURL，因此这是闭包。

### Web 中间件

在 Web 开发中，中间件一般都会使用闭包。比如 Echo 框架中的一个中间件：

```go
// BasicAuthWithConfig returns an BasicAuth middleware with config.
// See `BasicAuth()`.
func BasicAuthWithConfig(config BasicAuthConfig) echo.MiddlewareFunc {
	// Defaults
	if config.Validator == nil {
		panic("echo: basic-auth middleware requires a validator function")
	}
  ...
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			/// 省略很多代码
      ...
		}
	}
}
```

首先，echo.MiddlewareFunc 是一个函数：

```go
type MiddlewareFunc func(HandlerFunc) HandlerFunc
```

而 echo.HandlerFunc 也是一个函数：

```go
type HandlerFunc func(Context) error
```

所以，上面的函数嵌套了几层，是典型的闭包。

### 这是闭包吗？

在 Go 中不支持函数嵌套定义，函数内嵌套函数，必须通过匿名函数的形式。匿名函数在 Go 中是很常见的，比如开启一个 goroutine，通常通过匿名函数。

现在有一个问题，以下代码是闭包吗？

```go
package main

import (  
    "fmt"
)

func main() {  
    a := 5
    func() {
        fmt.Println("a =", a)
    }()
}
```

如果按照上面网上一般的回答，这不是闭包，因为并没有返回函数。但按照维基百科的定义，这个属于闭包。有没有其他证据呢？

在 Go 语言规范中，关于函数字面值（匿名函数）有这么一句话：

> Function literals are *closures*: they may refer to variables defined in a surrounding function. Those variables are then shared between the surrounding function and the function literal, and they survive as long as they are accessible.

也就是说，函数字面值（匿名函数）是闭包，它们可以引用外层函数定义的变量。

此外，在官方 FAQ 中有这样的说明：

[What happens with closures running as goroutines?](https://docs.studygolang.com/doc/faq#closures_and_goroutines)

例子是：

```go
func main() {
    done := make(chan bool)

    values := []string{"a", "b", "c"}
    for _, v := range values {
        go func() {
            fmt.Println(v)
            done <- true
        }()
    }

    // wait for all goroutines to complete before exiting
    for _ = range values {
        <-done
    }
}
```

这是 Go 中很常见的代码（很容易写错的），FAQ 称开启 goroutine 的那个匿名函数是一个闭包。

## 03 汇编看看实现

回到开始的题目，我们通过汇编看看，Go 闭包的实现，是不是按照维基百科说的，「闭包在实现上是一个结构体，它存储了一个函数（通常是其入口地址）和一个关联的环境（相当于一个符号查找表）」。

```bash
$ go tool compile -S main.go
```

看关键代码：

```go
0x0000 00000 (main.go:5)	TEXT	"".app(SB), ABIInternal, $24-8
0x0000 00000 (main.go:5)	MOVQ	(TLS), CX
0x0009 00009 (main.go:5)	CMPQ	SP, 16(CX)
0x000d 00013 (main.go:5)	PCDATA	$0, $-2
0x000d 00013 (main.go:5)	JLS	96
0x000f 00015 (main.go:5)	PCDATA	$0, $-1
0x000f 00015 (main.go:5)	SUBQ	$24, SP
0x0013 00019 (main.go:5)	MOVQ	BP, 16(SP)
0x0018 00024 (main.go:5)	LEAQ	16(SP), BP
0x001d 00029 (main.go:5)	FUNCDATA	$0, gclocals·2a5305abe05176240e61b8620e19a815(SB)
0x001d 00029 (main.go:5)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
0x001d 00029 (main.go:7)	LEAQ	type.noalg.struct { F uintptr; "".t string }(SB), AX
0x0024 00036 (main.go:7)	MOVQ	AX, (SP)
0x0028 00040 (main.go:7)	PCDATA	$1, $0
0x0028 00040 (main.go:7)	CALL	runtime.newobject(SB)
0x002d 00045 (main.go:7)	MOVQ	8(SP), AX
0x0032 00050 (main.go:7)	LEAQ	"".app.func1(SB), CX
0x0039 00057 (main.go:7)	MOVQ	CX, (AX)
0x003c 00060 (main.go:7)	MOVQ	$2, 16(AX)
0x0044 00068 (main.go:7)	LEAQ	go.string."Hi"(SB), CX
0x004b 00075 (main.go:7)	MOVQ	CX, 8(AX)
0x004f 00079 (main.go:10)	MOVQ	AX, "".~r0+32(SP)
0x0054 00084 (main.go:10)	MOVQ	16(SP), BP
0x0059 00089 (main.go:10)	ADDQ	$24, SP
0x005d 00093 (main.go:10)	RET
0x005e 00094 (main.go:10)	NOP
```

其中 `LEAQ	type.noalg.struct { F uintptr; "".t string }(SB), AX` 这行表明 Go 对闭包的实现和维基百科说的类似。

现在看看下面这种是不是这么实现的：

```go
package main

import (  
    "fmt"
)

func main() {  
    a := 5
    func() {
        fmt.Println("a =", a)
    }()
}
```

看看汇编

```bash
$ go tool compile -S test.go
"".main.func1 STEXT size=215 args=0x8 locals=0x50 funcid=0x0
  0x0000 00000 (test.go:9)	TEXT	"".main.func1(SB), ABIInternal, $80-8
  0x0000 00000 (test.go:9)	MOVQ	(TLS), CX
  0x0009 00009 (test.go:9)	CMPQ	SP, 16(CX)
  0x000d 00013 (test.go:9)	PCDATA	$0, $-2
  0x000d 00013 (test.go:9)	JLS	205
  0x0013 00019 (test.go:9)	PCDATA	$0, $-1
  0x0013 00019 (test.go:9)	SUBQ	$80, SP
  0x0017 00023 (test.go:9)	MOVQ	BP, 72(SP)
  0x001c 00028 (test.go:9)	LEAQ	72(SP), BP
  0x0021 00033 (test.go:9)	FUNCDATA	$0, gclocals·69c1753bd5f81501d95132d08af04464(SB)
  0x0021 00033 (test.go:9)	FUNCDATA	$1, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
  0x0021 00033 (test.go:10)	MOVQ	"".a+88(SP), AX
  0x0026 00038 (test.go:10)	MOVQ	AX, (SP)
  0x002a 00042 (test.go:10)	PCDATA	$1, $0
  0x002a 00042 (test.go:10)	CALL	runtime.convT64(SB)
  0x002f 00047 (test.go:10)	MOVQ	8(SP), AX
  0x0034 00052 (test.go:10)	MOVQ	AX, ""..autotmp_21+64(SP)
  0x0039 00057 (test.go:10)	LEAQ	type.[2]interface {}(SB), CX
  0x0040 00064 (test.go:10)	MOVQ	CX, (SP)
  0x0044 00068 (test.go:10)	PCDATA	$1, $1
  0x0044 00068 (test.go:10)	CALL	runtime.newobject(SB)
  0x0049 00073 (test.go:10)	MOVQ	8(SP), AX
  0x004e 00078 (test.go:10)	LEAQ	type.string(SB), CX
  0x0055 00085 (test.go:10)	MOVQ	CX, (AX)
  0x0058 00088 (test.go:10)	LEAQ	""..stmp_1(SB), CX
  0x005f 00095 (test.go:10)	MOVQ	CX, 8(AX)
  0x0063 00099 (test.go:10)	LEAQ	type.int(SB), CX
  0x006a 00106 (test.go:10)	MOVQ	CX, 16(AX)
  0x006e 00110 (test.go:10)	PCDATA	$0, $-2
  0x006e 00110 (test.go:10)	CMPL	runtime.writeBarrier(SB), $0
  0x0075 00117 (test.go:10)	JNE	189
  0x0077 00119 (test.go:10)	MOVQ	""..autotmp_21+64(SP), CX
  0x007c 00124 (test.go:10)	MOVQ	CX, 24(AX)
  0x0080 00128 (test.go:10)	PCDATA	$0, $-1
  0x0080 00128 (test.go:10)	PCDATA	$1, $-1
```

发现并没有这样的结构体，可见 Go 对这种情况做了特殊处理，因为它不是重复使用的匿名函数。

## 04 总结

通过以上的讲解，对闭包应该有了更清晰的认识。如果面试中再被问到闭包，你可以这么回答：

> 对闭包来说，函数在该语言中得是一等公民。一般来说，一个函数返回另外一个函数，这个被返回的函数可以引用外层函数的局部变量，这形成了一个闭包。通常，闭包通过一个结构体来实现，它存储一个函数和一个关联的上下文环境。但 Go 语言中，匿名函数就是一个闭包，它可以直接引用外部函数的局部变量，因为 Go 规范和 FAQ 都这么说了。

面试官会不会被你惊到：原来如此，后一种说法我之前没有注意过。

> 4 月 14 日更新：
>
> 来自[微信公众号](https://mp.weixin.qq.com/s/gfyW0pBIHsf2oYluQNbP8A)的读者 **gopher **留言：
>
> noalg 代表不会生成 equal 和 hash 函数，因为闭包的 struct 是匿名的，不存在比较或者作为 key 的场景。
> F uintptr 更准确的说应该是 .F uintptr，编译器生成的符号大部分都是.开头的。
> "".t string 表示捕获了一个 string 类型的变量 t，而且是 by value 而不是 by reference，因为"We use value capturing for values &lt;= 128 bytes that are never reassigned after capturing (effectively constant)."。
> 通过 (func)(*struct) 的类型转换，即可通过 .F 找到对应的函数。
> 题外话：closure 通过 struct 实现只是为了 GC 更友好，另外匿名 struct 是为了不同的 package 共用 struct 的可能性。


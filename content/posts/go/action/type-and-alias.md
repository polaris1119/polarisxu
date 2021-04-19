---
title: "答应我，这次一定彻底搞懂 Go 中的类型别名"
date: 2021-04-07T17:20:00+08:00
toc: true
isCJKLanguage: true
tags:
  - Go
  - 别名
---

大家好，我是站长 polarisxu。

有下面 3 行代码：

```go
// 32 位机器
1）var x int32 = 32.0
2）var y int = x
3）var z rune = x
```

它们是否能编译通过？为什么？

如果面试时问这道题，你需要想想面试官想考察你什么。在往下看之前，建议你记下自己的答案。

## 01 数字字面量

在 Go 语言中，字面量是无类型（untyped）的。无类型是什么意思？无类型意味着可以赋值给类似类型的变量或常量。用上面例子，32.0 是无类型的浮点数字面量，因此它可以赋值给任意数字相关类型变量（或常量）。以下都是合法的：

```go
var a int64 = 32.0
var b int = 32.0
var c float32 = 32.0
var d complex64 = 32.0
var e byte = 32.0
var f rune = 32.0
```

所以上题中 1）是正确的。

## 02 不同类型

在目前 Go 1.16 版本中（实际上只有很早期的版本不是），int 类型在 32 位机器占 4 字节，64 位机器占 8 字节。所以，在 32 位机器上，int32 和 int 的内存占用和内存布局是完全一样的。但 Go 语言不会做隐式类型转换，int 和 int32 是不同的类型，因此上题中 2）编译不通过。

## 03 类型别名

熟悉 C 语言的小伙伴，看到 Go 中以下定义：

```go
type myint int
```

会以为 myint 和 int 是一样的，认为 myint 是 int 的别名。而实际上，myint 是和 int 完全不一样的类型，只不过 myint 的底层类型是 int，它们直接可以强制类型转换，却不会隐式转换。关于这点无需多讲，重点要讲的是类型别名。

从 Go1.9 开始引入了类型别名，定义如下：

```go
AliasDecl = identifier, "=", Type .
```

具体例子：

```go
type intalias = int
```

myint 是新类型，和 int 不一样；而 intalias 却和 int 一样，它只是 int 的别名：所有使用 intalias 的地方都可以使用 int。

那为什么 Go 中会引入类型别名呢？Russ Cox 的论文 [Codebase Refactoring (with help from Go)](https://talks.golang.org/2016/refactor.article) 介绍了它的背景。总结一下类型别名的用途，主要有两点：

- 在大规模重构项目代码的时候，尤其是将一个类型从一个包移动到另一个包中的时候，有些代码会使用新包中的类型，有些代码使用旧包中的类型， 最典型的是 `context` 包。最开始，context 包名是 `golang.org/x/net/context`，1.7 开始，引入标准库，这样一来，存在两份。Go 1.9 开始采用别名重构了它；
- 允许一个庞大的包分解成内部的几个小包，但是小包中的类型需要集中暴漏在上层的大包中；

在 Go 中，你可以为任意类型定义别名，比如数组、结构体、指针、函数、接口、Slice、Map、Channel 等，包括为自定义类型定义别名。

```go
type F = func()
type I = interface{}
...
```

此外，还可以为其他包中的类型定义别名，比如为标准库类型定义别名：

```go
type MyReader = bufio.Reader
```

关于类型别名的一些注意事项：

- 别名和原类型是一样的，因此 switch-type 结构中，不能存在两个 case，一个是原类型，一个是别名；
- 类型别名不能循环定义，比如以下是不允许的：

```go
type T = struct {
	next *T1
}

type T1 = T
```

- 因为别名和原类型是一样的，因此共享同样的方法集，不论这个方法是定义在原类型还是别名上；
- 别名的导出性可以和原类型不一样；
- 不能为别的包的类型通过定义别名来增加方法。以下行为是不允许的：

```go
type MyReader = bufio.Reader
func (MyReader) AliasMethod() {
	fmt.Println("This is alias method")
}
```

编译报错：`cannot define new methods on non-local type bufio.Reader`。

回到开头题目的 3），rune 是什么类型？定义如下：

```go
type rune = int32
```

很显然，rune 是 int32 的别名，因此题目中 3）也能编译通过。

除了 rune，Go 内置类型中，还有 byte 是 uint8 的别名：

```go
type byte = uint8
```

需要说明的是，在 Go1.9 之前，rune 和 byte 的别名性质就存在，是编译器负责处理的。只是 Go1.9 之后，别名可以用于其他类型了。

## 04 总结

一道看似简单的题目，如果你能够分析透彻，把语言的变化都说出来，我相信面试官会给你加分。

今天的题目，你做对了吗？
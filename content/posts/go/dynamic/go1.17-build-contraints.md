---
title: "Go1.17 新特性：新版构建约束"
date: 2021-07-15T22:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 新特性
---

大家好，我是 polarisxu。

Go 1.17 下个月就要正式发布了。很多人要问泛型了吧，泛型已经很明确了，Go1.18 会有。今天给大家介绍 Go1.17 的一个新特性：构建约束 — Build Constraints。

确切来说，这个特性相关的工作在 1.16 时就加入，但处于过度阶段，1.17 在各方面都更完善，更完整的支持，是时候了解它了。

## 01 什么是构建约束

构建约束（build constraint），也叫做构建标记（build tag），是在 Go 源文件最开始的注释行，比如：

```go
// +build linux
```

看到这个，相信很多人都不陌生，因为这是 Go 一开始就有的特性，在 Go 源码中有很多这样的注释行。上面注释行的意思，这个文件只在 Linux 系统会包含在包中，其他系统会忽略这个文件。

几个注意点：

- 约束可以出现在任何源文件中，比如 `.go`、`.s` 等；
- 必须在文件顶部附近，它的前面只能有空行或其他注释行；可见包子句也在约束之后；
- 约束可以有多行；
- 为了区别约束和包文档，在约束之后必须有空行；

针对某个构建约束，可使用的词如下：

- 特定操作系统，对应 runtime.GOOS 的可用值，比如 linux、windows 等；
- 特定的架构，对应 runtime.GOARCH 的可用值，比如 386、amd64 等；
- 使用的编译器，比如 gc、gccgo；
- 支持 cgo 命令时，可以使用 cgo；
- Go 的主要发布版本，比如 go1.17、go1.16 等；（测试版本和 fixbug 版本不支持）
- 自定义的 tag，编译时通过 `-tags` 传递的值；
- 可以加入任意值，一般用 ignore 来忽略构建；

此外，文件名可以通过 GOOS 和 GOARCH 来做构建约束。

## 02 旧版构建约束

从上面看到，构建约束的语法是 `// +build` 这种形式，如果多个条件组合，通过空格、逗号或多行构建约束表示。比如：

```go
// +build linux,386
```

你知道什么意思吗？表示在 linux AND 386。逗号表示 AND，空格表示 OR。那看一个复杂的：

```go
// +build linux,386 darwin,!cgo
```

是不是有点懵？我也有点懵！它表示的意思是：(linux AND 386) OR (darwin AND (NOT cgo)) 。

有些时候，多个约束分成多行书写，会更易读些：

```go
// +build linux darwin
// +build amd64
```

这相当于：(linux OR darwin) AND amd64 。

是不是很复杂，很难记忆？

正因为太复杂，很容易出错。而且，Go 中有不少注释是有特殊意义的，也为了一致性考虑，因此有了新版的构建约束。

## 03 新版构建约束

在 Go 源码中，经常会见到类似下面开头的注释：

```go
//go:link
```

新版的构建约束，也使用了 `//go:` 开头：

```go
//go:build
```

注意 `//` 和 go 之间不能有空格。

同时新版语法使用布尔表达式，而不是逗号、空格等。布尔表达式，会更清晰易懂，出错可能性大大降低。

比如旧语法：

```go
// +build linux,386
```

对应的新语法：

```go
//go:build linux && 386
```

构建标记的基础语法与其当前形式没有变化，但是构建标记的组合现在是用 Go 的 || 、 && 和 ! 运算符和括号。（请注意，构建标记并不总是有效的 Go 表达式，即使它们共享操作符，因为标记并不总是有效的标识符。例如：”go1.1"。)

新语法可以使用 Go spec 的 EBNF 标记来表示：

```go
BuildLine      = "//go:build" Expr
Expr           = OrExpr
OrExpr         = AndExpr   { "||" AndExpr }
AndExpr        = UnaryExpr { "&&" UnaryExpr }
UnaryExpr      = "!" UnaryExpr | "(" Expr ")" | tag
tag            = tag_letter { tag_letter }
tag_letter     = unicode_letter | unicode_digit | "_" | "."
```

采用新语法后，一个文件只能有一行构建语句，而不是像旧版那样有多行。这样可以避免多行的关系到底是什么的问题。

Go1.17 中，gofmt 工具会自动根据旧版语法生成对应的新版语法，为了兼容性，两者都会保留。比如原来是这样的：

```go
// +build !windows,!plan9
```

执行 Go1.17 的 gofmt 后，变成了这样：

```go
//go:build !windows && !plan9
// +build !windows,!plan9
```

如果文件中已经有了这两种约束形式，gofmt 会根据 `//go:buid` 自动覆盖 `// +build` 的形式，确保两者表示的意思一致。如果只有新版语法，不会自动生成旧版的，这时，你需要注意，它不兼容旧版本了。

另外，Vet 工具现在能够检测出两种语法的不一致。所以，建议大家在编辑器中保存文件时自动执行 gofmt。

早在 Go1.16 时就新增了一个包：[go/build/constraint](https://docs.studygolang.com/pkg/go/build/constraint/)，专门处理新版构建约束。

关于新版约束的设计文档请移步：<https://go.googlesource.com/proposal/+/master/design/draft-gobuild.md>。

## 04 总结

新版本的构建约束可读性更强，更容易书写，不容易出错。有兴趣的可以自己针对构建约束，同时书写两种形式，体会下新版的好处。

最后提醒一点，新版约束中，一定要注意 `//` 和 go 之间不能有空格！
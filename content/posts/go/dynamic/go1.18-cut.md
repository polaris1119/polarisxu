---
title: "Go1.18 快讯：新增的 Cut 函数太方便了"
date: 2021-11-08T09:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 标准库
---

大家好，我是 polarisxu。

在编程中，字符串使用是最频繁的。Go 语言对字符串相关的操作也提供了大量的 API，一方面，字符串可以向普通 slice 一样进行相关操作；另一方面，标准库专门提供了一个包 strings 进行字符串的操作。

## 01 strings.Index 系列函数

假如有一个这样的需求：从 `192.168.1.1:8080` 中获取 ip 和 port。

我们一般会这么实现：

```go
addr := "192.168.1.1:8080"
pos := strings.Index(addr, ":")
if pos == -1 {
  panic("非法地址")
}
ip, port := addr[:pos], addr[pos+1:]
```

> 实际项目中，pos == -1 时应该返回 error
>
> 此处忽略通过 net.TCPAddr 方式得到，主要在于讲解字符串处理。

strings 包中，Index 相关函数有好几个：

```go
func Index(s, substr string) int
func IndexAny(s, chars string) int
func IndexByte(s string, c byte) int
func IndexFunc(s string, f func(rune) bool) int
func IndexRune(s string, r rune) int
func LastIndex(s, substr string) int
func LastIndexAny(s, chars string) int
func LastIndexByte(s string, c byte) int
func LastIndexFunc(s string, f func(rune) bool) int
```

Go 官方统计了 Go 源码中使用相关函数的代码：

- 311 Index calls outside examples and testdata.
- 20 should have been Contains
- 2 should have been 1 call to IndexAny
- 2 should have been 1 call to ContainsAny
- 1 should have been TrimPrefix
- 1 should have been HasSuffix

相关需求是这么多，而 Index 显然不是处理类似需求最好的方式。于是 Russ Cox 提议，在 strings 包中新增一个函数 Cut，专门处理类似的常见。

## 02 新增的 Cut 函数

Cut 函数的签名如下：

```go
func Cut(s, sep string) (before, after string, found bool)
```

将字符串 s 在第一个 sep 处切割为两部分，分别存在 before 和 after 中。如果 s 中没有 sep，返回 `s,"",false`。

根据 Russ Cox 的统计，Go 源码中 221 处使用 Cut 会更好。

针对上文提到的需求，改用 Cut 函数：

```go
addr := "192.168.1.1:8080"
ip, port, ok := strings.Cut(addr, ":")
```

是不是很清晰？！

这是又一个改善生活质量的优化。

针对该函数，官方提供了如下示例：

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	show := func(s, sep string) {
		before, after, found := strings.Cut(s, sep)
		fmt.Printf("Cut(%q, %q) = %q, %q, %v\n", s, sep, before, after, found)
	}
	show("Gopher", "Go")
	show("Gopher", "ph")
	show("Gopher", "er")
	show("Gopher", "Badger")
}

// Output:
/*
Cut("Gopher", "Go") = "", "pher", true
Cut("Gopher", "ph") = "Go", "er", true
Cut("Gopher", "er") = "Goph", "", true
Cut("Gopher", "Badger") = "Gopher", "", false
*/
```

## 03 总结

从 PHP 转到 Go 的朋友，肯定觉得 Go 标准库应该提供更多便利函数，让生活质量更好。在 Go 社区这么多年，也确实听到了不少这方面的声音。

但 Go 官方不会轻易增加一个功能。就 Cut 函数来说，官方做了详细调研、说明，具体可以参考这个 issue：[bytes, strings: add Cut](https://github.com/golang/go/issues/46336)，可见 bytes 同样的增加了 Cut 函数。

有人提到，为什么不增加 LastCut？Russ Cox 的解释是，LastIndex 的调用次数明显少于 Index，因此暂不提供 LastCut。

做一个决定，不是瞎拍脑袋的~
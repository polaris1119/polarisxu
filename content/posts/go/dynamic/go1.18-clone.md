---
title: "Go1.18 快讯：新增字符串 Clone API"
date: 2021-11-02T23:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Clone
  - 标准库
---

大家好，我是 polarisxu。

Go 1.18 虽然还有 4 个月发布，但大部分的功能基本确定。我们可以提前知晓、熟悉。

今天介绍的是标准库中新增的一个 API：`strings.Clone()`。

从名称可以知道，这是克隆。很多其他语言一开始就有这样的功能。比如 PHP 有 clone 关键字、`__clone` 魔术方法；Java 的根类 Object 有 clone 方法等。

## 01 函数签名

该函数的定义如下（见：<https://pkg.go.dev/strings@master#Clone>）

```go
// Clone returns a fresh copy of s.
// It guarantees to make a copy of s into a new allocation,
// which can be important when retaining only a small substring
// of a much larger string. Using Clone can help such programs
// use less memory. Of course, since using Clone makes a copy,
// overuse of Clone can make programs use more memory.
// Clone should typically be used only rarely, and only when
// profiling indicates that it is needed.
// For strings of length zero the string "" will be returned
// and no allocation is made.
func Clone(s string) string
```

Clone 返回 s 的新副本。它保证将 s 复制到一个新分配的副本中，当只保留一个很大的字符串中的一个小子字符串时，这一点很重要。使用克隆可以帮助这些程序使用更少的内存。当然，由于使用克隆制作拷贝，过度使用克隆会使程序使用更多内存。通常，只有在分析表明需要克隆时，才谨慎使用克隆。对于长度为零的字符串，将返回字符串 `""`，不进行内存分配。

## 02 举例说明

大家可能还是迷惑，不知道有啥用。举一个代码例子说明：

```go
package main

import (
	"fmt"
	"reflect"
	"unsafe"
)

func main() {
	s := "abcdefghijklmn"
	s1 := s[:4]

	sHeader := (*reflect.StringHeader)(unsafe.Pointer(&s))
	s1Header := (*reflect.StringHeader)(unsafe.Pointer(&s1))
	fmt.Println(sHeader.Len == s1Header.Len)
	fmt.Println(sHeader.Data == s1Header.Data)
  
  // Output:
  // false
  // true
}
```

Len 不相等不需要解释，Data 相等就值得注意。

> 上面代码，有些人可能不知道什么意思。这里涉及到 Go 中 string 类型的底层结构。在 Go 中，string 类型的底层表示如下：
>
> ```go
> type string struct {
> 	ptr unsafe.Pointer
> 	len int
> }
> ```
> 
> 而 reflect.StringHeader 结构是对字符串底层结构的反射表示。

在上面示例场景中，如果 s 很大，而之后我们只需要使用它的某个短子串，这会导致内存的浪费，因为子串和原字符串的 Data 部分指向相同的内存，因此整个字符串并不会被 GC 回收。

`strings.Clone` 函数就是为了解决这个问题的：（要正常运行下面代码，需要按照 Go tip 版本）

```go
s2 := strings.Clone(s[:4])

s2Header := (*reflect.StringHeader)(unsafe.Pointer(&s2))
fmt.Println(sHeader.Len == s2Header.Len)
fmt.Println(sHeader.Data == s2Header.Data)
// Output:
// false
// false
```

通过克隆得到 s2，从最后输出结果看，Data 已经不同了，原始的长字符串就可以被垃圾回收了。（你也可以将传递给 Clone 的参数改为 s1，后面部分用 s1 和 s2 比）

## 03 内部实现

知道了克隆的用途，再看看 strings.Clone 的实现。

```go
func Clone(s string) string {
	if len(s) == 0 {
		return ""
	}
	b := make([]byte, len(s))
	copy(b, s)
	return *(*string)(unsafe.Pointer(&b))
}
```

这里有两个关键点：

- 通过 copy 进行拷贝。其实普通的 slice，也会有需要克隆的场景，这时，需要我们手动执行 copy 操作。
- return 后面的语句 `*(*string)(unsafe.Pointer(&b))`，实现 []byte 到 string 的零内存拷贝转换。

## 04 总结

Go 虽然有 GC，大部分时候不需要考虑内存问题，但对内存的使用，我们需要有敬畏之心，特别是大块内存、重复分配内存的场景，我们需要知晓如何优化，写出真正高质量的代码。

strings.Clone 的使用很简单，但希望通过本文，你在写 Go 代码时，对类似场景下，slice 的正确使用有启发（string 可以认为是特殊的 slice）。

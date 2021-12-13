---
title: "Go1.17 新特性之切片变数组"
date: 2021-06-17T07:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 新特性
---

大家好，我是 polarisxu。

按计划，Go 1.17 会在 2021 年 8 月份发布（目前已经发布了 Beta1 版本）。目前，1.17 相关的功能已经开发差不多了，上次介绍了测试顺序随机的问题，今天介绍 1.17 中的另一个新功能：切片显式地转换成数组指针。

> 温馨提示，如果要试验该功能，需要升级到 1.17 Beta1 版本。另外一个主意事项就是如果在有 go.mod 的目录中试验，确保其中的版本改为 1.17，否则会报错：conversion of slices to array pointers only supported as of -lang=go1.17

## 01 数组转切片

介绍新功能之前，我们先看看在 Go 中如何将数组转为切片。（当然，数组指针也是 OK 的）

一般地，通过 slice 表达式（slice expressions）可以从一个数组得到一个切片。

```go
a[low : high : max]
```

其中，max 可以省略。比如：

```go
a := [5]int{1, 2, 3, 4, 5}
s := a[1:4]
```

s 就是一个切片。

## 02 切片转数组指针

先了解下，为什么会有这样的需求。

该需求来自这个 issue：<https://github.com/golang/go/issues/395>。rogpeppe 提到，很多时候，函数接收一个 slice 参数，但如果使用数组指针，则允许编译器在编译时检查常量索引。比如这样的情况：

```go
func foo(a []int) int {
    return a[0] + a[1] + a[2] + a[3];
}
```

能够编译期进行索引检查。比如这样（当然，最后实现不是这样的）：

```go
func foo(a []int) int {
    b := a.[0:4];
    return b[0] + b[1] + b[2] + b[3];
}
```

此外，有时候我们通过数组得到切片，但有时候我们直接创建切片，底层数组是匿名的。如果我们想要获得底层数组怎么办？将切片转为数组指针可以实现这个需求。

看看具体的例子，以下来自 Go 语言规范（针对 Go1.17 这个语言特性新增）：

```go
s := make([]byte, 2, 4)
s0 := (*[0]byte)(s)      // s0 != nil
s2 := (*[2]byte)(s)      // &s2[0] == &s[0]
s4 := (*[4]byte)(s)      // panics: len([4]byte) > len(s)

var t []string
t0 := (*[0]string)(t)    // t0 == nil
t1 := (*[1]string)(t)    // panics: len([1]string) > len(s)
```

几个注意的点：

- 当切片的长度小于数组长度（len）时会 panic。所以上面例子中，s4 和 t1 发生了 panic
- 将一个非空切片转为 0 长度的数组，得到的指针不是 nil（如 s0）；但将一个空切片转为 0 长度的数组，得到的指针是 nil（如 t0）；
- 多次转换，并不会创建多个数组（因为得到的是底层数组），这从 `&s2[0] == &s[0]` 可以看出；

所以，总结一下就是，将切片转换为数组指针，产生指向切片的底层数组的指针。如果切片的长度小于数组的长度，则会发生运行时 panic。

不过针对 panic，目前没法做断言检查。只能通过 if 判断了。

## 03 reflect 注意事项

针对语言这个改动，reflect 包中的 Type 接口有一个方法：ConvertibleTo。之前的说明是这样的：

```go
// ConvertibleTo reports whether a value of the type is convertible to type u.
ConvertibleTo(u Type) bool
```

1.17 是这样的：

```go
// ConvertibleTo reports whether a value of the type is convertible to type u.
// Even if ConvertibleTo returns true, the conversion may still panic.
// For example, a slice of type []T is convertible to *[N]T,
// but the conversion will panic if its length is less than N.
ConvertibleTo(u Type) bool
```

因为切片转为数组指针可能会 panic，所以才加了这么一句文档说明。

因此，如果通过反射转换做类型转换，虽然通过 ConvertibleTo 判断是可转换的，但调用 Convert 方法依然可能 panic。这点需要特别注意下。

## 04 小结

这个语言改变，大部分时候可能用不到。但有些场景可以做到不需要内存拷贝（copy），比如标准库中有一个例子：

```go
// https://docs.studygolang.com/src/crypto/sha256/sha256.go?s=5787:5834#L252
func Sum224(data []byte) (sum224 [Size224]byte) {
	var d digest
	d.is224 = true
	d.Reset()
	d.Write(data)
	sum := d.checkSum()
	copy(sum224[:], sum[:Size224])
	return
}
```

官方计划修改为：

```go
func Sum224(data []byte) [Size224]byte {
	var d digest
	d.is224 = true
	d.Reset()
	d.Write(data)
	sum := d.checkSum()
	ap := (*[Size224]byte)(sum[:Size224])
	return *ap
}
```

注意其中的区别。

但这里 bradfitz 在修改时，发现，为什么一定要转为数组指针，能否直接转为数组，毕竟，在 Go 中使用数组的话，不太常用数组指针。于是 bradfitz 给出了另一个提案：<https://github.com/golang/go/issues/46505>，即 allow conversion from slice to array。目前该提案是否接受，还没有结论。

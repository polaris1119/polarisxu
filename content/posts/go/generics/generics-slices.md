---
title: "Go泛型系列：slices 包讲解"
date: 2021-11-27T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
---

大家好，我是 polarisxu。

前段时间，[Russ Cox 明确了泛型相关的事情](https://mp.weixin.qq.com/s/pCGpgVVH11wDrFknU9A76Q)，原计划在标准库中加入泛型相关的包，改放到 golang.org/x/exp 下。

目前，Go 泛型的主要设计者 [ianlancetaylor](https://github.com/ianlancetaylor) 完成了 slices 和 maps 包的开发，代码提交到了 golang.org/x/exp 中，如果经过使用、讨论等，社区认可后，预计在 1.19 中会合入标准库中。

今天，通过学习 slices 包，掌握 Go 泛型的使用方法。

## 01 为什么增加 slices 包

标准库有 bytes 和 strings 包，分别用来处理 []byte 和 string 类型，提供了众多方便的函数，但对普通的 slice，却没有相关的包可以使用。

比如 bytes 和 strings 都有 Index 函数，用来在 []byte 或 string 查找某个 byte 或字符串的索引。对于普通的 slice，没法写一大堆包来处理，只能用户自己实现，这也是没有泛型的弊端。

> 提供 bytes 和 strings，主要是因为它们使用频率高

现在有了泛型，可以实现一些便利的 slice 操作方法，必须要针对某一个具体类型的 slice 都实现一遍相同的功能。

## 02 constraints 包

继续讲解 slices 包之前，先看看 contraints 包。

该包定义了一组用于类型参数（泛型）的有用约束，这个包已经确定在 Go 1.18 标准库中包含，截止目前（2021.11.27），该包定义了 6 个约束类型：

```go
// Signed is a constraint that permits any signed integer type.
// If future releases of Go add new predeclared signed integer types,
// this constraint will be modified to include them.
type Signed interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64
}

// Unsigned is a constraint that permits any unsigned integer type.
// If future releases of Go add new predeclared unsigned integer types,
// this constraint will be modified to include them.
type Unsigned interface {
	~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr
}

// Integer is a constraint that permits any integer type.
// If future releases of Go add new predeclared integer types,
// this constraint will be modified to include them.
type Integer interface {
	Signed | Unsigned
}

// Float is a constraint that permits any floating-point type.
// If future releases of Go add new predeclared floating-point types,
// this constraint will be modified to include them.
type Float interface {
	~float32 | ~float64
}

// Complex is a constraint that permits any complex numeric type.
// If future releases of Go add new predeclared complex numeric types,
// this constraint will be modified to include them.
type Complex interface {
	~complex64 | ~complex128
}

// Ordered is a constraint that permits any ordered type: any type
// that supports the operators < <= >= >.
// If future releases of Go add new ordered types,
// this constraint will be modified to include them.
type Ordered interface {
	Integer | Float | ~string
}
```

前面 3 个是整型相关类型约束，Float 是浮点型约束，Complex 是负数类型约束，而 Ordered 表示支持排序的类型约束，表示支持大小比较的类型。

之前文章：[《Go泛型系列：Go1.18 类型约束那些事》](https://mp.weixin.qq.com/s/FFxNpRVgs-v9cIKWCLeN4Q)提到，约束语法变更了，一个是 `|` 符号，一个是 `~`，上面定义中，很多地方都用到了 `~` 符号，它表示出了类型自身，底层类型是它的类型也适用该约束。

## 03 slices 包详解

目前，slices 包有 14 个函数，可以分成几组：

- slice 比较
- 元素查找
- 修改 slice
- 克隆 slice

其中，修改 slice 分为插入元素、删除元素、连续元素去重、slice 扩容和缩容。

### slice 比较

比较两个 slice 中的元素，细分为是否相等和普通比较：

```go
func Equal[E comparable](s1, s2 []E) bool
func EqualFunc[E1, E2 any](s1 []E1, s2 []E2, eq func(E1, E2) bool) bool
func Compare[E constraints.Ordered](s1, s2 []E) int
func CompareFunc[E1, E2 any](s1 []E1, s2 []E2, cmp func(E1, E2) int) int
```

其中 comparable 约束是语言实现的（因为很常用），表示可比较约束（相等与否的比较）。主要，其中的 E、E1、E2 等，只是泛型类型表示，你定义时，可以用你喜欢的，比如 T、T1、T2 等。

看一个具体的实现：

```go
func Equal[E comparable](s1, s2 []E) bool {
	if len(s1) != len(s2) {
		return false
	}
	for i, v1 := range s1 {
		v2 := s2[i]
		if v1 != v2 {
			return false
		}
	}
	return true
}
```

没有什么特别的，只不过把 s1、s2 当成同类型的 slice 进行操作而已。

### 元素查找

在 slice 中查找某个元素，分为普通的所有查找和包含判断：

```go
func Index[E comparable](s []E, v E) int
func IndexFunc[E any](s []E, f func(E) bool) int
func Contains[E comparable](s []E, v E) bool
```

其中，IndexFunc 的类型参数没有使用任何约束（即用的 any），说明查找是通过 f 参数进行的，它的实现如下：

```go
func IndexFunc[E any](s []E, f func(E) bool) int {
	for i, v := range s {
		if f(v) {
			return i
		}
	}
	return -1
}
```

参数 f 是一个函数，它接收一个参数，类型是 E，是一个泛型，和 IndexFunc 的第一个参数类型 `[]E` 的元素类型保持一致即可，因此可以直接将遍历 s 的元素传递给 f。

### 修改 slice

一般不建议做相关操作，因为性能较差。如果有较多这样的需求，可能需要考虑更换数据结构。

```go
// 往 slice 的位置 i 处插入元素（可以多个）
func Insert[S ~[]E, E any](s S, i int, v ...E) S
// 删除 slice 中 i 到 j 的元素，即删除 s[i:j] 元素
func Delete[S ~[]E, E any](s S, i, j int) S
// 将连续相等的元素替换为一个，类似于 Unix 的 uniq 命令。Compact 修改切片的内容，它不会创建新切片
func Compact[S ~[]E, E comparable](s S) 
func CompactFunc[S ~[]E, E any](s S, eq func(E, E) bool) S
// 增加 slice 的容量，至少增加 n 个
func Grow[S ~[]E, E any](s S, n int) S
// 移除没有使用的容量，相当于缩容
func Clip[S ~[]E, E any](s S) S
```

以上类型约束都包含了两个：

- S ~[]E：表明这是一个泛型版 slice，这是对 slice 的约束。注意 [] 前面的 `~`，表明支持自定义 slice 类型，如 type myslice []int
- E any 或 E comparable：对上面 slice 元素类型的约束。

### 克隆 slice

即获得 slice 的副本，会进行元素拷贝，注意，slice 中元素的拷贝是浅拷贝，非值类型不会深拷贝。

```go
func Clone[S ~[]E, E any](s S) S {
	// Preserve nil in case it matters.
	if s == nil {
		return nil
	}
	return append(S([]E{}), s...)
}
```

## 04 总结

因为泛型的存在，同样的功能，对不同类型的 slice 再也不用写多份代码。因为一些功能很常见，因此 Go 官方将其封装，将来会在标准库中提供。

出于谨慎考虑，slices 包不会在 1.18 中包含，如果你需要用到 slices 中的功能，可以采用从 slices 代码中复制的方式，个人觉得依赖 golang.org/x/exp 还是不太好。

slices 源码地址：<https://github.com/golang/exp/blob/master/slices/slices.go>。
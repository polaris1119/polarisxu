---
title: "Go1.18 快讯：constraints 包被移除标准库"
date: 2022-02-05T22:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 新特性
---

大家好，我是 polarisxu。

Go1.18 已经发布 Beta2 版本了，正式版本预计 3 月份发布。Go1.18 最重要的特性莫过于泛型，之前写过几篇相关文章：

- [Go泛型系列：提前掌握Go泛型的基本使用](https://polarisxu.studygolang.com/posts/go/generics/generics-basic/)
- [Go泛型系列：Go1.18 类型约束那些事](https://polarisxu.studygolang.com/posts/go/generics/generics-constraints/)
- [Go 泛型入门教程](https://polarisxu.studygolang.com/posts/go/generics/generics-tutorial/)

其中提到一个标准库新包：constraints，相关提案见：<https://github.com/golang/go/issues/45458>。该包的目的是想预定义一些常用的泛型约束，避免用户自己重复定义。

这是该包最初希望包含的约束：

```go
// Package constraints defines a set of useful constraints to be used with type parameters.
package constraints

// Signed is a constraint that permits any signed integer type.
type Signed interface { ... }

// Unsigned is a constraint that permits any unsigned integer type.
type Unsigned interface { ... }

// Integer is a constraint that permits any integer type.
type Integer interface { ... }

// Float is a constraint that permits any floating-point type.
type Float interface { ... }

// Complex is a constraint that permits any complex numeric type.
type Complex interface { ... }

// Ordered is a constraint that permits any ordered type: any type that supports the operators < <= >= >.
type Ordered interface { ... }

// Slice is a constraint that matches slices of any element type.
type Slice[Elem any] interface { ~[]Elem }

// Map is a constraint that matches maps of any element and value type.
type Map[Key comparable, Val any] interface { ~map[Key]Val }

// Chan is a constraint that matches channels of any element type.
type Chan[Elem any] interface { ~chan Elem }
```

然而简洁一直是 Go 追求的，于是有人提出，该包中的 Slice、Map、Chan 的约束根本不必要，包括简化约束字面值语法，具体讨论见：<https://github.com/golang/go/issues/48424>。于是，Go1.18 Beta 版本中，将这几个约束类型去掉了。

然而，依然有人对 constraints 有其他意见，包括对包名不满意。这个 [issue](https://github.com/golang/go/issues/50348) 就提议将包名改为 of。

当然，最重要的是尚不清楚该包中哪些约束是重要的，应该存在，哪些不应该存在。

当初决定将 slices 和 maps 移到 x/exp 包，而留下 constraints，是因为 Go Team 认为它是使用泛型的基础，但在实践中似乎并没有被证明是这样。特别是，大多数代码使用 any 或 comparable 即可，如果是这样，也许 constraints 包很少被用到。

当然，其中的 constraints.Ordered 还是挺常用的，既然如此，也许应该和 comparable 类似，变成预声明标识符。

经过  rsc 与 robpike、griesemer、ianlancetaylor 等讨论，决定 Go1.18 中，将 constraints 和 slices、maps 一起，移到 x/exp 包中，之后在 Go 1.19 或 Go 1.20 中重新考虑它。

虽然目前 Go1.18 Beta2 还包含 constraints 包，但已经确定正式版本会移除。

如果你需要使用 constraints.Ordered，建议先自己实现，如下：

```go
type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 | ~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr | ~float32 | ~float64 | ~string
}
```

关于将 constraints 移到 x/exp 的详细说明，见 rsc 提的 issue：<https://github.com/golang/go/issues/50792>。
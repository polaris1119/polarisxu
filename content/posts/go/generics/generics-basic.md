---
title: "Go泛型系列：提前掌握Go泛型的基本使用"
date: 2021-09-28T23:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
---

泛型，是 Go 语言多年来最令人兴奋和根本性的变化之一。没有泛型，很多人以此「鄙视」Go 语言。当然，也有人觉得根本不需要泛型。有泛型，不代表你一定要用。平心而论，有些场景下，泛型还是很有必要和帮助的。

现在已经确认，Go1.18 正式包含泛型（Go1.17 已经可以试用，只是默认不支持，见之前的文章：扬眉吐气：[刚刚，Go 已经默认支持泛型了](https://mp.weixin.qq.com/s/EMcarjLe2CCJZO9t5rM_Ww)）。

不过，不少人对泛型还是迷迷糊糊的。本文就尝试用简单的术语解释泛型相关的内容。

## 01 什么是泛型

Go 是一门强类型语言，意味着程序中的每个变量和值都有某种特定的类型，例如`int`、`string` 等。在函数签名中，我们需要对参数和返回值指定类型，如下所示：

```go
func Add(a, b int) int
```

参数 `a` 和 `b` 的类型是 `int`，返回值类型也是 `int`，结果是 `a` 和 `b` 的和。

如果现在需要一个对两个 `float64` 求和的函数，怎么办？

大概率会出现类似这样的函数：

```go
func AddFloat(a, b float64) float64
```

如果有更多其他的类型（比如字符串相加），可能需要写更多的对应版本函数，很不方便，也很繁琐，一堆复制粘贴的代码。

## 02 Go 中的泛型函数

如果有了泛型，上面的问题怎么解决呢？只需要一个函数就搞定：

```go
func Add[T any](a, b T) T
```

是不是很简单？不过看着有点晕？稍微解释下：

- Add 后面的 `[T any]`，T 表示类型的标识，any 表示 T 可以是任意类型
- a、b 和返回值的类型 T 和前面的 T 是同一个类型
- 为什么用 `[]`，而不是其他语言中的 `<>`，官方有过解释，大概就是 `<>` 会有歧义。曾经计划使用 `()`，因为太容易混淆，最后使用了 `[]`。

这样就表示，a、b 和返回值可以是任意类型，但它们的类型是同一个。那具体是什么类型如何确定呢？根据调用时的实际参数决定。因此，我们现在可以这么使用：

```go
Add(1, 2)
Add(2.1, 3.2)
```

不过，这时候代码会报错。你可以本地用 Go1.17 启用泛型的方式试验，也可以使用 gotip 版本，亦或直接访问这里试验：<https://gotipplay.golang.org/p/vTHnUA_8vOI>

```go
package main

import (
	"fmt"
)

func Add[T any](a, b T) T {
	return a + b
}

func main() {
	fmt.Println(Add(1, 2))
	fmt.Println(Add(2.1, 3.2))
}
```

运行会报错：

```bash
type checking failed for main
prog.go2:8:9: invalid operation: operator + not defined for a (variable of type parameter type T)
```

为什么？请看下文。

## 03 约束

很显然，并非所有类型都支持加法操作。因此我们需要给出约束，指定可以进行加法操作的类型。

上面代码中，我们对类型 T 使用的是 any，相当于没有进行任何约束。现在我们给一个约束：

```go
type Addable interface {
	type int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uintptr, float32, float64, complex64, complex128, string
}
```

这是新语法，叫做类型列表（type list）。

首先，Addable 重用了接口语法，即 interface 关键字，表示约束，具体约束的类型通过 type 指定，多个用逗号分隔。

现在 Add 函数中 T 的约束从 any 改为 Addable：

```go
func Add[T Addable](a, b T) T {
	return a + b
}
```

现在再次运行：<https://gotipplay.golang.org/p/kR_B6OUyDXA>，发现正常了。而且还支持字符串、复数等：

```go
Add("polaris", "xu")
```

可见，约束可以是任意接口类型。（any 相当于空接口）

还有另外一种场景：可比较。比如 map 中的 key 要求是可比较的。比如下面的代码：

```go
func findFunc[T any](a []T, v T) int {
	for i, e := range a {
		if e == v {
			return i
		}
	}
	return -1
}
```

T 的约束是任意类型，而实际上并非所有类型都是可比较的。怎么办？我们当然可以向上面 Addable 一样定义一个约束，但为了方便，Go 内置提供了一个 `comparable` 约束，表示可比较的。参考下面代码：

```go
package main

func findFunc[T comparable](a []T, v T) int {
	for i, e := range a {
		if e == v {
			return i
		}
	}
	return -1
}

func main() {
	print(findFunc([]int{1, 2, 3, 4, 5, 6}, 5))
}
```

## 04 constraints 包

写泛型代码时，约束挺常见。再看一个例子，从切片中找出最大值：

```go
func Max[T any](input []T) (max T) {
    for _, v := range input {
        if v > max {
            max = v
        }
    }
    return
}
```

但运行会报错：

```go
fmt.Println(Max([]int{1, 4, 2, 10}))
// cannot compare v > max (operator > not defined for T)
```

这时，我们自然想到使用上面 Add 函数类似的办法，自定义一个约束：Ordered，把可能的类型都列上。

```go
type Ordered interface {
    type int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uintptr, float32, float64, string
}
```

因为这样的需求挺常见的，为了方面，官方提供了一个新包：`constraints`，预定义了一些约束，具体查看：<https://github.com/golang/go/issues/45458>。

有了它，不需要自定义这个 Ordered 约束，而是使用 `constraints` 包中的，即：

```css
func Max[T constraints.Ordered](input []T) (max T)
```

## 05 泛型类型

上面，我们介绍了泛型函数：即函数可以接受任意类型。注意和 `interface{}` 这样的任意类型区分开，泛型中的类型，在函数内部并不需要做任何类型断言和反射的工作，在编译期就可以确定具体的类型。

我们知道，Go 支持自定义类型，比如标准库 sort 包中的 IntSlice：

```go
type IntSlice []int
```

此外，还有 `StringSlice`、`Float64Slice` 等，一堆重复代码。如果我们能够定义泛型类型，就不需要定义这么多不同的类型了。比如：

```go
type Slice[T any] []T
```

能看懂吧。

在使用时，针对 int 类型，就是这样：

```go
x := Slice[int]{1, 2, 3}
```

如果作为函数参数，这么使用：

```go
func PrintSlice[T any](b Slice[T])
```

如果为这个类型定义方法，则是这样：

```go
func (b Slice[T]) Print()
```

也就是说，`Slice[T]` 作为整体存在。

当然，泛型类型也可以做类型约束，而不是 any 类型：

```go
type Slice[T comparable] []T
```

## 06 总结

通过本文的讲解，相信你对 Go 泛型有了一个基本的掌握。

Go1.18 会包含不少泛型相关的标准库，包括对现有标准库的泛型支持，这是目前 Go 官方的重要工作。

今天开一个头，后续会不断分享 Go 泛型更多的内容，大家一起提前掌握 Go 泛型。

## 参考资料

- <https://bitfieldconsulting.com/golang/generics>
- <https://github.com/mattn/go-generics-example>
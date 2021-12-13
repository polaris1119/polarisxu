---
title: "Go泛型系列：Go1.18 类型约束那些事"
date: 2021-11-14T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
---

大家好，我是 polarisxu。

上篇[《Go泛型系列：提前掌握Go泛型的基本使用》](https://mp.weixin.qq.com/s/0sdNN7Tlx09Hwtqb-2jlRA)简单讲解了泛型中的约束，但约束相关内容远不止那些，本文介绍更多约束相关内容。

> 请安装最新的 tip 版本，方便验证本文的内容。当然，也可以通过 <https://gotipplay.golang.org/> 在线验证。

## 01 语法变更

上次提到，定义约束的语法类似这样：

```go
type Addable interface {
	type int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uintptr, float32, float64, complex64, complex128, string
}
```

不过目前已经确认，语法改成如下形式：

```go
type Addable interface {
  int | int8 | int16 | int32 | int64 | uint | uint8 | uint16 | uint32 | uint64 | uintptr | float32 | float64 | complex64 | complex128 | string
}
```

对于这样的修改，大家褒贬不一。就语义来说，新的方式 `|` 有或之意，更贴切，而且少了一个 `type`，更简洁。

## 02 额外用法

除了以上提到的优点，新的方式还还有额外的用途，也就是不用每次都定义一个接口约束。

看一个具体示例：

```go
package main

import (
	"fmt"
)

func add[T int|float64](a, b T) T {
	return a + b
}

func main() {
	fmt.Println(add(1, 2))
	fmt.Println(add(1.2, 2.3))
  // fmt.Println(add("a", "b"))
}
// Output:
// 3
// 3.5
```

最后注释的一行代码，会编译报错：`string does not satisfy int|float64`。

注意 add 函数的泛型约束：`T int|float64`。如果约束是逗号分隔，无法采用这种语法：

```go
func add[T int,float64](a, b T) T
```

以上代码显然很不友好，编译器也不好解析。

采用了 `|` 后，不需要每次都定义接口约束，可以让代码更少。不过，这种方式建议只在少数类型约束时才适合，否则可读性太差。

除了以上用法，约束还有一种用法。

在 Go 语言中，基于某类型定义新类型，有时可能希望泛型约束是某类型的所有衍生类型。看一个具体例子：

```go
package main

import (
	"fmt"
)

func add[T ~string](x, y T) T {
	return x + y
}

type MyString string

func main() {
	var x string = "ab"
	var y MyString = "cd"
	fmt.Println(add(x, x))
	fmt.Println(add(y, y))
}

// Output:
// abab
// cdcd
```

注意 add 函数的签名：

```go
func add[T ~string](x, y T) T
```

约束 `~string`  表示支持 string 类型以及底层是 string 类型的类型，因此 MyString 类型值也可以传递给 add。

## 03 注意事项

约束形式的多样性，导致 Go 泛型语法一下子复杂起来：

```go
// 没有任何约束
func add[T any](x, y T) T
// 约束 Addble (需要单独定义)
func add[T Addble](x, y T) T
// 约束允许 int 或 float64 类型
func add[T int|float64](x, y T) T
// 约束允许底层类型是 string 的类型（包括 string 类型）
func add[T ~string](x, y T) T
```

在泛型中，有些场景可能想当然可以成立，但结果可能不成立，在使用时需要注意（当然，不排除将来支持）。比如：

```go
func MakeChan[T chan bool | chan int](c T) {
  _ = make(T) // 错误
   _ = new(T) // 正确
  _ = len(c)  // 正确
}

// 以下代码无法编译：
// cannot range over c (variable of type T constrained by []string|map[int]string) (T has no structural type)
func ForEach[T []string | map[int]string](c T, f func(int, string)) {
	for i, v := range c {
		f(i, v)
	}
}
```

ForEach 函数的签名，你能看懂吗？泛型确实让 Go 复杂起来了，虽然语法允许，但建议大家以后写泛型代码时一定要尽量保证可读性。

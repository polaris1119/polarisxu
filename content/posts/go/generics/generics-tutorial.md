---
title: "Go 泛型入门教程"
date: 2021-12-19T16:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
---

大家好，我是 polarisxu。

有泛型的 Go 版本 1.18 已经发布了 Beta1 版本，之前陆陆续续介绍了泛型，但可能有些人还是对 Go 泛型没有完整的了解，因此有这份入门教程。

## 01 准备工作

开始学习泛型之前，你应该安装 Go1.18 Beta1 或之后发布的版本，建议[使用 goup 等版本管理工具](https://mp.weixin.qq.com/s/yTblk9Js1Zcq5aWVcYGjOA)，当然也可以直接通过 playground 来验证：<https://go.dev/play/?v=gotip>。

不过，本教程基于本地安装 Go1.18 Beta1 为例进行。

```bash
$ goup install 1.18beta1
Downloaded   0.0% (    16384 / 143162528 bytes) ...
Downloaded   5.9% (  8404928 / 143162528 bytes) ...
Downloaded  14.1% ( 20234096 / 143162528 bytes) ...
Downloaded  22.3% ( 31981328 / 143162528 bytes) ...
Downloaded  30.5% ( 43695808 / 143162528 bytes) ...
Downloaded  38.7% ( 55443040 / 143162528 bytes) ...
Downloaded  45.7% ( 65486352 / 143162528 bytes) ...
Downloaded  53.9% ( 77200832 / 143162528 bytes) ...
Downloaded  62.1% ( 88866144 / 143162528 bytes) ...
Downloaded  70.3% (100580624 / 143162528 bytes) ...
Downloaded  78.4% (112295088 / 143162528 bytes) ...
Downloaded  85.5% (122371168 / 143162528 bytes) ...
Downloaded  93.7% (134102032 / 143162528 bytes) ...
Downloaded 100.0% (143162528 / 143162528 bytes)
INFO[0013] Unpacking /Users/xuxinhua/.go/go1.18beta1/go1.18beta1.darwin-amd64.tar.gz ...
INFO[0020] Success: go1.18beta1 downloaded in /Users/xuxinhua/.go/go1.18beta1
INFO[0020] Default Go is set to 'go1.18beta1'
```

验证是否安装成功：

```bash
$ go version
go version go1.18beta1 darwin/amd64
```

## 02 创建项目

切换到 `$HOME` 目录，Linux/Mac 执行：

```bash
$ cd ~
```

Windows 下执行（在 C 盘，基于 cmd 或 PowerShell）：

```bash
C:\> cd %HOMEPATH%
```

然后创建目录并初始化模块：

```bash
$ mkdir generics
$ cd generics
$ go mod init github.com/polaris1119/generics
go: creating new go.mod: module github.com/polaris1119/generics
```

> 其中的模块前缀可以替换为你喜欢的名字。

## 03 添加非泛型函数

下面以 map 为例，先看非泛型如何处理，泛型又是如何处理。

假如有两个 map，分别是 map[string]int 和 map[string]float64，编写函数将 map 中的 value 值相加，返回结果。因为有两个类型，因此编写两个函数。

```go
func SumInts(m map[string]int) int {
    var s int
    for _, v := range m {
        s += v
    }
    return s
}

func SumFloats(m map[string]float64) float64 {
    var s float64
    for _, v := range m {
        s += v
    }
    return s
}
```

在 main 函数中初始化两个 map 并调用上面的函数。

```go
func main() {
    ints := map[string]int{
        "first":  34,
        "second": 12,
    }

    floats := map[string]float64{
        "first":  35.98,
        "second": 26.99,
    }

    fmt.Printf("非泛型计算结果，SumInts: %v, SumFloats: %v\n", SumInts(ints), SumFloats(floats))
}
```

运行后，输出结果：

```bash
$ go run main.go
非泛型计算结果，SumInts: 46, SumFloats: 62.97
```

虽然得到了想要的结果，但 SumInts 和 SumFloats 的逻辑差不多。如果将来有其他类型，我们必须增加额外的函数，代码逻辑也类似。

有了泛型，只需要一个函数就可以实现以上两个函数的功能，而且可以方便扩展为支持其他相关类型，比如 map[int]float64 等。

## 03 泛型处理多类型

要支持任一类型的值，该函数将需要一种方法来声明它支持的类型。同时，调用者需要一种方法来指定它是使用整数 map 还是浮点数 map 进行调用，即调用时指定实际参数的类型。

为了支持这一点，需要编写一个函数，除了它的普通函数参数外，还需要声明类型参数。这些类型参数使函数具有通用性，使其能够处理不同类型的参数。这样，你可以使用类型参数和普通函数参数调用该通用函数，即泛型函数。

每个类型参数都有一个类型约束，作为类型参数的一种元类型。每个类型约束指定调用代码可以用于相应类型参数的允许类型。

虽然类型参数的约束通常表示一组类型，但在编译时类型参数代表单个类型——调用代码作为类型参数提供的类型。如果类型参数的约束不允许该调用者指定的类型，则代码将无法编译。

请记住，类型参数必须支持泛型代码对其执行的所有操作。例如，函数对参数执行加减运算，而 string 是不支持的，因此约束中不能包含 string 类型，否则代码将无法编译。

如果没看懂，就看具体代码：

```go
func SumIntsOrFloats[K comparable, V int | float64](m map[K]V) V {
    var s V
    for _, v := range m {
        s += v
    }
    return s
}
```

函数 SumIntsOrFloats 声明了两种参数：类型参数和普通函数参数。其中类型参数放在 `[]` 中，普通参数依然放在 `()` 中。（别问类型参数为什么不用 `<>`，官方给了解释：<https://groups.google.com/g/golang-nuts/c/7t-Q2vt60J8/m/65D5xBDvBgAJ>）

该函数的类型参数是：`K comparable, V int | float64`，其中 K、V 的名字不重要，分别表示某种类型，comparable 和 `int | float64` 是 K、V 类型的约束，即调用该方法时，K、V 允许的类型。comparable 是语言预定义的约束，官方的解释如下：<https://pkg.go.dev/builtin@master#comparable>

> comparable is an interface that is implemented by all comparable types (booleans, numbers, strings, pointers, channels, interfaces, arrays of comparable types, structs whose fields are all comparable types). The comparable interface may only be used as a type parameter constraint, not as the type of a variable.

即表示所有可比较类型，也就是说，K 可以是任意可比较类型。

而 V 的类型约束 `int | float64` 表示只允许是 int 或 float64，其他类型编译会报错。关于类型约束更多内容，可以参考我之前写的文章：[Go1.18 类型约束那些事](https://mp.weixin.qq.com/s/FFxNpRVgs-v9cIKWCLeN4Q)。

再看该函数的普通参数：m map[K]V，这表明，m 是一个 map，它的 key 类型是 K，value 类型是 V。很显然，这两个是该函数「类型参数」定义的类型。

泛型函数有了，该如何调用呢？

在 main 中增加如下调用：

```go
fmt.Printf("泛型计算结果，Ints 结果: Floats 结果: %v\n", SumIntsOrFloats[string, int](ints), SumIntsOrFloats[string, float64](floats))
```

同一个函数，支持 map[string]int 和 map[string]float64。

注意，我们在调用函数和声明函数类型，用 `[]` 指定了具体的类型，比如 `SumIntsOrFloats[string, int](ints)`，即调用时普通参数是什么类型通过 `[]` 指定。很显然，这很繁琐，实际上 Go 会进行类型推断，即编译器会通过普通参数的类型推导出「类型参数」。不过，跟 Go 中其他类型自动推导类似，有些情况是无法自动推导的，这时候必须手动指定实际的类型参数。

因此，上面的调用代码也可以简写为：

```go
fmt.Printf("泛型计算结果，Ints 结果: Floats 结果: %v\n", SumIntsOrFloats(ints), SumIntsOrFloats(floats))
```

运行后，得到如下结果：

```bash
$ go run main.go
非泛型计算结果，SumInts: 46, SumFloats: 62.97
泛型计算结果，Ints 结果: 46, Floats 结果: 62.97
```

## 04 声明类型约束

上文已经大概解释了类型约束，针对本文例子，解释下类型约束。

上面没有将 `int | float64` 定义为一个命名约束，相当于约束字面量（或联合类型）。一般有两种场景会单独声明类型约束：

- 约束太长，比如有很多类型，直接写在函数中，会严重影响可读性
- 方便类型约束重用

将上面 V 的约束定义为单独的类型约束：（实际是接口，但不能作为单独类型使用）

```go
type Number interface{
  int | float64
}
```

基于此定义另外一个函数 SumNumbers：

```go
func SumNumbers[K comparable, V Number](m map[K]V) V {
    var s V
    for _, v := range m {
        s += v
    }
    return s
}
```

类似的，可以这样调用（省略了「类型参数」）：

```go
fmt.Printf("泛型计算结果（带 Constraint），Ints 结果: %v, Floats 结果: %v\n",
    SumNumbers(ints),
    SumNumbers(floats))
```

## 05 总结

泛型的内容远不止这些，但本文作为入门教程，旨在介绍基础内容，让大家对泛型使用有一个基本了解。本文的示例参照官方泛型教程：<https://go.dev/doc/tutorial/generics>。

本文完整代码见 playground：<https://go.dev/play/p/TwS6wda3nbv?v=gotip>。

---
title: "Rust 劝退系列 03：变量"
date: 2021-04-19T12:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - rust
  - 变量
---

大家好，我是站长 polarisxu。

这是 Rust 劝退系列的第 3 个教程，探讨 Rust 中的变量。

## 01 变量和绑定

变量指定了某存储单元（Memory Location）的名称，该存储单元会存储特定类型的值。

Rust 是静态类型语言，不能在运行期改变变量类型。

和你熟悉的大部分编程语言不一样，Rust 中变量一般不叫声明，而叫做绑定（这是从函数式语言中借鉴的，使用关键字 let 绑定），那有什么区别呢？

在 Go 语言中一般有下面几种声明变量的方式：

```go
var age = 10
var age int
var age int = 10
age := 10	// 只能在函数内部使用
// 可以分组
var (
	age = 10
  birthday = "01-01"
)
```

Go 中声明变量，可以不指定类型（会进行类型推导），也可以不给初始值（会有默认初始值）。

而 Rust 中，形式比较少，主要有两种：

```rust
let age = 10;
let age: i32 = 10;
```

和 Go 一样，大部分时候，Rust 也能够推导出类型。在显示指定类型时，需要加上 `:`。关于类型，后续讲解。

那为什么 Rust 中变量创建一般叫做绑定呢？

1）Rust 和 C 一样，变量创建后必须初始化后才能使用（未使用的变量会警告）。以下代码编译报错：

```rust
fn main() {
    let age: i32;
    println!("age is {}", age);
}
// error[E0381]: borrow of possibly-uninitialized variable: `age`
```

2）Rust 中，通过 let 关键字，在标识符（如变量 age）与值（如 10）之间建立起一种关联关系。表明所有权关系。也就是说这块内存现在属于 age 了。

> 熟悉 JS 的朋友，应该对 var 和 let 很亲切，不过两者的区别和 Go 中的 var 与 Rust 的 let 区别不一样。

## 02 可变性

第一次看到下面的代码报错，你肯定特别的惊讶：

```rust
fn main() {
    let age = 10;
   	println!("age is {}", age);
    age = 11;
    println!("age is {}", age);
}
// error[E0384]: cannot assign twice to immutable variable `age`
```

没错，Rust 中的变量默认是不可变的（好吧，变量不可变。。。但又不是常量）。这也是 Rust 中内存管理很重要的一个特性。

如果我想变量可变，怎么办？Rust 提供了关键字 mut，这叫做可变绑定：

```rust
fn main() {
    let mut age = 10;
   	println!("age is {}", age);
    age = 11;
    println!("age is {}", age);
}
```

通常，我们应该优先创建不可变变量，只有真的需要时，才使用可变变量。

## 03 隐藏（shadow）

因为变量默认不可变，Rust 中还存在这样「诡异」的情况。下面代码一切正常：

```rust
fn main() {
    let age = 10;
   	println!("age is {}", age);
    let age = 11;
    println!("age is {}", age);
}
```

在 Go 中，肯定报重复声明。

这种「重复」创建同名变量的语法，Rust 中叫做隐藏（Shadow）。也就是说上次创建的被这次创建的隐藏了。具体有什么用呢？

比如类似这样的代码，在 Go 中还是比较常见的：

```go
ageStr := req.FormValue("age")
age, err := strconv.Atoi(ageStr)
```

也就是说，同样的数值，因为类型不同，需要用两个不同名称的变量表示。但 Rust 中可以这样：

```rust
fn main() {
    let age = "10";
    let age = age.parse::<i32>().unwrap();
   	println!("age is {}", age);
}
```

不过这种语法有好处也有弊端。当涉及到作用域时，要特别注意隐藏的问题。这和 Go 中的简短声明（:=）的「坑」很像。类似下面这样的代码，最后的 age 依然是 10：（实际中的代码一般不会这么明显）

```rust
fn main() {
    let age = 10;
    {
        let age = "abc";
        println!("age is {}", age);
    }
   	println!("age is {}", age);
}
// age is abc
// age is 10
```

可见，隐藏只会其所属作用域内生效。

## 04 小结

Rust 是静态类型语言，运行期间不能改变变量类型。

- 通过 let 创建变量，Rust 中一般叫做变量绑定；
- 默认变量不可变，创建可变绑定，可以在变量名前加上 mut 关键字；
- 重复定义重名变量会隐藏（shadow）之前的变量，但要注意作用域问题；

本节内容还是比较简单的，但要注意和你所学语言不同的点以及可能的坑。没被劝退吧~
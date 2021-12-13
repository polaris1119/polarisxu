---
title: "Rust 劝退系列 08：模式匹配"
date: 2021-06-08T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - rust
  - match
---

大家好，我是站长 polarisxu。

这是 Rust 劝退系列的第 8 个教程，探讨 Rust 中的模式匹配。

## 01 match 表达式

关于 match 表达式，很多其他语言并没有，比如 Go 语言。不过有些语言开始支持 match，比如 PHP 8.0 就有了 match 表达式。

一般地可以认为 match 和 switch 类似，所以 Rust 中没有 switch。

match 用于检查某个当前的值是否匹配一组/列值中的某一个。看一个具体的例子：

```rust
fn test_match(number: i32) -> &'static str {
    match number {
        // 匹配单个值
        1 => {println!("One!"); "One!"},
        // 匹配多个值
        2 | 3 | 5 | 7 | 11 => "This is a prime",
        // 匹配一个闭区间范围
        13..=19 => "A teen",
        // 处理其他情况
        _ => "Ain't special",
    }
}
```

看起来是一个简单的语法结构，但大概率在其他语言没见过。简单解释下：

- 跟其他语言的 switch 类似，可以匹配多个分支；多个分支之间，使用 `,` 分隔；
- 在 match 分支中，`=>` 左侧是模式，因此叫做模式匹配，比如 | 表示匹配多个值；`..=` 表示匹配一个范围；右侧是在左侧匹配成功时要执行的操作；
- match 要求穷尽，也就是要包含所有可能的值。因此提供了 `_`，用来处理所有其他情况，类似 switch 的 default 分支；但只要穷尽了，可以没有 `_`；
- 如果右侧操作是多个语句，需要放在 `{}` 中；
- match 是表达式，它的结果是匹配到的模式中，执行操作的最后一个表达式的结果。这在 Rust 中是很常见的，之前提到过，Rust 中一切皆表达式。所以，这个例子中 match 表达式的值即为函数的返回值。因此，match 的所有分支必须返回同一数据类型；
- 注意 match 表达式最后是否有分号的区别；

> 日常吐槽：在 match 中匹配区间，如果想和 for in 一样，使用 `..` 来表示半闭半开区间，结果报错。看到资料说应该使用 `…`，但却提示该语法已废弃！为啥语法结构还不保持一致呢？！

看一个接收 match 结果的例子：

```rust
let boolean = true;
let binary = match boolean {
  false => 0,
  true => 1,
};	// 注意这里的分号
println!("{} -> {}", boolean, binary);
```

## 02 match 其他用法

上面介绍了常规的 match 操作。match 还有很多其他的用法。

### 解构

当元组和 match 一起时，可以解构元组。

```rust
fn main() {
		// 试一试将不同的值赋给 `pair`
    let pair = (0, -2);
    
    println!("Tell me about {:?}", pair);
    // match 可以解构一个元组
    match pair {
        // 解构出第二个值
        (0, y) => println!("First is `0` and `y` is `{:?}`", y),
        (x, 0) => println!("`x` is `{:?}` and last is `0`", x),
        _      => println!("It doesn't matter what they are"),
        // `_` 表示不将值绑定到变量
    }
}
```

关于枚举和指针、引用和 match 的结合，以后遇到再讲解。

### guard 语句

在 match 分支中可以加上过滤条件。接着上面元组解构的例子：

```rust
fn main() {
    let pair = (2, -2);

    println!("Tell me about {:?}", pair);
    match pair {
        (x, y) if x == y => println!("These are twins"),
        // `if` 条件部分是一个卫语句
        (x, y) if x + y == 0 => println!("Antimatter, kaboom!"),
        (x, _) if x % 2 == 1 => println!("The first one is odd"),
        _ => println!("No correlation..."),
    }
}
```

### 绑定

这是什么意思呢？看一个例子：（来自 rust by example）

```rust
// `age` 函数，返回一个 `u32` 值。
fn age() -> u32 {
    15
}

fn main() {
    println!("Tell me type of person you are");

    match age() {
        0             => println!("I'm not born yet I guess"),
        // 可以直接 `match` 1 ..= 12，但怎么把岁数打印出来呢？
        // 在 1 ..= 12 分支中绑定匹配值到 `n` 。现在年龄就可以读取了。
        n @ 1  ..= 12 => println!("I'm a child of age {:?}", n),
        n @ 13 ..= 19 => println!("I'm a teen of age {:?}", n),
        // 不符合上面的范围。返回结果。
        n             => println!("I'm an old person of age {:?}", n),
    }
}
```

match 后是一个函数，我们希望在分支中，根据匹配结果，使用 age 函数的返回值。当然，这个例子有点多此一举，完全可以在 match 之前用变量存储 age 函数的返回值。

那换一个例子：

```rust
fn some_number() -> Option<u32> {
    Some(41)
}

fn main() {
    match some_number() {
        Some(n @ 40..=42) => println!("The Answer: {}!", n),
        Some(n)      => println!("Not interesting... {}", n),
        _            => (),
    }
}
```

- 关于 Option 以后讲解

这个例子很好的讲解了绑定的作用：分支中想要使用匹配的结果，通过 @ 符号可以将匹配的结果和某个变量绑定，然后就可以使用这个变量了。

## 03 if let 和 while let

这两个结构其他语言没见过，可以理解为是某些场景下替代 match，让代码更简洁，因为 match 必须穷尽所有情况，而 if let 和 while let 没有此限制。

以下代码：

```rust
let some_u8_value = Some(3u8);
match some_u8_value {
  Some(3) => println!("three"),
  _ => (),	// 有点多余
}
```

改为 if let：

```rust
let some_u8_value = Some(3u8);
if let Some(3) = some_u8_value {
	println!("three");
}
```

- 和 match 一样，if let 和 while let 都是表达式；
- if/while let 等号左侧是模式，右侧是要匹配的值；所以当右侧的值和左侧的模式匹配时，执行对应的语句块；所以，有时候 if let 也可以单纯的当做解构使用；
- if let 支持普通的 else if 和 else；while let 没有 else；

while let 语法和 if let 类似。这里就不举例子了。

## 04 小结

Rust 中的 match 虽然和其他语言的 switch 类似，很显然，match 的复杂度比 switch 高。当然，不管复杂与否，最关键还是要实际使用，需要不断实际练习。

通常，match 和 Option、枚举一起使用，因此，在讲解这两个知识点时，一般会使用到 match。


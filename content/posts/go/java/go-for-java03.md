---
title: "为 Java 开发者准备的 Go 教程 03：Java 有而 Go 无"
date: 2022-01-11T22:30:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - Go
  - Java
---

大家好，我是 polarisxu。

Go 语言的设计是站在巨人的肩膀上的，它吸取了其他语言的优秀设计，同时摒弃了一些「不认可」的设计。同时，为了保持简单性，Go 的特性也比很多其他语言少。因此，Java 有一些特性，Go 没有。但没有，不代表不好。本文就看看具体有哪些。（当然，也存在 Go 有的特性，而 Java 没有）

## 1、多重赋值

Java 可以在一条语句中将同一个值分配给多个变量（很多 C 族语言都支持）。例如：

```java
int x, y, z;
x = y = z = 10;
```

Go 不支持上面的语法。相反，Go 采用另一种形式，有些时候更简便。

```go
var x, y, z int = 10, 10, 10
```

而且，可以是不同类型：

```go
var x, y, z = 10, 12.0, "polarisxu"
```

正因为有这样的语法，在 Go 中交换两个变量的值很方便，不需要引入中间变量：

```go
var x, y = 1, 2
x, y = y, x
```

## 2、语句和运算符

Go 和 Java 运算符具有不同的优先级。Go 的优先级更少，在我看来这更自然。如果不确定，请明确使用括号来指定优先级。一般来说，大家不用刻意去记这些优先级，有一个大概的印象即可。

但有一个关键的区别要记住，在 Go 中，i++ 和 i-- 是语句，而不是表达式。这是什么意思呢？语句就表明不能出现这样恶心的写法（常见的恶心面试题）：

```go
// Go 中非法
x = i++ + y
```

而且，Go 中根本没有 `--i` 或 `++i`。而 Java 是支持的。

Go 还不支持三元表达式。需要使用 if/else 语句代替。这点遭到很多人吐槽，毕竟大部分语言都支持。

```go
// Go 中编译不通过
z := x > y ? x : y

// 得改为类似这样：
var z = y
if x > y {
  z = x
}
```

## 3、Assert 语句

Go 没有 assert（断言）语句。不过 Go 单元测试挺不错的，一般会用测试来做类似的事情，而且也有一些好的测试框架支持 assert。在写 Demo 时，经常 err != nil 时，倾向于用 panic 来中断程序，不过正式代码建议少用 panic。

## 4、While 和 Do 语句

while、do、for 是大部分语言提供的三大循环关键字。然而，Go 认为没必要搞这么多关键字，直接一个 for 搞定。（虽然没有直接替换 do 语句的，但肯定可以用 for 搞定）

```go
// 相当于 while (true) {}
for {}

// 相当于 while (x < 1) {}
for x < 1 {}

// ...
```

注意，Go 中的条件，包括 if 语句的，小括号可以省略，而且没有纠结的 `{` 到底放在哪的问题，规定了只能放在末尾。

## 5、Throw 语句

Go 没有 try/catch，因此也没有 throw。硬要找一个类似的，那就是 panic，但思想是不一样的。

## 6、Java 的一堆修饰符，Go 都没有

比如 strictfp, transient, volatile, synchronized, abstract, static，这些关键字，Go 都没有，也没有类似的。大多数都是不需要的，因为 Java 中需要它们的问题在 Go 中以不同的方式得到解决。例如，通过将变量声明为 package 级来实现与静态值类似的效果。

## 7、对象、类、内部类、构造函数、this、super 等

Go 不像 Java 那样完全支持面向对象编程（OOP）。因此，它不支持这些 Java 结构。但 Go 不少功能可以与大多数 OOP 功能类似使用，后续文章会讲解。因此，Go 最好被描述为一种基于对象的语言。Go 允许实现 OOP 的一些关键目标，但与严格的 OOP 语言通常所采用的方式不同。最主要的是 Go 不支持继承（虽然可以模拟类似继承的功能），强调使用组合，因为继承有点被乱用了。

Go 不支持类，也没有构造函数（一般通过实现一个普通 New 函数充当构造函数），但有类似的功能，比如支持为类型定义方法，支持实现接口等。Go 的类型嵌套是组合，勉强有点类似 Java 的内部类。

Go 不需要显示声明实现哪个接口，而是一种隐式实现，大家通常称为 duck type。

Go 没有 this、super 等关键字。

## 8、函数式编程

虽然 Go 一开始就将函数定义为一等公民，但函数式相关功能支持不多，比如典型的实用函数（map、reduce、select、exclude、forEach、find 等），这是 Go 故意为之，主要考虑简单性。随着 Go 引入泛型，相关实用函数会考虑纳入。

这方面，Java 也是后来才加入的。

> 注：Java5 开始支持泛型，Go 在 1.18 支持泛型。

## 9、基本类型包装器

Java 集合（数组除外）不能包含基本类型值（primitive values，比如 int、long 等），只能包含对象。因此，Java 为每个基本类型提供包装器类型。为了使集合更易于使用，Java 自动完成了这个包装过程（box），以将其插入到集合中，并在从集合中取出值时展开（unbox）该值。Go 没有这方面的限制。注意，需要使用装箱（box/unbox）是 Java 在内存使用方面不如 Go 高效的一方面原因。

## 10、Annotation（注解）

Go 没有注释。Go Struct 字段可以有标记（tag），这些标记提供类似但更有限的角色。

Annotation、function streams 和 lambda 使 Java（至少部分地）成为一种声明性语言。Go 几乎完全是一种命令式语言。这在有时候会使 Go 代码更加冗长。

此外，Go 中的 build constraints 在某些方面和 Annotation 有类似的效果。

## 11、可见性

Java 支持四种可见性：

- private
- default
- protected
- public

Go 没有以上关键字，Go 只有导出和非导出。导出类似 public，通过首字母大写来指定。首字母小写则是未导出。

## 12、重载/重写

在 Java 中，可以在同一范围内定义具有相同名称但具有不同签名（不同数量和/或类型的参数）的函数。这被称为（通过参数多态性的一种形式）重载函数。Go 不允许重载（overloaded）。

在Java中，具有相同名称和签名的函数可以在继承层次结构的较低层重新定义。这种重新定义的函数被称为（通过继承多态性）重写（overridden）。由于 Go 不支持继承，因此不允许这种方式的重写。不过 Go 中的嵌入类型，有类似重写的功能。

---

肯定还有其他 Java 有而 Go 没有的，欢迎交流！

## 参考

这个系列主要参考以下资料：

- [Go for Java Programmers](https://talks.golang.org/2015/go-for-java-programmers.slide)
- [Java to Go in-depth tutorial](https://yourbasic.org/golang/go-java-tutorial/)
- ### [Go for Java Programmers: ebook](https://www.oreilly.com/library/view/go-for-java/9781484271995/)

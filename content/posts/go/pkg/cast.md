---
title: "Go 第三方库推荐：类型转换如此简单"
date: 2021-08-10T22:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 第三方库
---

大家好，我是 polarisxu。

强类型语言有它的优势，但也有不便利的地方，最典型的就是类型转换。Golang 作为一门强类型语言，而且不支持隐式类型转换，因此这个问题更突出。虽然 Go 提供了不少方式进行类型转换，包括相关的标准库，比如 strconv 包。

然而，strconv 包使用没那么方便，比如 `"8"` 转为 int 类型：

```go
s := "8"
i, err := strconv.Atoi(s)
```

你必须对 err 进行处理，因为返回两个值，没法直接将结果传递给接收 int 参数的函数，使用不方便。

今天给大家介绍一个第三方库，专门处理类型转换的问题。

## 01 为什么需要类型转换

有一些场景会需要使用类型转换：

- 从 yaml、toml、json 等配置文件中读取数据；
- 从网络接收请求数据；
- 其他通过 interface{} 处理数据的情况；
- 。。。

转换为正确的类型，能充分利用强类型的好处，让程序更健壮、更安全。

## 02 spf13/cast

第三方包 github.com/spf13/cast 专门解决类型转换的问题，这个包产生于 hugo。当时主要用于处理 yaml 等配置文件数据的转换。该包不会 panic。

该包目前有 1.6k+ 的 Star，有超过 4000 多个开源项目使用了该包。

这个包使用很简单，主要有两套函数：

1）To_ 形式函数

这些函数始终返回所需的类型。如果无法正确转换为对应的类型，则返回目标类型的零值。

支持的类型包括所有的基本数据类型，还支持 time.Time、time.Duration、slice、map 等常用类型。

比如：

```go
cast.ToString("mayonegg")         // "mayonegg"
cast.ToString(8)                  // "8"
cast.ToString(8.31)               // "8.31"
cast.ToString([]byte("one time")) // "one time"
cast.ToString(nil)                // ""
cast.ToTime("2021-08-10 22:00:00")	// 2021-08-10 22:00:00 +0000 UTC
```

注意，转换为 time.Time 时，需要注意时区问题。ToTime 默认使用 UTC，如果想用其他时区，得类似这么做：

```go
secondsEastOfUTC := int((8 * time.Hour).Seconds())
beijing := time.FixedZone("Beijing Time", secondsEastOfUTC)
fmt.Println(cast.ToTimeInDefaultLocation("2021-08-10 22:00:00", beijing))
```

当然，你也可以这样：

```go
fmt.Println(cast.ToTimeInDefaultLocation("2021-08-10 22:00:00", time.Local))
```

不过，Local 表示本地时区，要明确这个本地是不是你想要的。

2）To_E 形式函数

E 表示 error，也就是说，这一系列函数会返回 error。在无法进行类型转换时，会将错误原因返回。To_ 形式内部调用的是 To_E 形似，只是它忽略了错误。

这种形式就不举例了。一般地，除非你需要区分零值是因为出错导致的还是本身就是零值，否则应该使用 To_ 系列函数，毕竟更省事。

## 03 总结

大概率，不少公司都有自己类似的库。如果没有，可以考虑使用该库，这样的轮子，没太多必要造。不过这个库有一点我不太喜欢，就是没法指定默认值。

比如，我想在转换失败时，返回我的默认值，而不是默认零值，这个包做不到。常见的场景就是，处理用户可选输入，如果用户没输入，给一个默认值。

配置文件也有这样的场景，比如某个配置项如果没有配置，我希望硬编码一个默认值。因为 cast 不支持，依赖 cast 的 github.com/spf13/viper 库也不支持默认值，导致我会写出这样的繁琐代码：

```go
viper.SetDefault("listen.port", "2021")
port := viper.GetString("listen.port")
```

我更希望的是这样的代码：

```go
port := viper.GetString("listen.port", "2021")	// listen.port 没设置时，返回 2021
```


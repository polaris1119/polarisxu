---
title: "Go 官方应该搞一个类似 Rustup 的管理工具"
date: 2021-02-25T15:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Rustup
---

大家好，我是站长 polarisxu。

搭建开发环境复杂，会让很多新手抓狂。比如看到有人吐槽 Python 环境复杂，而搭建 PHP 环境，出现了很多一键安装包，像 lnmp 等。可见大家开始上手时，希望能够在环境上少一些折腾，别还没入门就劝退。

在早期，搭建 Go 语言开发环境，什么 GOROOT、GOPATH、GOBIN，很多新手一头雾水，经常稀里糊涂配置上了，写项目 go install 一下，找不到编译好的程序跑哪去了。。。

## 01 一个新的提案

Go 1.5 实现了自举，如果要源码安装 Go，需要先安装 Go1.4。今天看到 rsc 发布了一个提案：[将 Go 1.16 用作 Go 1.18 的引导工具链](https://github.com/golang/go/issues/44505)，这意味着不再是 Go 1.4 了。

rsc 在提案中提到，最初计划实现自举时，计划采用滚动的方式，即下一个版本通过上一个版本构建，比如 Go1.4 用 Go1.3 构建，Go1.5 用 Go1.4 构建，但这样特别麻烦。比如我想源码安装最新的 Go1.16，我得先有 Go1.15。。。

所以，最后改成了固定使用 Go1.4 来构建，即要构建 Go1.x，对于 x ≥ 5，需要 `$GOROOT_BOOTSTRAP` 中已经安装 Go1.4 或更新版本，而该环境变量的默认值就是 `$HOME/go1.4`。

但现在距离 Go1.4 已经过去 6 年了，Go 发生了很多变化，特别是 M1 mac 的出现，使得 Go1.4 无法满足一些需求。因此 rsc 认为需要进行迭代，于是建议采用 Go1.16 作为引导工具链。

至于为什么是 1.16，而不是 1.15 或 1.17，rsc 也进行了解释：

- Go1.16 增加了 //go:build 指令，代替之前的 `+build`。（我认为还有一个就是上文说的，Go1.15 不支持 M1 mac）
- Go1.17 目前看，没有增加编译器相关的特性，而且可以使用 Go1.16 作为测试 1.17 的引导工具，因为 1.17 还可以使用 1.4 引导，正好可以对比测试；
- Go1.17 将会是第一个使用新的基于寄存器的 ABI 版本，因此可能会存在一些长期存在的 Bug。

当然，不等到 Go1.18 的原因，因为 Go1.18 将包含泛型，改动会很大，不太适合。

rsc 还提到：

> The next obvious entry in the sequence after Go 1.4 and Go 1.16 is Go 1.256, followed by Go 1.65536.
> (Or perhaps that is not quite the right pattern to establish.)

目测 Go2 只是一个概念，Go1.x 可能长时间持续下去。

## 02 梦想一个官方的 Go 安装工具

上面说的提案，主要设计源码构建 Go 的问题。一般用户安装 Go，官方推荐怎么做的呢？

一般是推荐下载对应系统的预编译好版本，比如 Linux 系统，下载 go1.16.linux-amd64.tar.gz，然后执行：

```bash
$ tar -C /usr/local -xzf go1.16.linux-amd64.tar.gz
```

接着将 /usr/local/go/bin 加入 PATH 环境变量，一般建议修改 $HOME/.profile 或 /etc/profile：

```bash
export PATH=$PATH:/usr/local/go/bin
```

这个过程并不复杂。（其他系统也是类似操作）

但存在以下问题：

- 有新版本，如何升级？
- 我想试验其他版本，如何做？
- 如何卸载 Go？

正因为有这样的问题存在，但官方没有直接提供解决方案，于是 Go 社区出现了各种类似的解决方案，比如 goup、gvm 等，但毕竟不是官方的，很多人并不知晓它们的存在。

反观 Rust 的安装，只需要如下一行代码：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

这是下载 rustup，同时通过 rustup 来安装 Rust，需要的环境变量也会帮设置好，而且类 Unix 系统都推荐采用这种方式安装。即使是 Windows 系统，也是下载 rustup 工具，然后通过它来安装 Rust。

安装了 Rust 后，上面提到的 Go 的三个问题，Rustup 都很好的解决了，而且它还能直接切换 Beta、Nightly 版本。

我们知道安装 Go 存在一个内地是否能正常下载的问题，这包括下载 Go 本身和下载依赖的第三方包。早期是很痛苦的，现在好很多。Go 官方专门为内地搭建了一个官网 <https://golang.google.cn>，同时 GOPROXY 的存在，国内社区开发了相应的 proxy。

但这两道门槛，还是会让部分新手头疼：

- 官网怎么访问不了？怎么下载 Go？
- 安装完 Go 后，写代码，依赖总是下载报错，因为默认的 GOPROXY 内地也访问不了。。。

当然，国外并不存在这样的问题。但国内这个大市场，Go 应该考虑下。

所以，我觉得 Go 应该提供一个 Rustup 这样的官方工具，而且可以方便修改下载镜像，解决下载不了和慢的问题。当然这只是我的美好愿望~（不知道会不会有人向官方提 issue，或者大概率会被拒？）


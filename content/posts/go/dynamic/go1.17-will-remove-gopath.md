---
title: "Go1.17 快报：将移除 GOPATH"
date: 2021-02-19T09:20:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Rust
  - Go
---

大家好，我是站长 polarisxu。

是的，没看错，Go 1.16 刚正式发布，但这里说的是 Go1.17 将会包含的改变（不出意外的话），我会出一系列文章介绍 Go1.17 的变化。

关于 Go 1.16 的变化。Reddit 上有一张图总结的挺好的：

![](imgs/go1.16-full-feature.png)

相关的知识点，我之前也写过很好几篇文章，有兴趣的可以看看：

- [Go 1.16 的这个新变化需要适应下：go get 和 go install 的变化](https://mp.weixin.qq.com/s/18AZEEX1UeShLx6-9Ir9Zw)
- [提前试用将在 Go1.16 中发布的内嵌静态资源功能](https://mp.weixin.qq.com/s/SiCTV7R2wA_I2nCQkC3GGQ)
- [基于 Go1.16 实现静态文件的 HTTP Cache](https://mp.weixin.qq.com/s/dxDQkMGLB9sTsklWzx_pnQ)
- [图书《Go 语言标准库》更新了：io/fs 包讲解](https://mp.weixin.qq.com/s/8ukhxjSPqK5e9wSJyKGTZA)

刚刚 Go 官方发表[博文](https://docs.studygolang.com/blog/go116-module-changes)，针对 Go1.16 中 “Modules on by default” 进行了详细讲解。默认启用 Module 是什么意思？也就是说 GO111MODULE=on，进一步，即使没有 go.mod ，go 命令现在仍以模块感知模式（module-aware mode）构建包。

尽管如此，你至少还可以手动禁用 Module，即设置  GO111MODULE=off。

但官方计划在 Go1.17 中移除  GO111MODULE 这个环境变量，届时将只能使用 Module 模式。Go 语言总是针对某个问题的尽量只有一种解决方案，保持其简单的“本性”，我个人还是挺喜欢的。当然我相信也会有人不喜欢。

这里给大家一些建议：

- 网上的文章，讲解 Go 环境搭建的，如果不是基于 module，而是 GOPATH 的，直接忽略。GOPATH 的历史，有兴趣可以了解，但作为新手，入门时多半下载的最新版本 Go，这时如果看到文章还是 GOPATH 年代的，基本环境都搞不定，会很有受挫感。
- 目前市面上的图书，大部分都还是基于 GOPATH 的（注：我出版的 《Go 语言编程之旅》是基于 Module 的），这部分内容，基本也可以略过，毕竟 GOPATH 要进博物馆了。
- 如果还没有迁移到支持 Module 的版本，这半年时间尽快迁移吧，毕竟现在的库基本会基于 Module 构建，Go 1.17 预计 2021 年 8 月发布，距离 Go 1.11 过去好几个版本了，给了充足的过度时间。

此外，在 Go1.17 中关于 module 的特性还会有其他改进，比如支持 [lazy module loading](https://github.com/golang/go/issues/36460)，这应该会使模块加载过程更快，更稳定。对 Go1.17 中其他设计模块变化的部分，可以通过 <https://github.com/golang/go/labels/modules> 查看。

对于 Go 做出废弃 GOPATH 的决定，你怎么看？
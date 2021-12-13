---
title: "Go 官网要变天。。。"
date: 2021-08-24T22:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 官网
---

大家好，我是 polarisxu。

Golang 官网，有些人可能从来没有访问过，因为国内一般访问不了。但我经常和「它」打交道，因为 Go 语言中文网很早就对 Go 官网做了一个镜像。最近 Go1.17 发布了，利用周末，我把 Go 官网镜像升级了下，但折腾了很久。。。发现 Go 官网要「变天」了！

之前写过一篇文章：[《回顾 Go 官网的演变史》](https://mp.weixin.qq.com/s/7lkBRmjEkElvqHmJVVBWwQ)，没看的可以看看。

## 01 这次又变了

如果你访问了 Go 官网（golang.org），会发现：点击 Packages，跳转到 pkg.go.dev 去了；点击 Blog，跳转到 <https://go.dev/blog/> 了。而且，[Russ Cox 发博文](https://go.dev/blog/tidy-web)说，在接下来的 1、2 个月内，要将 golang.org 合并入 go.dev。根据 Russ Cox 的说法，现在 Go 相关网站很混乱：

> go.dev 包含了一些有用的信息来帮助人们评估 Go，但是 golang. org 继续提供分发下载、文档和标准库的包参考。其他网站 ---- blog.golang. org、 play.golang. org、 talks.golang.org 和 tour.golang. org---- 也提供其他材料。这一切都有点支离破碎，令人困惑。

所以，Go 官方希望能够统一。

## 02 目前 Go 语言中文网继续提供原风格镜像

实话说，我个人不太喜欢 go.dev 的风格，特别是看标准库，有点别扭，不过可能迟早要习惯！

因为官方大的变动，导致每次想搭建一个镜像，特别费劲。经过折腾，目前依然保持了原 golang.org 风格的官网镜像：<https://docs.studygolang.com>，国内随便访问，同时 blog、play 等都可以正常访问。

不过，如果 golang.org 彻底废弃，这个镜像可能很难维持原风格，毕竟需要保持更新。还有一种方案就是，更新的内容，我处理成兼容原风格版本！我尽量努力做到，因为我还在基于这个风格翻译成中文版。

---

你喜欢 go.dev 的风格吗？欢迎留言交流！


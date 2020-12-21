---
title: "听说你还不知道如何查看 Go 历史文档？"
date: 2020-12-17T17:15:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 标准库
  - pkgsite
---

大家好，我是站长 polarisxu。

这是一篇短文，写这篇文章主要是看到了两个信息：

- tonybai 写的[《如何查看历史版本的 Go 文档？》](https://tonybai.com/2020/12/15/how-to-see-the-manual-of-go-history-version/)
- Go 官方发博文，2021 年初开始，[godoc.org 默认将重定向到 pkg.go.dev](https://docs.studygolang.com/blog/godoc.org-redirect)；

tonybai 在文章中说了两种方法：

- 利用 go doc，可行，但非最优。比如 go doc http.Request。通过切换本地的 Go 版本实现查看不同版本的 Go 标准库文档；
- 使用 godoc 建立历史版本的 Web 化文档中心。这种方式需要额外安装 godoc：`go get golang.org/x/tools/cmd/godoc`。这种方法相当于本地启动一个旧版 Go 官网。godoc 支持一个参数 -goroot 来指定不同的 Go 版本目录树；

但这两种方法都挺费劲的，因为需要你本地有各个版本的 Go 源码。以前没有更好的方法，但自从有了 pkg.go.dev，查看历史文档方便多了。因为 pkg.go.dev 更懂 Go module，通过它不仅可以查看标准库的历史版本文档，而且可以查看第三方库的历史版本。具体可以查看这里：<https://pkg.go.dev/std?tab=versions>。

虽然 godoc.org 也可以同时查看标准库文档和第三方库文档，但没有历史版本。pkg.go.dev 经过一年多的发展，经历了开源、重构等，官方终于决定正式弃用 godoc.org，将其重定向到 pkg.go.dev。

所以，是时候使用 pkg.go.dev 了，而且它可以直接访问，而不像 golang.org 不能访问。

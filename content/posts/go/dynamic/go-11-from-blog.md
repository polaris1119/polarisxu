---
title: "说好的 Go1.17 支持泛型又推迟了：给你 GopherCon2020 全套 PPT 安慰下"
date: 2020-11-12T10:30:00+08:00
toc: true
draft: true
isCJKLanguage: true
tags: 
  - GitHub
  - Nitro
---

2020 年 11 月 10 日是 Go 开源 11 周年，Go 官方发表了一篇博文：《[Eleven Years of Go](https://docs.studygolang.com/blog/11years)》，回顾了过去一年 Go 的发展，同时展望未来一年，将要做的事情。

## 01 过去一年回顾

过去一年，因为疫情，大家都很难。Go 的发展也多少有些影响，但依然有不少产出。

首先是去年 11 月份发布了 go.dev 和 pkg.go.dev。然后在 2020 年 2 月份如期发布了 Go1.14，这个版本明确了 Go Module 可以用于生产环境，同时提升了 defer 的性能和 goroutine 的抢占调度，减少了调度和 GC 的延迟。

2 月份，发布了一个全新的、用于 protocol buffer 的 API，即 google.golang.org/protobuf，对协议缓冲区反射和自定义消息的支持有了很大的改进。

6 月 VSCode Go 扩展正式成为 Go 项目，由开发 gopls 的开发人员维护。同时 gopls 更加完善，极大的降低了资源的占用。

6 月份还有一件大事，那就是 pkg.go.dev 的源码开放了。

当然，6 月份最重要的一件事是发布了泛型新的设计草案，并提供了原型工具。

7 月份讨论发布了三个设计草案：1）[编译约束重新设计](https://github.com/golang/proposal/blob/master/design/draft-gobuild.md)；比如之前是 +build linux，改为 //go:build linux，通过指令实现；2）[文件系统接口：io/fs](https://github.com/golang/proposal/blob/master/design/draft-iofs.md)，这个设计会在 Go1.16 中发布；3）[内嵌资源草案](https://github.com/golang/proposal/blob/master/design/draft-embed.md)，这个也会在 Go1.16 中发布。我之前写过文章介绍：[提前试用将在 Go1.16 中发布的内嵌静态资源功能](https://mp.weixin.qq.com/s/SiCTV7R2wA_I2nCQkC3GGQ)。

8 月份如期发布 Go1.15，不过这个版本主要是优化和 Bug 修复，并没有什么新特性。优化方面最重要的是重写链接器，使其运行速度提高了 20% ，对于大型构建平均使用的内存减少了 30% 。

## 02 展望未来

还在进行中的 GopherCon 2020，Go Team 将展示 8 个项目：

- Robert Griesemer 演讲 [《Typing [Generic] Go》](https://www.gophercon.com/agenda/session/233094)
- [Go Time 播客的现场录音，由包括 Hana Kim 在内的专家调试人员组成](https://www.gophercon.com/agenda/session/2334490)
- Michael Knyszek 的演讲 [《Evolving the Go Memory Manager's RAM and CPU Efficiency》](https://www.gophercon.com/agenda/session/417940)
- Dan Scales 的演讲 [《Implementing Faster Defers》](https://www.gophercon.com/agenda/session/417941)
- [Go Team 团队的现场问答](https://www.gophercon.com/agenda/session/420539)
- Austin Clements 的演讲[《Pardon the Interruption: Loop Preemption in Go 1.14》](https://www.gophercon.com/agenda/session/417943)
- Jonathan Amsterdam 的演讲 [《Working with Errors》](https://www.gophercon.com/agenda/session/233432)
- Carmen Andoh 的演讲 [《Crossing the Chasm for Go: Two Million Users and Growing》](https://www.gophercon.com/agenda/session/233426)

2021 年 2 月份会发布 Go1.16 版本，上面说了，会包含文件系统接口和静态资源嵌入。随着 Apple 自研芯片的 Mac 发布，需要支持 Apple 的 arm64。在 Go1.16 版本会提供 GOARCH=arm64 MacOS 的支持。也许你没感觉，目前 Module 还是 auto 模式，Go1.16 会起会默认开启，即 GO111MODULE 由 auto 改为 on。

2020 年月中确认新版泛型方案时，说预计在 2021 年 8 月份的 Go1.17 中发布，很遗憾告诉大家，又要推迟了。Go 1.17 会带来较多功能和改进，比如上文提到的 `//go:build` 指令，以及 go test 中的 fuzzing test。

2021 年会进一步在 Go Module 上投入（调查显示，目前 96% 的人使用了 Module），会考虑终止对 GOPATH 的支持，全面使用 Module。同时 godoc.org 会正式统一到 pkg.go.dev 中，pkg.go.dev 的重新设计已经发布，后续也会不断做更多的完善和改进。

## 03 关于泛型

在官方博客，Go Team 表示，大家很期待泛型，因此他们一直在努力，为可投入使用做各种细节的打磨，2021 年这块会是重点。目标是 2021 年底，在 Go1.18 的 Beta 中让大家体验，因此不出意外泛型会在 Go1.18 实现。

**泛型又推迟了一个版本，你还相信爱情吗？**（当然，其实上次官方说法是最早在 Go1.17 实现。）

我个人倒是对 Go 对泛型引入慎重的做法持支持的态度，毕竟这是一个重大的特性，不应该草草决定。

## 04 福利

目前 GopherCon 2020 大会进行中，但他们的演讲 PPT 我已经为你准备好了。比如讲泛型的：

![](imgs/go-11-generic.png)

完整全套 PPT 获取，扫码关注下方 polarisxu 公众号，回复 gophercon2020 可以获取。


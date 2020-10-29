---
title: "更懂 module 的包资源中心：关于 pkg.go.dev 的前世今生和未来"
date: 2019-11-15T08:52:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - pkg
  - module
---

北京时间 2019 年 11 月 14 日凌晨 1 点 16 分，Go 官方团队在 golang-nuts 邮件组宣布 go.dev 上线，这是一个新的 Go 开发人员中心。具体的介绍可以看我之前发布的文章 [大家用Go都做什么？Go官方新发布的 Go.Dev 告诉你](https://mp.weixin.qq.com/s/vwBlrJvHXdWhqWmVFhv7-A)。同时，go.dev 还提供了一个 Go 软件包和模块的新信息资源中心：pkg.go.dev，而在此之前，Go 已经存在了一个包资源网站：godoc.org。2020 年 1 月 31 日，在 Go 官方博客又发布了一篇博文，关于 pkg.go.dev 接下来要做的事情，一时间社区讨论激烈，很多人不解。官方（Russ）对此也进行了解释。本文就官方的博文和 Google 邮件组上的相关内容进行整理总结，分享给大家。

## 一、官方博文 《Next steps for pkg.go.dev》快速解读

1. 将 godoc.org 请求重定向到 pkg.go.dev，并向社区开发者征求反馈意见
2. 回答了开发者比较关心的几个问题：
	- 在迁移过程中，如果 package 没有显示在 pkg.go.dev 上，可以通过从 proxy.golang.org 获取对应版本的 module 来添加；
	- 开发者的package突然出现不明的许可证限制 ，不要慌，后面会优化证书检测算法；
	- pkg.go.dev 是否会开源？很多公司想搭建自己的代码文档中心，目前这个需求在征求意见可填官方的调查问卷：https://google.qualtrics.com/jfe/form/SV_6FHmaLveae6d8Bn

以下是全文：

---

## 介绍

在 2019 年，我们官方启动了 [go.dev](https://go.dev/)，这是 Go 开发人员新的资源中心。

作为该站点的一部分，我们还启动了 [pkg.go.dev](https://pkg.go.dev)，它是有关 Go 软件包和模块的信息资源中心。像 [godoc.org](https://godoc.org/) 一样 ，pkg.go.dev 也提供 Go 文档。然而，它还了解 module，并提供有关软件包以前版本的信息！

今年开始，我们将在 pkg.go.dev 中添加新的更多功能，以帮助我们的用户更好地了解他们的依赖关系，并帮助他们围绕要导入的库做出更好的决策。

## 将 godoc.org 请求重定向到 pkg.go.dev

为了减少在过渡的过程中对用户的打扰，我们计划在今年晚些时候将流量从 godoc.org 重定向到 pkg.go.dev 上。同时我们需要您的及时意见反馈，以确保 pkg.go.dev 能够满足我们所有用户的需求。我们鼓励大家从今天开始使用pkg.go.dev，并提供反馈。

您的反馈将为我们的过渡计划提供信息，目的是使 pkg.go.dev 成为包和模块的主要信息和文档来源。我们确定您想在pkg.go.dev上看到一些内容，并且希望您收到有关这些功能的信息！

您可以通过以下渠道与我们分享您的反馈意见：

- 在 Go 问题跟踪器上发布 (https://golang.org/s/discovery-feedback)；
- 发邮件：go-discovery-feedback@google.com；
- 通过 go.dev 底部的 “Share Feedback” 或 “Report an Issue”；

作为过渡的一部分，我们还将讨论对 pkg.go.dev 进行 API 访问的计划 。我们将在 Go issue 33654 (https://golang.org/s/discovery-updates) 上发布更新 。

## 问答

自 11 月推出以来，我们已经收到 Go 用户关于 pkg.go.dev 的大量反馈 。对于本文的剩下部分，我们将回答一些常见问题，希望对大家有帮助。

### 1. 我的 package 未显示在 pkg.go.dev 上，该怎么做？

我们会定期监控 [Go Module Index](https://index.golang.org/index) 以查找要添加到 pkg.go.dev 的新包。如果在 pkg.go.dev 上没有找到某个包，则可以通过从 proxy.golang.org 获取模块版本来添加它 。有关说明，请参见 https://go.dev/about

### 2.  我的 package 有许可证限制。它会是什么问题？

我们知道，无法在 pkg.go.dev 上完整地看到您想要的 package，这是一个令人沮丧的经历。感谢您在我们改进许可证检测算法过程中的耐心配合。

自 2019 年 11 月推出以来，我们进行了以下改进：

- 更新了我们的许可政策(https://pkg.go.dev/license-policy)，里面包括了我们检测和识别的许可列表；
- 与许可证检查(https://github.com/google/licensecheck)团队合作，改善对版权声明的检测；
- 建立了特殊情况的手动审核流程；

与往常一样，我们的许可政策位于 https://pkg.go.dev/license-policy 。如果您遇到问题，请随时在 Go 问题跟踪器上提交问题 (https://golang.org/x/discovery-feedback)，或发送电子邮件至 go-discovery-feedback@google.com， 以便我们直接与您合作！

### 3. pkg.go.dev 会开源吗，以便可以在我的私人库上运行它？

我们知道，拥有私有代码库的公司希望运行提供模块支持的文档服务器。我们希望帮助满足这一需求，但是我们目前还没有深入的了解这个需求痛点。

我们从用户那里听说，运行 godoc.org 服务器比实际上要复杂得多，因为它是为在 Internet 范围而不是仅在公司内部提供服务而设计的。我们认为当前的 pkg.go.dev 服务将出现相同的问题。

我们认为使用新的服务都能够提供私有代码部署，而不是让每家公司都面临运行在公网上面。而且除了提供文档之外，新服务器还可以为 goimports 和 gopls 提供帮助 。

如果要运行这样的服务，请填一个 3-5 分钟的调查( https://google.qualtrics.com/jfe/form/SV_6FHmaLveae6d8Bn )，以帮助我们更好地了解您的需求。该调查将持续到 2020 年 3 月1日。（polaris 建议：**国内用户可以反馈反馈关于大陆访问不到或慢的问题**。）

最后，我们对 2020 年 pkg.go.dev 的未来感到兴奋，希望广大开发者也一样！我们期待听到您的反馈，并希望与 Go 社区在该迁移中紧密合作。

原文地址：https://blog.golang.org/pkg.go.dev-2020

## 二、Go 团队核心成员 RSC（Russ）在邮件组的回复

以下是他邮件回复内容的整理：

这封邮件有点长，但我希望它能解决大部分讨论。如果您觉得缺少任何东西，请回复，我很高兴继续讨论。

### go.dev 出现的背景

过去一年左右的时间里，我们开始了解的一件事是，下一波 Go 采用者中的许多人都希望拥有一个包含 Go 资源的“一站式”网站，包括如何入门，谁正在使用它，指向学习资源，软件包文档等的链接。新的 [go.dev](http://go.dev) 就是该一站式网站。在宣布它的博客中，我们将其称为 [Go 开发人员的新中心](https://blog.golang.org/go.dev)。

### 为什么 go.dev 不同于 golang.org？

我个人认为，将两者分开可以使 [go.dev](http://go.dev) 包含更多社区内容。从历史上看，[golang.org](http://golang.org) 是权威地谈论 Go 的地方：它具有语言规范，标准库文档，官方下载等。对我们一直很重要的一点是，不要将它与世界上所有其他 Go 内容混在一起。新站点似乎是为其他资源创建更具包容性的场所的机会，因此是第二个站点。

### godoc.org 出现的背景

Gary Burd 从 2012 年末开始创建并运行了 [godoc.org](http://godoc.org)。它曾经是，现在仍然是一个绝妙的主意，并且显然是对 Go 社区的宝贵服务。大约一年后，Gary 决定不再运行并为服务器付费，因此将其交给 Go 项目采用。我们很乐意这样做，以确保所有 Go 用户仍然可以使用此资源。我们在 2014 年采用 [godoc.org](http://godoc.com) 时说过 (https://groups.google.com/g/golang-nuts/c/_rbVuzl-OqA/m/N_xoNaD4kAoJ)，我再说一遍：我非常感谢 Gary 创作的作品。

### 为什么根本没有新的软件包文档站点？为什么不就地更新 godoc.org？

通过引入模块和包的多个版本的概念，我们知道必须更新 [godoc.org](https://godoc.org)。经过一番努力，似乎值得重新开始，特别是因为具有单 VM 数据库的 [godoc.org](https://godoc.org) 服务器设计已经开始有点不合时宜了。除了模块工作之外，我们还要解决其他问题，例如服务的可访问性和整体可伸缩性。

As a side note, there's almost nothing in the Go distribution that has survived eight years without being redone. The compiler, the assembler, the linker, the go command itself, most of the standard library: all of them have been massively overhauled one or more times since the start of Go. That's how we take what we learn and make things better.

顺便提一句，Go 发行版中几乎没有任何内容可以重做 8 年。编译器，汇编器，链接器，go 命令本身，大多数标准库：自 Go 以来，所有这些库均已进行了一次或多次大修。这就是我们学习和改进事情的方式。

这种重写总是涉及一个过渡时期，在这个过渡时期中，旧版本仍然是大多数人使用的主力军，而新版本则为早期采用者测试和发现错误提供了新名称。

### 为什么在 pkg.go.dev 上有新的包文档站点？

Docs for all the packages in the entire ecosystem are exactly the kind of community-generated content that [go.dev](http://go.dev) is meant to help find, so [pkg.go.dev](http://pkg.go.dev) seemed like a good name. Especially since [go.dev](http://go.dev) has a much broader scope than [godoc.org](http://godoc.org), it makes sense to take the opportunity to fold it in and reduce the number of sites a typical user has to be aware of (once the transition is complete).

整个生态系统中所有软件包的文档都是 [go.dev](http://go.dev)，旨在帮助查找社区产生的内容，因此 [pkg.go.dev](https://pkg.go.dev) 似乎是个好名字。尤其是由于 [go.dev](https://go.dev) 的范围比 [godoc.org](http://godoc.org) 更为广泛，因此有机会抓住它并减少它是有意义的。典型用户必须知道的站点数（一旦转换完成）。

### 当 pkg.go.dev 不够完善时，为什么要谈论将 godoc.org 重定向到 pkg.go.dev？

直言不讳，以便您可以帮助我们了解发生了什么问题，因此我们可以在重定向发生之前对其进行修复。我们知道一些事情，但是发现有些事情我们完全不知道也不会感到惊讶。最好是尽早发现而不是后来发现。同样，该博客文章首先是请求反馈有关在实际执行重定向之前需要发生的情况。

### 为什么 pkg.go.dev 需要检测到许可证才能显示文档？为什么没有 godoc.org？

负责 pkg.go.dev 的团队已经花了很多时间与 Google 的律师讨论从互联网下载 Go 源码时我们可以做或不能做的事情。我们遵循的规则是，提供漂亮的 HTML 文档版本会显示原始文档的修改版本，并且只有在获得公认的已知良好许可证的情况下，我们才能这样做。

When we adopted [godoc.org](http://godoc.org) from Gary Burd back in 2014, it did not occur to any of us to put it through that kind of review. If we had, maybe the community would have gone through this licensing pain earlier. For now we are focusing on making changes to [pkg.go.dev](http://pkg.go.dev) rather than correcting past mistakes on [godoc.org](http://godoc.org). (At this point, more scrutiny of what [godoc.org](http://godoc.org) does is not likely to have an outcome that anyone likes.)

当我们在 2014 年采用 Gary Burd 的 godoc.org 时，我们所有人都没有想到要进行这种审查。如果有的话，也许社区会更早地经历这种许可痛苦。目前，我们专注于对 pkg.go.dev 进行更改，而不是更正 godoc.org 上的错误。（在这一点上，对 godoc.org 所做的事情进行更严格的审查可能不会产生任何人喜欢的结果。）

### pkg.go.dev 上不显示那些热门软件包？

现在看来 pkg.go.dev 可以看到至少 100 个其他模块导入的 1200 个模块。其中，看起来 82 被标记为不可再发行，因此我们无法显示其文档。低于 7％，我们正在努力更好地理解这一点。如果有任何是我们的错误，我们将予以解决。

Another thing that was suggested that I think is a great idea is to change the “no docs available” page to have a command-line to bring up the docs in your own local godoc command.

我认为另一个好主意是建议更改 “无可用文档” 页面，以便使用命令行在您自己的本地 godoc 命令中显示该文档。

题外话：一般来说（不仅仅是关于 Go 的内容），你会惊讶于在某种元数据（GitHub meta，package.json，SPDX代码等）中具有声明的 “许可证类型”  但实际上没有许可证文本的软件包数量。这使得许可证无法遵守！例如，MIT 许可证要求“以上版权声明和此许可声明应包含在软件的所有副本或重要部分中”。但是，如果没有要包含的此类通知，仅包含“ // SPDX-License-Identifier：MIT”注释，则实际上没有办法遵守。真是一团糟。如果您从未遇到过程序员如何看待世界与律师如何做之间的差异，那么让我推荐 [What Colour are your bits?](https://ansuz.sooke.bc.ca/entry/23)



 encountered the differences between how programmers see the world

and how lawyers do, let me recommend "[What Colour are your bits?](https://ansuz.sooke.bc.ca/entry/23)"]

### 为什么pkg.go.dev没有开源？

这里没有任何阴谋。最初的计划是将其开源，但是开放源代码给代码库带来了压力，要求它们可以在其他环境中重用。目前，该代码仅针对以下一种情况编写：全球 pkg.go.dev 网站。

我帮助编辑了博客文章，并负责“将pkg.go.dev开源，以便我可以在我的私人代码上运行它吗？”这个问题。对于造成这么多人的冒犯，我深表歉意。

我并不是要暗示没有其他理由来运行文档服务器，只是举例说明我认为 Go 开发人员想要代码的最常见原因。

与我们发布不是全局代理站点的代理的开放源代码参考实现的方式几乎相同，我仍然希望我们将发布不需要模块代码的软件包文档站点的开放源代码参考实现。全球站点。不论是在使用私有代码还是在您的笔记本电脑上使用完全开源的代码，无需在全球范围内实现的实现都可以更轻松地运行。我还希望同一台服务器可以提供索引查询，以使诸如 goimports 和 gopls 之类的工具更快。相比之下，pkg.go.dev 可能无法（至少以不同的方式）为扩展关注点和隐私关注点提供此类查询。

因此，博客文章中的原因是真正的原因：当前的代码不是您可能应该运行的代码，无论是在工作中还是在离线模式下的笔记本电脑上，我都认为我们可以为此提供更好的答案。

但是，我听到所有想要查看网站上正在运行的代码并可能对其做出贡献的所有人，无论是否在其他情况下运行都有意义。我将对此进行调查。

再次感谢您在我们与大家沟通不畅时给我们打招呼。确实有帮助。希望这封邮件也能对您有所帮助，否则请告知我。

祝好，
Russ

---

注意：目前 godoc.org 上已经有提示，建议使用 pkg.go.dev 了。

## 三、关于 golangclub.com

最后，go.dev 的中国本土化站点：https://golangclub.com 仍在完善中，期待您的贡献。项目地址：https://github.com/polaris1119/golangclub

![](https://s2.ax1x.com/2020/02/10/15aZUs.png)
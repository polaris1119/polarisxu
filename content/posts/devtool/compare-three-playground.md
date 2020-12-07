---
title: "对比三款 Go Playground：你喜欢哪款？"
date: 2020-08-19T18:12:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Golang
  - Playground
categories:
  - 开发工具
---

曾几何时，语言的在线运行（Playground）似乎成了标配。确实，Playground 能够让我们可以快速试验一些想法。Go 语言在发布之初就提供了一个，这就是 <https://play.golang.org>。然而，由于众所周知的原因，我们访问不了。为了方便国内广大 gopher，我搞了一个国内镜像：<https://play.studygolang.com>，尽情使用、分享吧。

## 官方的 Playground

不得不说，Go 官方的 Playground 真的比较原始。

![](imgs/playgolangorg.png)

提供的功能比较少，主要有：

- 格式化，但需要手动点击。在点击格式化时，如果勾选了 Imports，会自动对使用的标准库做导入；
- 分享。能够将你的代码分享给其他人，方便对方查看、运行；
- 代码片段。顶部下拉列表中提供了一些代码片段，点击可以直接切换编辑框内容；

总结下：官方的 Playground 主要提供了在线编辑、运行、分享 Go 代码的功能，其中分享对全球的 gopher 来说，可以更方便的进行代码交流，排查问题等，分享也是使用最多的。

然而官方的 Playground 缺点也很明显：

- 界面简单，略显丑陋；
- 不支持代码高亮；
- 不支持代码提示；
- 语法错误无法实时提示；
- 。。。

于是有了第三方的 Playground。

## goplay.space

第一个出场的是 <https://goplay.space>。这是 iafan 在 2017 年开发的，

> Go Play Space is an experimental alternative [Go Playground](https://play.golang.org/) frontend that is built in Go itself (using [GopherJS](https://github.com/gopherjs/gopherjs)), a Go→JavaScript transpiler, and [Vecty](https://github.com/gopherjs/vecty), a React-like frontend library for GopherJS).

![](imgs/goplayspace.gif)

可见，goplay.space 的代码运行依然使用官方的，只是替换了前端部分。看看它提供了哪些功能：

- 语法高亮显示，大括号和引号自动关闭，正确的撤消/重做，自动缩进；
- 智能文档查找：例如双击源代码中的包名或 Println 等函数名称，在右边将看到相关的文档；这个功能真的很实用；
- 实时的语法错误检查；
- 错误行高亮显示（语法错误和编译器返回的错误）；
- 能够突出显示代码行和代码块（类似在 Github 上，但更好！）—只需单击行号即可。使用 Shift 和 Ctrl 修改选择；
- 键盘快捷键（请参阅顶部按钮标题处）；
- 支持多个 UI 主题；
- 支持 [Fira Code](https://github.com/tonsky/FiraCode) 字体（系统中已安装的字体或 Webfont）；
- go import 始终在运行代码之前运行，因此您通常不必担心导入问题；

代码执行是官方的 Go Playground 的代理，因此它保证了程序将有相同的结果。同时共享的代码段也存储在 golang.org 服务器上。所以，分享的代码，可以直接在 goplay.space 展示。比如这个代码：<https://play.golang.org/p/aouL6zP4O35>，对应的 goplay.space 就是：<https://goplay.space/#aouL6zP4O35>。

个人认为 goplay.space 最大的特色是智能文档查找，可以在写代码时及时查看文档。要是加上自动完成功能就好了。

## goplay.tools

[x1unix](https://twitter.com/x1unix) 觉得以上两个 Playground 都不够好。就在前些天（2020-08-12），发布了一个 “Better Go Playground”，这就是 <https://goplay.tools/>。

几个月前，x1unix 决定尝试创建一个更好的 Go Play 版本，该版本将具有一些有价值的小功能，使原型制作足够舒适，例如基本代码自动完成（仅支持 stdlib），语法检查，代码段和示例。另外，随着 Go in WebAssembly 趋势开始增长，添加了 WebAssembly 支持。

此外，用户可以选择编辑器字体以及一些其他选项的小选项来自定义编辑器。

这个项目基于 React 和 Monaco editor 创建。

![](imgs/goplaytools.gif)

目前该 Playground 有如下特性：

- 代码完成：标准库
- 加载和保存文件
- 代码片段和教程，基于 [gobyexample.com](https://gobyexample.com/)
- WebAssembly 支持
- 暗黑模式
- 更多定制选项

和 goplay.space 一样，它也是官方 Playground 的代理，因此官方分享的，在这里也可以直接查看，方便国内用户。上面例子对应该 Playground 是：<https://goplay.tools/snippet/aouL6zP4O35>。

仔细研究会发现它还支持鼠标右键菜单，有类似 VSCode 的 Command Palette 功能，调出该面板的快捷键是 F1。

![](imgs/goplaytools.png)

代码完成功能可以显示对应的文档（针对标准库），如下：

![](imgs/goplaytools-doc.png)

可见这真的是一个更好的 Playground，一定程度上有点在线编辑器的感觉。该项目在 GitHub 的地址：<https://github.com/x1unix/go-playground>。

## 后记

除了以上三款，其实还有一些其他的，比较小众，因此不做对比。最后，推荐大家以后可以使用 <https://goplay.tools/>，有兴趣的也可以为它贡献代码。


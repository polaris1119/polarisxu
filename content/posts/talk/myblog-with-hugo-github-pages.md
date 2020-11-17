---
title: "Hugo + GitHub Pages 搭建自己的网站"
date: 2020-10-29T21:40:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Hugo
  - GitHub
draft: true
---

大家好，我是站长 polarisxu。

很早之前，我使用 WordPress 搭建了个人博客：<http://blog.studygolang.com>，毕竟那时候 WordPress 是首选。现如今，大家似乎更喜欢静态博客，各种语言的静态博客生成器轮子不断，比如 Go 语言的 Hugo 就是一个静态博客生成器。我个人认为，静态博客生成器流行的一个很大原因，是 Markdown 的流行，开发人员习惯了使用 Markdown 进行写作。

对于我，有另外一个痛点。最近在公众号写了一些文章，希望同步到博客，只是文字还好处理些，如果涉及到图片，微信公众号上传了一次，博客还得再来一次，挺费劲的。同时，为了保留最原始的文字，原始博文放在 GitHub 是一个不错的选择（用 Git 保留你的修改，不要太棒好嘛！）。

既然博文都保存在了 GitHub 上，怎么方便快速的基于 GitHub 来搭建自己的博客呢？（有些人直接就让在 GitHub 阅读，虽然可以，但体验还是不太好，而且看起来没有那么高大上，是不是？）

我想过使用 GitBook 来搭建，安装时，发现官方已经不维护 gitbook-cli 了，而且每次新增加文章，都得维护目录等，也是挺费劲的。于是放弃了这种方式。

这时我想到了通过静态博客生成器来搞。最喜欢 Go，自然 Hugo 成为第一选择。

废话不多少，记录下我搭建的过程。

## 01 安装 Hugo

你可以通过 <https://github.com/gohugoio/hugo/releases> 下载响应的安装包，我喜欢源码安装。

```bash
$ go get -v github.com/gohugoio/hugo
```

如果你也想通过源码安装，请自行准备好 Go 环境。

查看版本同时验证是否安装成功：

```bash
$ hugo version
Hugo Static Site Generator v0.76.5 darwin/amd64 BuildDate: unknown
```

## 02 使用 Hugo


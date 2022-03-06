---
title: "新开一个 Go 系列：从零构建一个 WEB API"
date: 2022-01-30T22:30:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - Go
  - API
---

大家好，我是 polarisxu。

在本书的第一部分中，我们将建立一个项目目录，并为构建Greenlight API奠定基础。我们将：
为项目创建一个框架目录结构，并在高层解释如何组织我们的Go代码和其他资产。
建立HTTP服务器以侦听传入的HTTP请求。
引入一种合理的模式来管理配置设置（通过命令行标志），并使用依赖项注入使依赖项对我们的处理程序可用。使用httprouter包帮助实现API端点的标准RESTful结构。
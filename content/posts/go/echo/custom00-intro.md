---
title: "Echo 系列教程——定制篇0：让 Echo 更强大、更好用"
date: 2020-02-21T19:24:51+08:00
toc: true
isCJKLanguage: true
tags: 
  - echo
  - web框架
  - 定制
categories:
  - Echo系列
---

一个强大的框架，一定是可以定制的，或者说可以扩展，能够根据用户自己的需求进行改变、增强，甚至某些功能的替换。作为一个强大的框架，Echo 必然也是可以定制、可以扩展的。本篇起，我们一起探讨如何对 Echo 框架进行定制或扩展，打造成符合你个性需求的框架。

定制化主要包含如下一些方面：

- 自定义 Binder，用来处理 Request 数据绑定
- 自定义 Validator，用来处理输入验证
- 自定义 Logger，用你喜欢的日志库
- 自定义 Renderer，增强或替换模板引擎
- 自定义 HTTP Error Handler，让 HTTP 错误处理更友好
- 自定义 Server 相关，替换或扩展默认的 Server

关于扩展 Echo，主要通过中间件来实现，而这部分内容，我们已经在[《基础篇：通过一个例子串联各特性》](http://blog.studygolang.com/2019/12/echo-login-example/)中讲解了，具体常见中间件的使用，会在实战篇讲解。

除此之外，Echo#Debug 可以决定是否进入调试模式，在开发阶段，建议设置为 true，生产环境改为 false。

在开篇我们看到，在启动 Echo 项目时，默认会显示一个 Startup Banner，我们可以通过 Echo#HideBanner 控制它不显示。


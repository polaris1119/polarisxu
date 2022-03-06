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

虽然 Go 语言最初的目的不是用于开发 Web 的，但毫无疑问，Go 在 Web API 方面大放异彩，相关的开源框架也很多。

这个系列教程，将从头开始，一步步构建一个 JSON API，用于管理图书信息，我将这个应用叫做 GopherBook。

在这个系列中，我们的 API 将尽可能严格按照 RESTFul 标准实现。完成该项目后，GopherBook API 列表如下：

| 方法   | URL 模式                 | 功能                              |
| ------ | ------------------------ | --------------------------------- |
| GET    | /v1/healthcheck          | 显示应用健康状态和版本信息        |
| GET    | /v1/books                | 显示所有图书的详细信息            |
| POST   | /v1/book                 | 创建一本新图书                    |
| GET    | /v1/book/:id             | 显示一本特定图书的详细信息        |
| PATCH  | /v1/book/:id             | 更新一本特定图书的详细信息        |
| DELETE | /v1/book/:id             | 删除一本特定图书                  |
| POST   | /v1/user                 | 注册一个新用户                    |
| PUT    | /v1/user/activated       | 激活一个用户                      |
| PUT    | /v1/user/password        | 更新一个用户的密码                |
| POST   | /v1/token/authentication | 生成一个新的 authentication token |
| POST   | /v1/token/password-reset | 生成一个密码重置 token            |
| GET    | /debug/vars              | 显示应用指标                      |

以上这些 API 并不复杂，无非是 CURD，但通过实现以上 API，你能够更好地掌握 Go 语言的相关 API 和技巧，这也是这个系列的初衷，一起通过实践掌握 Go 语言。
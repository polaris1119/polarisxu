---
title: "RPC 那些事 01：快速了解 RPC"
date: 2021-05-06T22:30:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - Go
  - RPC
---

大家好，我是站长 polarisxu。

今天起开启一个新的系列：RPC 那些事。为什么讲这个？这几年微服务很火，而 RPC 是微服务很重要的一个基础部分。通过这个系列，希望大家能够较全面的掌握 RPC。

在这个系列中，主要基于 Go 语言讲解，同时 RPC 框架选择 gRPC。

## 01 RPC 简介

关于 RPC 这个词，大家应该不陌生。维基百科是这么定义的：

> 在分布式计算，远程过程调用（英语：Remote Procedure Call，缩写为 RPC）是一个计算机通信协议。该协议允许运行于一台计算机的程序调用另一个地址空间（通常为一个开放网络的一台计算机）的子程序，而程序员就像调用本地程序一样，无需额外地为这个交互作用编程（无需关注细节）。RPC 是一种服务器-客户端（Client/Server）模式，经典实现是一个通过发送请求-接受回应进行信息交互的系统。

根据这个定义，RPC 其实是一种进程间通信的模式。RPC 的概念很早就出现了，最早可以追溯到 1976 年。RPC 首次在 UNIX 平台上普及的执行工具程序是 SUN 公司的 RPC（现在叫 ONC RPC）。而在 1984 年，Bruce Jay Nelson 发表了奠定基础性的论文 [Implementing Remote Procedure Call](http://www.cs.cmu.edu/~dga/15-712/F07/papers/birrell842.pdf)，定义了机器之间互通这种远程调用的标准。

> 注意：远程过程调用，并不一定要求在不同机器，只要不是同一个进程即可

RPC 总是由客户端对服务器发出一个执行若干过程的请求，并用客户端提供的参数，执行结果将返回给客户端。由于存在各式各样的变体和细节差异，对应地派生了各式远程过程调用协议，而且它们通常不互相兼容。

一般 RPC 流程如下：

1. 客户端调用客户端 stub（client stub）。这个调用是在本地，并将调用参数 push 到栈（stack）中。
2. 客户端 stub（client stub）将这些参数包装，并通过系统调用发送到服务端机器。打包的过程叫 marshalling。（常见方式：XML、JSON、二进制编码）
3. 客户端本地操作系统发送信息至服务器。（可通过自定义 TCP 协议或 HTTP 传输）
4. 服务器系统将信息传送至服务端 stub（server stub）。
5. 服务端 stub（server stub）解析信息。该过程叫 unmarshalling。
6. 服务端 stub（server stub）调用程序，并通过类似的方式返回给客户端。

来自网上的一张图：

![RPC](https://mediumcn.com/assets/images/rpc/4.jpg)

RPC 通常分为三层，RPC Runtime 负责最底层的网络传输，Stub 处理客户端和服务端约定好的语法、语义的封装和解封装，这些调用远程的细节都被这两层搞定了，用户端和服务端这层就只要负责处理业务逻辑，调用本地 Stub 就相当于调用远程。（从图中可以看到，客户端最终的 Send 会等待，最终这个调用执行的是服务端最上层，然后将结果返回，直到客户端的 Receive，然后返回给上层）

## 02 RPC 框架

有了 RPC 协议，为了允许不同的客户端均能访问服务器，许多标准化的 RPC 系统应运而生了。其中大部分采用接口描述语言（Interface Description Language，IDL），方便跨平台的远程过程调用。

一般一个 RPC 框架一般包括：

- 协议约定：规定调用远程方法的语法，参数传递方式等。比如系列化协议。
- 传输协议：基于什么网络协议进行数据传输。

比如这几年很火的 gRPC 框架，它采用 Protocol Buffers 二进制协议，而传输协议基于 HTTP 2.0。通常，一个优秀的 RPC 框架应该支持多语言。

一般地，根据「协议约定」的不同有以下一些常见的扩展 RPC 协议：

- XML-RPC：使用 XML 进行编解码，并基于 HTTP 进行传输；
- JSON-RPC：使用 JSON 进行编解码；
- SOAP：是 XML-RPC 的继任者；

至于 RPC 框架，目前比较流行的有：

- Apache Thrift
- gRPC
- rpcx
- Dubbo
- 。。。

在本系列教程中，我们会学习 Go 语言标准库中的 net/rpc、net/rpc/jsonrpc，然后会重点学习 gRPC。

## 03 小结

从语义上，RESTful 和 RPC 是不一样的。但如果我的 RESTful 为客户端提供好 SDK，客户端通过 SDK 调用 RESTful 接口，对客户端来说，这跟 RPC 就一样了。这种情况，我认为 RESTful 是一种特殊的 RPC。你觉得呢？

## 参考文档

- https://en.wikipedia.org/wiki/Remote_procedure_call
- https://zhuanlan.zhihu.com/p/60352360


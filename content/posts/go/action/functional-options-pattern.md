---
title: "Go编程模式：详解函数式选项模式"
date: 2021-11-28T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 选项模式
---

大家好，我是 polarisxu。

Go 不是完全面向对象语言，有一些面向对象模式不太适合它。但经过这些年的发展，Go 有自己的一些模式。今天介绍一个常见的模式：函数式选项模式（Functional Options Pattern）。

## 01 什么是函数式选项模式

Go 语言没有构造函数，一般通过定义 New 函数来充当构造函数。然而，如果结构有较多字段，要初始化这些字段，有很多种方式，但有一种方式认为是最好的，这就是函数式选项模式（Functional Options Pattern）。

函数式选项模式是一种在 Go 中构造结构体的模式，它通过设计一组非常有表现力和灵活的 API 来帮助配置和初始化结构体。

在 Uber 的 [Go 语言规范](https://github.com/uber-go/guide/blob/master/style.md#functional-options)中提到了该模式：

> Functional options 是一种模式，在该模式中，你可以声明一个不透明的 `Option` 类型，该类型在某些内部结构中记录信息。你接受这些可变数量的选项，并根据内部结构上的选项记录的完整信息进行操作。
>
> 将此模式用于构造函数和其他公共 API 中的可选参数，你预计这些参数需要扩展，尤其是在这些函数上已经有三个或更多参数的情况下。

## 02 一个示例

为了更好的理解该模式，我们通过一个例子来讲解。

定义一个 Server 结构体：

```go
package main

type Server struct {
  host string
  port int
}

func New(host string, port int) *Server {
  return &Server{host, port}
}

func (s *Server) Start() error {
}
```

如何使用呢？

```go
package main

import (
  "log"
  "server"
)

func main() {
  svr := New("localhost", 1234)
  if err := svr.Start(); err != nil {
    log.Fatal(err)
  }
}
```

但如果要扩展 Server 的配置选项，如何做？通常有三种做法：

- 为每个不同的配置选项声明一个新的构造函数
- 定义一个新的 Config 结构体来保存配置信息
- 使用 Functional Option Pattern

### 做法 1：为每个不同的配置选项声明一个新的构造函数

这种做法是为不同选项定义专有的构造函数。假如上面的 Server 增加了两个字段：

```go
type Server struct {
  host string
  port int
  timeout time.Duration
  maxConn int
}
```

一般来说，host 和 port 是必须的字段，而 timeout 和 maxConn 是可选的，所以，可以保留原来的构造函数，而这两个字段给默认值：

```go
func New(host string, port int) *Server {
  return &Server{host, port, time.Minute, 100}
}
```

然后针对 timeout 和 maxConn 额外提供两个构造函数：

```go
func NewWithTimeout(host string, port int, timeout time.Duration) *Server {
  return &Server{host, port, timeout}
}

func NewWithTimeoutAndMaxConn(host string, port int, timeout time.Duration, maxConn int) *Server {
  return &Server{host, port, timeout, maxConn}
}
```

这种方式配置较少且不太会变化的情况，否则每次你需要为新配置创建新的构造函数。在 Go 语言标准库中，有这种方式的应用。比如 net 包中的 Dial 和 DialTimeout：

```go
func Dial(network, address string) (Conn, error)
func DialTimeout(network, address string, timeout time.Duration) (Conn, error)
```

### 做法 2：使用专门的配置结构体

这种方式也是很常见的，特别是当配置选项很多时。通常可以创建一个 Config 结构体，其中包含 Server 的所有配置选项。这种做法，即使将来增加更多配置选项，也可以轻松的完成扩展，不会破坏 Server 的 API。

```go
type Server struct {
  cfg Config
}

type Config struct {
  Host string
  Port int
  Timeout time.Duration
  MaxConn int
}

func New(cfg Config) *Server {
  return &Server{cfg}
}
```

在使用时，需要先构造 Config 实例，对这个实例，又回到了前面 Server 的问题上，因为增加或删除选项，需要对 Config 有较大的修改。如果将 Config 中的字段改为私有，可能需要定义 Config 的构造函数。。。

### 做法 3：使用 Functional Option Pattern

一个更好的解决方案是使用 Functional Option Pattern。

在这个模式中，我们定义一个 Option 函数类型：

```go
type Option func(*Server)
```

Option 类型是一个函数类型，它接收一个参数：`*Server`。然后，Server 的构造函数接收一个 Option 类型的不定参数：

```go
func New(options ...Option) *Server {
  svr := &Server{}
  for _, f := range options {
    f(svr)
  }
  return svr
}
```

那选项如何起作用？需要定义一系列相关返回 Option 的函数：

```go
func WithHost(host string) Option {
  return func(s *Server) {
    s.host = host
  }
}

func WithPort(port int) Option {
  return func(s *Server) {
    s.port = port
  }
}

func WithTimeout(timeout time.Duration) Option {
  return func(s *Server) {
    s.timeout = timeout
  }
}

func WithMaxConn(maxConn int) Option {
  return func(s *Server) {
    s.maxConn = maxConn
  }
}
```

针对这种模式，客户端类似这么使用：

```go
package main

import (
  "log"
  
  "server"
)

func main() {
  svr := New(
    WithHost("localhost"),
    WithPort(8080),
    WithTimeout(time.Minute),
    WithMaxConn(120),
  )
  if err := svr.Start(); err != nil {
    log.Fatal(err)
  }
}
```

将来增加选项，只需要增加对应的 WithXXX 函数即可。

这种模式，在第三方库中使用挺多，比如 github.com/gocolly/colly：

```go
type Collector {
  // 省略...
}
func NewCollector(options ...CollectorOption) *Collector

// 定义了一系列 CollectorOpiton
type CollectorOption{
  // 省略...
}
func AllowURLRevisit() CollectorOption
func AllowedDomains(domains ...string) CollectorOption
...
```

不过 Uber 的 Go 语言编程规范中提到该模式时，建议定义一个 Option 接口，而不是 Option 函数类型。该 Option 接口有一个未导出的方法，然后通过一个未导出的 `options` 结构来记录各选项。

Uber 的这个例子能看懂吗？

```go
type options struct {
  cache  bool
  logger *zap.Logger
}

type Option interface {
  apply(*options)
}

type cacheOption bool

func (c cacheOption) apply(opts *options) {
  opts.cache = bool(c)
}

func WithCache(c bool) Option {
  return cacheOption(c)
}

type loggerOption struct {
  Log *zap.Logger
}

func (l loggerOption) apply(opts *options) {
  opts.logger = l.Log
}

func WithLogger(log *zap.Logger) Option {
  return loggerOption{Log: log}
}

// Open creates a connection.
func Open(
  addr string,
  opts ...Option,
) (*Connection, error) {
  options := options{
    cache:  defaultCache,
    logger: zap.NewNop(),
  }

  for _, o := range opts {
    o.apply(&options)
  }

  // ...
}
```

## 03 总结

在实际项目中，当你要处理的选项比较多，或者处理不同来源的选项（来自文件、来自环境变量等）时，可以考虑试试函数式选项模式。

注意，在实际工作中，我们不应该教条的应用上面的模式，就像 Uber 中的例子，Open 函数并非只接受一个 Option 不定参数，因为 addr 参数是必须的。因此，函数式选项模式更多应该应用在那些配置较多，且有可选参数的情况。

## 参考文献

- <https://golang.cafe/blog/golang-functional-options-pattern.html>
- <https://github.com/uber-go/guide/blob/master/style.md#functional-options>
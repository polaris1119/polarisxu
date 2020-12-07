---
title: "Echo 系列教程——基础篇2：Echo 核心亮点介绍"
date: 2019-10-28T11:15:51+08:00
toc: true
isCJKLanguage: true
tags: 
  - echo
  - web框架
  - 亮点
categories:
  - Echo系列
---

在 Echo 的官网的首页，列出了 9 个核心功能或亮点。我这里将它说成是亮点（也许并不一定都比其他框架更好）。

## 一、优化的路由

**高度优化的 HTTP 路由，动态内存分配为零，可对路由进行优先级排序。**

这一点从上一篇：[搭建 Echo 开发环境](基础篇：搭建 Echo 开发环境.md) 可以看到。

Echo 路由基于 [radix tree](http://en.wikipedia.org/wiki/Radix_tree) ，查询速度非常快。路由使用 [sync pool](https://docs.studygolang.com/pkg/sync/#Pool) 来重用内存，实现无 GC 开销下的零动态内存分配。

### 路由的注册和使用方式

各大框架路由的注册和使用方式都类似，通过 HTTP 方法（GET、POST、PUT、DELETE 等），将 url 路径和一个处理程序绑定在一起，唯一不太一样的一般是处理程序的函数签名不一样（主要参数类型不一样）。例如，下面的代码则展示了一个注册路由的例子：它包括 `GET` 的访问方式， `/hello` 的访问路径，以及发送 `Hello World` HTTP 响应的处理程序。

```go
// 业务处理
func hello(c echo.Context) error {
  	return c.String(http.StatusOK, "Hello, World!")
}

// 路由
e.GET("/hello", hello)
```

更多路由的特性，参考文档：<https://echo.labstack.com/guide/routing/>（英文）、 <https://www.bookstack.cn/read/echo-v3-zh/guide-routing.md> （中文）。（上篇贴的中文文档打不开了。注意，中文文档基于 V3，而不是 V4）

## 二、Scalable

Echo 方便构建健壮的 RESTful API，轻松将其组织起来。

根据上一节路由，我们可以轻松构建出 RESTful API，比如：

```go
e.POST("/user", createUser)
e.GET("/user/1", findUser)
e.PUT("/user/1", updateUser)
e.DELETE("/user/1", deleteUser)
```

可以轻松对应上 RESTful API 的标准。

## 三、自动 TLS

Echo 能够通过 “Let's Encrypt” 自动安装 TLS 证书。`Echo#StartAutoTLS` 接受一个接听 443 端口的网络地址。类似 `:443` 这样。

```go
e.StartAutoTLS(":443")
```

可以通过 `e.AutoTLSManager` 做一些控制，比如缓存等。

## 四、HTTP/2

Echo 自动支持 HTTP/2。HTTP/2 (原本的名字是 HTTP/2.0) 是万维网使用的 HTTP 网络协议的第二个主要版本。HTTP/2 提供了更快的速度和更好的用户体验。

### 特性

- 使用二进制格式传输数据，而不是文本。使得在解析和优化扩展上更为方便。
- 多路复用，所有的请求都是通过一个 TCP 连接并发完成。
- 对消息头采用 HPACK 进行压缩传输，能够节省消息头占用的网络的流量。
- Server Push：服务端能够更快的把资源推送给客户端。

## 五、中间件

这是让 Echo 可扩展、功能强大、好用的关键组件。

中间件是一个函数，嵌入在 HTTP 的请求和响应之间。它可以获得 `Echo#Context` 对象用来进行一些特殊的操作， 比如记录每个请求或者统计请求数。

### 不同级别的中间件

#### 1、根级别中间件（router 之前）

`Echo#Pre()` 用于注册一个在路由执行之前运行的中间件，可以用来修改请求的一些属性。比如在请求路径结尾添加或者删除一个 `/` 来使之能与路由匹配。

下面的这几个内建中间件应该被注册在这一级别：

- AddTrailingSlash
- RemoveTrailingSlash
- MethodOverride

*注意*: 由于在这个级别路由还没有执行，所以这个级别的中间件不能调用任何 `echo.Context` 的 API。

#### 2、根级别中间件（router 之后）

大部分时间你将用到 `Echo#Use()` 在这个级别注册中间件。 这个级别的中间件运行在路由处理完请求之后，可以调用所有的 `echo.Context` API。

下面的这几个内建中间件应该被注册在这一级别：

- BodyLimit
- Logger
- Gzip
- Recover
- BasicAuth
- JWTAuth
- Secure
- CORS
- Static

#### 3、组级别中间件

当在路由中创建一个组的时候，可以为这个组注册一个中间件。例如，给 admin 这个组注册一个 BasicAuth 中间件。

```go
e := echo.New()
admin := e.Group("/admin", middleware.BasicAuth())
```

也可以在创建组之后用 `admin.Use()`注册该中间件。

#### 4、路由级别中间件

当你创建了一个新的路由，可以选择性的给这个路由注册一个中间件。

```go
e := echo.New()
e.GET("/", <Handler>, <Middleware...>)
```

## 六、数据绑定

HTTP 请求有效负载的数据绑定，包括 JSON，XML 或表单数据。

可以使用 `Context#Bind(i interface{})` 将请求内容体绑定至 go 的结构体。默认绑定器支持基于 `Content-Type`  请求头包含 application/json，application/xml 和 application/x-www-form-urlencoded 的数据。

下面是绑定请求数据到 `User` 结构体的例子。

```go
// User
User struct {
  Name  string `json:"name" form:"name" query:"name"`
  Email string `json:"email" form:"email" query:"email"`
}

// Handler
func(c echo.Context) (err error) {
  u := new(User)
  if err = c.Bind(u); err != nil {
    return
  }
  return c.JSON(http.StatusOK, u)
}
```

以上代码支持如下请求数据的绑定：

1、JSON 数据

```
curl \
  -X POST \
  http://localhost:1323/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Joe","email":"joe@labstack"}'
```

2、Form 表单数据

```
curl \
  -X POST \
  http://localhost:1323/users \
  -d 'name=Joe' \
  -d 'email=joe@labstack.com'
```

3、查询参数 (Query Parameters)

```
curl \
  -X GET \
  http://localhost:1323/users\?name\=Joe\&email\=joe@labstack.com
```

## 七、数据呈现

有发送各种 HTTP 响应的 API，包括 JSON，XML，HTML，文件，附件，内联，流或 Blob。

## 八、模板

支持使用任何模板引擎进行模板渲染。

使用 `Context#Render(code int, name string, data interface{}) error` 命令渲染带有数据的模板，并发送带有状态代码的 `text/html` 响应。通过 `Echo.Renderer` 的设置我们可以使用任何模板引擎。

## 九、可扩展（Extensible）

拥有可定制的集中 HTTP 错误处理和易于扩展的 API 等。

## 总结

以上是 Echo 首页给出的 9 大核心亮点，后续教程会给出详细的讲解或实际例子。

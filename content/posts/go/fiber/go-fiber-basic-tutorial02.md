---
title: "Go Fiber 框架系列教程 02：详解相关 API 的使用"
date: 2021-09-21T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Fiber
---

大家好，我是 polarisxu。

该系列第一篇文章发出后，大家褒贬不一，很正常。选什么，不选什么，大家自己评估，没有什么是最好的。我这个系列，更多只是让大家对 Fiber 有些了解，说不定正好合你胃口呢？

前面对 Fiber 有了大概的印象。今天着重较深入探讨 Fiber 相关功能。

先从 `fiber.New` 函数配置开始。

## 01 配置

大部分 Go 框架，获得实例的函数是不支持配置的，比如 Gin、Echo 等。但 Fiber 框架的 New 函数支持传递配置：

```go
// New creates a new Fiber named instance.
//  app := fiber.New()
// You can pass optional configuration options by passing a Config struct:
//  app := fiber.New(fiber.Config{
//      Prefork: true,
//      ServerHeader: "Fiber",
//  })
func New(config ...Config) *App
```

一般情况，使用默认配置即可（即不手动传递配置），但有必要了解下，通过配置，我们能干些什么。

比如，我们希望响应头中，Server 用自定义的。

```go
config := fiber.Config{
  ServerHeader: "Go Fiber Framework",
}
app := fiber.New(config)
```

响应头类似这样：

```bash
Content-Length: 12
Content-Type: text/plain; charset=utf-8
Date: Mon, 20 Sep 2021 14:58:45 GMT
Server: Go Fiber Framework
```

实际上，在前文模板引擎使用的 Views 就是一个配置项。

目前配置 29 项之多，有不少是关于 HTTP 的配置。所有的配置和说明可以在文档找到：<https://docs.gofiber.io/api/fiber#config>。建议扫一遍，有一个印象，方便将来有需求时知道在这里找。

## 02 路由

标准库 net/http 的路由比较简单，这大概也是有各种路由库（框架）的原因之一。

最简单的路由莫过于直接匹配，如：

```go
// 请求匹配到 /about
app.Get("/about", func(c *fiber.Ctx) error {
  return c.SendString("about")
})
```

而**命名路由**（也叫参数路由）是一个强大框架必须的，即提供占位符。比如：

```go
app.Get("/hello/:username", func(c *fiber.Ctx) error {
  str := fmt.Sprintf("Hello, %s", c.Params("username"))
  return c.SendString(str)
})
```

这个路由就可以匹配任意的以 `/hello/` 开头的请求，比如：`/hello/polarisxu`，最后会输出：`Hello, polarixu`。

不过，如果请求的刚好是 `/hello/` 呢？Fiber 会返回 404，报路由找不到。如果你希望这时候把 username 当空处理，而不是返回 404，可以在 `:username` 后加一个 `?`：

```go
app.Get("/hello/:username?", func(c *fiber.Ctx) error {
  str := fmt.Sprintf("Hello, %s", c.Params("username"))
  return c.SendString(str)
})
```

此外，还有 `+` 和 `*` 进行通配，区别在于 `+` 要求至少要有一个，而 `*` 可以没有。通过 `c.Params("+")` 和 `c.Params("*")` 获得对于的值。

此外，Fiber 还支持有 `-` 和 `.` 的复杂路由，例如：

```go
// http://localhost:3000/flights/LAX-SFO
app.Get("/flights/:from-:to", func(c *fiber.Ctx) error {
    fmt.Fprintf(c, "%s-%s\n", c.Params("from"), c.Params("to"))
    return nil // LAX-SFO
})
```

> 注意，如果路由中需要包含特殊字符，比如 `:`，需要进行转义。

因为 Fiber 的目标之一是成为 Go 最快、最清晰的 Web 框架，因此对于更复杂的路由，比如正则表达式，Fiber 不会支持。

Fiber 还提供了方法，返回所有注册的路由信息：

```go
var handler = func(c *fiber.Ctx) error { return nil }

func main() {
    app := fiber.New()

    app.Get("/john/:age", handler)
    app.Post("/register", handler)

    data, _ := json.MarshalIndent(app.Stack(), "", "  ")
    fmt.Println(string(data))

    app.Listen(":3000")
}
```

返回结果如下：

```json
[
  [
    {
      "method": "GET",
      "path": "/john/:age",
      "params": [
        "age"
      ]
    }
  ],
  [
    {
      "method": "HEAD",
      "path": "/john/:age",
      "params": [
        "age"
      ]
    }
  ],
  [
    {
      "method": "POST",
      "path": "/register",
      "params": null
    }
  ]
]
```

可以辅助排查路由问题。

## 03 Static

上文介绍了服务静态资源的 Static 方法，这里详细解释下。

Static 方法可以多个。默认情况下，如果目录下有 `index.html` 文件，对目录的访问会以该文件作为响应。

```go
app.Static("/static/", "./public")
```

以上代码用于项目根目录下 public 目录的文件和文件夹。

此外，Static 方法有第三个可选参数，以便对 Static 行为进行微调，这可以通过 fiber.Static 结构体控制。

```go
// Static defines configuration options when defining static assets.
type Static struct {
    // When set to true, the server tries minimizing CPU usage by caching compressed files.
    // This works differently than the github.com/gofiber/compression middleware.
    // Optional. Default value false
    Compress bool `json:"compress"`

    // When set to true, enables byte range requests.
    // Optional. Default value false
    ByteRange bool `json:"byte_range"`

    // When set to true, enables directory browsing.
    // Optional. Default value false.
    Browse bool `json:"browse"`

    // The name of the index file for serving a directory.
    // Optional. Default value "index.html".
    Index string `json:"index"`

    // Expiration duration for inactive file handlers.
    // Use a negative time.Duration to disable it.
    //
    // Optional. Default value 10 * time.Second.
    CacheDuration time.Duration `json:"cache_duration"`

    // The value for the Cache-Control HTTP-header
    // that is set on the file response. MaxAge is defined in seconds.
    //
    // Optional. Default value 0.
    MaxAge int `json:"max_age"`

    // Next defines a function to skip this middleware when returned true.
    //
    // Optional. Default: nil
    Next func(c *Ctx) bool
}
```

上文说，默认情况下，对目录访问的索引文件是 index.html，通过 Index 可以改变该行为。如果想要启用目录浏览功能，可以设置 Browse 为 true。

## 04 路由处理器

在前面提到，Fiber 有对应的方法支持所有 HTTP Method。除此之外，还有两个特殊的方法：Add 和 All。

Add 方法是所有 HTTP Method 对应方法的底层实现，比如 Get 方法：

```go
func (app *App) Get(path string, handlers ...Handler) Router {
	return app.Add(MethodHead, path, handlers...).Add(MethodGet, path, handlers...)
}
```

它底层调用了 Add 方法，做了两次绑定，分别是 HEAD 和 GET，也就是说，对于 Get 方法，支持 HTTP GET 和 HEAD。

> 我之前写过一篇文章：[网友很强大，发现了Go并发下载的Bug](https://mp.weixin.qq.com/s/g_v9ZOotpMfvgQtM5GqB-g)。Echo 框架，对于 Get 方法，只是 HTTP GET，不支持 HEAD 请求。目前看，Fiber 的做法更合理。如果你真的只需要 GET，可以通过 Add 方法实现。

而 All 方法表示支持任意 HTTP Method。

## 05 Mount 和 Group

Mount 方法可以将一个 Fiber 实例挂载到另一个实例。

```go
func main() {
    micro := fiber.New()
    micro.Get("/doe", func(c *fiber.Ctx) error {
        return c.SendStatus(fiber.StatusOK)
    })

    app := fiber.New()
    app.Mount("/john", micro) // GET /john/doe -> 200 OK

    log.Fatal(app.Listen(":3000"))
}
```

Group 是路由分组功能，框架基本会支持该特性，对于 API 版本控制很有用。

```go
func main() {
  app := fiber.New()

  api := app.Group("/api", handler)  // /api

  v1 := api.Group("/v1", handler)   // /api/v1
  v1.Get("/list", handler)          // /api/v1/list
  v1.Get("/user", handler)          // /api/v1/user

  v2 := api.Group("/v2", handler)   // /api/v2
  v2.Get("/list", handler)          // /api/v2/list
  v2.Get("/user", handler)          // /api/v2/user

  log.Fatal(app.Listen(":3000"))
}
```

## 06 fiber.Ctx 的方法

此外，就是 handler 中的参数 fiber.Ctx，这是一个结构体，包含了众多的方法（不少都是方便开发的方法），在使用时查阅 API 文档，或访问 <https://docs.gofiber.io/api/ctx> 浏览。

这里介绍几个其他框架可能没有的方法。

```go
// BodyParser binds the request body to a struct.
// It supports decoding the following content types based on the Content-Type header:
// application/json, application/xml, application/x-www-form-urlencoded, multipart/form-data
// If none of the content types above are matched, it will return a ErrUnprocessableEntity error
func (c *Ctx) BodyParser(out interface{}) error
```

该方法将请求绑定到结构体。（响应的也有 QueryParser 方法，主要处理查询字符串到结构体的绑定）

看一个例子：

```go
type Person struct {
		Name string `json:"name" xml:"name" form:"name"`
		Pass string `json:"pass" xml:"pass" form:"pass"`
}

app.Post("/login", func(ctx *fiber.Ctx) error {
		p := new(Person)

		if err := ctx.BodyParser(p); err != nil {
			return err
		}

		log.Println(p.Name) // john
		log.Println(p.Pass) // doe

		return ctx.SendString("Success")
})

// 运行下面的命令进行测试

// curl -X POST -H "Content-Type: application/json" --data "{\"name\":\"john\",\"pass\":\"doe\"}" localhost:3000/login

// curl -X POST -H "Content-Type: application/xml" --data "<login><name>john</name><pass>doe</pass></login>" localhost:3000/login

// curl -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "name=john&pass=doe" localhost:3000/login

// curl -X POST -F name=john -F pass=doe http://localhost:3000/login

// curl -X POST "http://localhost:3000/login?name=john&pass=doe"
```

关于获取参数，包括路由参数、查询参数、表单参数，Fiber 都非常友好的提供了可选的默认值形式，也就是说，当没有传递对应值时，我们可以给一个默认值，比如：

```go
// 10 是可选的。以下代码表示，当 page 参数没有传递，page=10
page := ctx.Query("page", 10)
```

> 默认值模式（可选参数）在 Fiber 中有大量使用，这能极大为使用者带来方便。

此外，路由参数还有 `ParamsInt` 方法，用来获取 int 类型的路由参数。

## 07 小结

通过本文对 Fiber 内置功能的介绍，我的感受是，Fiber 为开发者提供了很多便利。如果你没有用过其他框架，可能没有那么大的感受。后续文章考虑出一个不同框架相关写法的对比。

下篇文章介绍 Fiber 的中间件~

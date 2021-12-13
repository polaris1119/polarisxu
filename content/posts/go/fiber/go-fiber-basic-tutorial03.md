---
title: "Go Fiber 框架系列教程 03：中间件"
date: 2021-10-05T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Fiber
---

大家好，我是 polarisxu。

Middleware（中间件） 是一个 Web 框架重要的组成部分，通过这种模式，可以方便的扩展框架的功能。目前 Go Web 框架都提供了 Middleware 的功能，也有众多可用的 Middleware。

Fiber 也是如此，官方提供了众多的 Middleware，方便用户直接使用。本文先看看 Fiber 中 Middleware 的定义，然后介绍 Fiber 中的几个 Middleware，最后自己实现一个 Middleware。

> Fiber 文档中关于 Middleware 的说明：中间件是在 HTTP 请求周期中链接的函数，它可以访问用于执行特定操作（例如，记录每个请求或启用 CORS）的上下文。

## 01 Middleware 长什么样

设计用于更改请求或响应的函数称为中间件函数。Next 是 Fiber 路由器函数，当它被调用时，执行与当前路由匹配的下一个函数。

可见，中间件其实和 Handler 是一样的，只是用途有区别。或者说至少签名是一样的，这样才能更好的形成一个链。

因此，Fiber 中的中间件签名如下：

```go
func(ctx *fiber.Ctx) error
```

Fiber 没有专门定义中间件类型。

此外，从 fiber.App.Use 方法也可以看到，中间件和普通的 Handler 并无本质不同。

```go
// Use registers a middleware route that will match requests
// with the provided prefix (which is optional and defaults to "/").
//
//  app.Use(func(c *fiber.Ctx) error {
//       return c.Next()
//  })
//  app.Use("/api", func(c *fiber.Ctx) error {
//       return c.Next()
//  })
//  app.Use("/api", handler, func(c *fiber.Ctx) error {
//       return c.Next()
//  })
//
// This method will match all HTTP verbs: GET, POST, PUT, HEAD etc...
func (app *App) Use(args ...interface{}) Router {
	var prefix string
	var handlers []Handler

	for i := 0; i < len(args); i++ {
		switch arg := args[i].(type) {
		case string:
			prefix = arg
		case Handler:
			handlers = append(handlers, arg)
		default:
			panic(fmt.Sprintf("use: invalid handler %v\n", reflect.TypeOf(arg)))
		}
	}
	app.register(methodUse, prefix, handlers...)
	return app
}
```

而 fiber.Handler 类型只是 `func(*fiber.Ctx) error` 的别名：

```go
// Handler defines a function to serve HTTP requests.
type Handler = func(*Ctx) error
```

这点上，Gin 框架和 Fiber 是类似的。不过，有一些框架，比如 Echo，专门定义了中间件类型。但不管怎么样，中间件的本质和普通路由 Handler 是类似的。

## 02 Fiber 内置的中间件

所有内置的中间件可以在 fiber 项目的 middleware 子包找到，这些中间件对应的文档在这里：<https://docs.gofiber.io/api/middleware>。

以 Recover 中间件为例，看看官方中间件的实现方法，我们自己的中间件可以参照实现。

1）签名

```go
func New(config ...Config) fiber.Handler
```

上文说了，中间件就是一个 Handler，因此这里 New 函数返回 `fiber.Handler`，这就中间件。

至于 New 函数的参数不做任何要求，只需要最终返回 `fiber.Handler` 即可。

2）配置

一个好的中间件，或通用的中间件，一般都会有配置，让中间件更灵活、更强大。看看 Recover 的配置定义：

```go
// Config defines the config for middleware.
type Config struct {
    // Next defines a function to skip this middleware when returned true.
    //
    // Optional. Default: nil
    Next func(c *fiber.Ctx) bool

    // EnableStackTrace enables handling stack trace
    //
    // Optional. Default: false
    EnableStackTrace bool

    // StackTraceHandler defines a function to handle stack trace
    //
    // Optional. Default: defaultStackTraceHandler
    StackTraceHandler func(e interface{})
}
```

具体配置是什么样的，需要根据中间件的功能来定义。

不过，配置中 Next 这个行为，很多中间件都可以有。

3）默认配置

一般的，会提供一个默认配置，方便使用。而且，大部分时候，使用默认配置即可。Recover 的默认配置如下：

```go
var ConfigDefault = Config{
    Next:              nil,
    EnableStackTrace:  false,
    StackTraceHandler: defaultStackTraceHandler,
}
```

如果这样调用 `recover.New()` ，会默认使用上面的默认配置。

最后看看 New 函数的代码：

```go
// New creates a new middleware handler
func New(config ...Config) fiber.Handler {
	// Set default config
	cfg := configDefault(config...)

	// Return new handler
	return func(c *fiber.Ctx) (err error) {
		// Don't execute middleware if Next returns true
		if cfg.Next != nil && cfg.Next(c) {
			return c.Next()
		}

		// Catch panics
		defer func() {
			if r := recover(); r != nil {
				if cfg.EnableStackTrace {
					cfg.StackTraceHandler(r)
				}

				var ok bool
				if err, ok = r.(error); !ok {
					// Set error that will call the global error handler
					err = fmt.Errorf("%v", r)
				}
			}
		}()

		// Return err if exist, else move to next handler
		return c.Next()
	}
}
```

以上就是一个 Fiber 标准中间件的写法。

具体使用时就是：`app.Use(recover.New())`。

当然，如果只是自己项目使用，可以不用写配置。

## 03 实现一个简单的中间件

通过 Recover 学习到了中间件的标准写法，如果中间件只在自己项目使用，不需要灵活性，完全可以采用简单的写法。

```go
func Security(ctx *fiber.Ctx) error {
  ctx.Set("X-XSS-Protection", "1; mode=block")
  ctx.Set("X-Content-Type-Options", "nosniff")
  ctx.Set("X-Download-Options", "noopen")
  ctx.Set("Strict-Transport-Security", "max-age=5184000")
  ctx.Set("X-Frame-Options", "SAMEORIGIN")
  ctx.Set("X-DNS-Prefetch-Control", "off")

  // 执行下一个 Handler
  return ctx.Next()
}
```

这其实也是一个 Handler，对吧。无非最后调用的是 ctx.Next，而不是 ctx.JSON 之类的。

使用时这样：

```go
app := fiber.New()
app.Use(Security)
```

只要理解中间件的机制，不需要拘泥于具体形式，可以灵活变换中间件的写法。

## 04 总结

本文讲解了什么是中间件，Fiber 中间件长什么样以及对内置中间件 Recover 的学习，最后自己实现一个简单的中间件。掌握了 Fiber 的中间件，相信对其他 Go Web 框架的中间件的学习也就不难了，因为都差不多。


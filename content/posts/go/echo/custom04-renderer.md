---
title: "Echo 系列教程——定制篇4：自定义 Renderer，增强或替换模板引擎"
date: 2020-03-16T10:17:51+08:00
toc: true
isCJKLanguage: true
tags: 
  - echo
  - web框架
  - 模板引擎
---

Render，顾名思义，要进行页面渲染。Go 语言不但自带有强大的 http 库，还自带了 HTML 模板引擎。Echo 框架对模板引擎进行了一些额外处理，并提供了给用户自定义页面渲染的接口。本文就相关问题进行探讨。

## 模板渲染

Echo 框架的 Context 接口提供了下面的方法进行页面渲染：

```go
// echo 包中 Context 接口的方法
Render(code int, name string, data interface{}) error
```

其中，code 是 HTTP Status，name 是定义的模板名，data 是模板可能需要的数据。执行这个方法后，通过数据渲染模板，并发送带有 HTTP 状态的 text/html 响应。可以通过 Echo.Renderer 来注册模板，从而允许我们使用任何模板引擎。

Renderer 接口定义如下：

```go
// Renderer is the interface that wraps the Render function.
type Renderer interface {
  Render(io.Writer, string, interface{}, Context) error
}
```

这里可能会有点迷糊，怎么有两个 Render 方法，而且它们的签名还不一样。这里的逻辑是这样的：

- echo.Echo 类型有一个 Renderer 接口类型的字段，用来注册模板引擎；
- echo.Context 接口类型有一个 Render 方法，在 Handle 中我们通过调用 Context 的 Render 方法进行模板渲染；
- 在 Context 的 Render 方法内部（当然是 echo 中 Context 接口的默认实现），会调用 echo.Echo 的字段 Renderer 的 Render 方法，进行具体的模板渲染；

这里是具体的渲染源码：

```go
func (c *context) Render(code int, name string, data interface{}) (err error) {
	if c.echo.Renderer == nil {
		return ErrRendererNotRegistered
	}
	buf := new(bytes.Buffer)
	if err = c.echo.Renderer.Render(buf, name, data, c); err != nil {
		return
	}
	return c.HTMLBlob(code, buf.Bytes())
}
```

可见，如果调用了 Context#Render 进行模板渲染，但并没有注册模板引擎则会报错（ErrRendererNotRegistered）。

### 集成标准库模板引擎

1、我们先定义一个类型：Template，然后实现 Echo.Renderer 接口，即提供 Render 方法。

```go
type Template struct {
    templates *template.Template
}

func (t *Template) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
    return t.templates.ExecuteTemplate(w, name, data)
}
```

2、接着预编译一个模板。定义一个模板文件：template/index.html，内容如下：

```
{{define "index"}}Hello, {{.}}!{{end}}
```

然后预编译得到 Template 的实例：

```go
tpl := &Template{
    templates: template.Must(template.ParseGlob("template/*.html")),
}
```

3、注册模板引擎：

```go
e := echo.New()

e.Renderer = tpl
```

4、在 Handler 中渲染模板：

```go
e.GET("/", func(ctx echo.Context) error {
  return ctx.Render(http.StatusOK, "index", "studygolang")
})
```

注意这里的 index 是模板文件中 `define "index"` ，而不是文件名。

编译后运行，浏览器正常显示：Hello，studygolang!

![](https://s2.ax1x.com/2020/03/08/3v2XQ0.png)

## 通用化定制

一般的，页面会有一些通用的部分，比如头部、尾部等。所以业界通常的做法是有一个 layout，而且还可能不止一个 layout，因为普通用户看到的和后台看到的头部、尾部一般会不一样。那这样的通用化定制需求该如何集成到 Echo 的 Render 中呢？

先考虑只有一种 layout 的情况。定义一个类型 layoutTemplate，实现 Echo.Renderer 接口：

```go
type layoutTemplate struct{}

var LayoutTemplate = &layoutTemplate{}

func (l *layoutTemplate) Render(w io.Writer, contentTpl string, data interface{}, ctx echo.Context) error {
	layout := "layout.html"
	tpl, err := template.New(layout).ParseFiles("template/common/"+layout, "template/"+contentTpl)
	if err != nil {
		return err
	}

	return tpl.Execute(w, data)
}
```

然后注册该 Renderer，并在 Handler 中渲染，注意 ctx.Render 的第二个参数，跟上面说的不一样，我们传递的是子模板的文件名：index.html。

```go
e := echo.New()

e.Renderer = render.LayoutTemplate

e.GET("/", func(ctx echo.Context) error {
  return ctx.Render(http.StatusOK, "index.html", nil)
})
```

这里用到了两个模板文件：layout.html 和  index.html，来源 Hugo 的 [soho 这个模板](https://themes.gohugo.io/theme/soho/)。

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Echo博客系统</title>

  <meta name="author" content="Go语言中文网站长polaris">

  <meta name="keywords" content="" />
  <meta name="description" content="" />

  <link type="text/css" rel="stylesheet" href="/static/css/print.css" media="print">
  <link type="text/css" rel="stylesheet" href="/static/css/poole.css"> 
  <link type="text/css" rel="stylesheet" href="/static/css/hyde.css">

  <link rel="stylesheet"
        href="https://fonts.googleapis.com/css?family=Open+Sans:400,400i,700&display=swap">

  <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/css/all.min.css"
        integrity="sha256-mmgLkCYLUQbXn0B1SRqzHar6dCnv9oZFPEC1g1cwlkk="
        crossorigin="anonymous" />

  <link rel="apple-touch-icon-precomposed"
        sizes="144x144"
        href="https://themes.gohugo.io//theme/soho/apple-touch-icon-144-precomposed.png">

  <link rel="shortcut icon" href="https://themes.gohugo.io//theme/soho/favicon.png">

  </head>

<body>
  <aside class="sidebar">
    <div class="container">
        <div class="sidebar-about">
            <div class="author-image">
                <img src="https://themes.gohugo.io/theme/soho/images/profile.png" class="img-circle img-headshot center" alt="Profile Picture">
            </div>
            <h1>Echo-Gopher</h1>
        </div>

        <nav>
            <ul class="sidebar-nav">
                <li> <a href="/">Home</a> </li>
                <li> <a href="/about/"> About </a> </li>
            </ul>
        </nav>

        <section class="social-icons">

            <a href="https://github.com/polaris1119" rel="me" title="GitHub">
                <i class="fab fa-github" aria-hidden="true"></i>
            </a>
            
            <a href="https://weibo.com/studygolang" rel="me" title="Weibo">
                <i class="fab fa-weibo" aria-hidden="true"></i>
            </a>
            
        </section>
    </div>
  </aside>

  <main class="content container">
    {{template "content" .}}
  </main>

  <footer>
    <div class="copyright">
      &copy; polaris 2020 · <a href="https://creativecommons.org/licenses/by-sa/4.0">CC BY-SA 4.0</a>
    </div>
  </footer>

<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/js/all.min.js"
  integrity="sha256-MAgcygDRahs+F/Nk5Vz387whB4kSK9NXlDN3w58LLq0="
  crossorigin="anonymous"></script>
  
</body>
</html>
```

这是 layout.html 的内容，核心在于 `{{template "content" .}}`，表示具体内容模板需要定义 content，所以看看 index.html 文件：

```html
{{define "content"}}
<div class="posts">
    <article class="post">
        <h2 class="post-title">
            <a href="/">Echo 系列教程 — 定制篇3：自定义 Logger，用你喜欢的日志库</a>
        </h2>

        <div class="post-date">
            <time datetime="2020-03-06T00:00:00Z">Mar 06, 2020</time> · 3 min read
        </div>
        在知识星球简书项目中，我们分析对比了目前的一些日志库。虽然 Go 标准库有一个 log，但功能有限，所以才出现了很多第三方的日志库。
        <div class="read-more-link">
            <a href="http://blog.studygolang.com/2020/03/echo-custom-logger/">阅读全文</a>
        </div>
    </article>

    <article class="post">
        <h2 class="post-title">
            <a href="/">Echo 系列教程 — 定制篇2：自定义 Validator，进行输入校验</a>
        </h2>

        <div class="post-date">
            <time datetime="2020-02-28T00:00:00Z">Feb 28, 2020</time> · 4 min read
        </div>
        上一篇讲 Binder 时提到，参数自动绑定和校验是 Web 框架很重要的两个功能，可以极大的提升开发速度，并更好的保证数据的可靠性（服务端数据校验很重要）。
        <div class="read-more-link">
            <a href="http://blog.studygolang.com/2020/02/echo-custom-validator/">阅读全文</a>
        </div>
    </article>
</div>
{{end}}
```

运行后打开浏览器访问 http://localhost:2020 ：

![](https://s1.ax1x.com/2020/03/13/8uzXAf.png)

接下来看看如何处理多个 layout 的情况。

因为 Render 的签名是固定的，不同的 layout 通过什么方式告知 Render 呢？观察 Render 方法的参数：

```go
Render(w io.Writer, name string, data interface{}, ctx echo.Context)
```

可以在 data 和 ctx 上下功夫：

1. 将 data 指定为 map[string]interface{}，layout 通过 data 传递；

2. 通过 ctx 的 Set 方法设置 layout，方法内通过 ctx.Get 获取 layout；

先看第 1 种方式：

```go
// NoNavRender 没有导航的 layout html 输出
func NoNavRender(ctx echo.Context, contentTpl string, data map[string]interface{}) error {
	if data == nil {
		data = make(map[string]interface{})
	}
	data["layout"] = "nonav_layout.html"

	return ctx.Render(http.StatusOK, contentTpl, data)
}
```

在 render 包中增加了一个 NoVaRender 函数，该函数要求 data 必须是 map[string]interface{}，这样就可以做到将 layout 传递给 Render 方法，不过因为 Render 方法的 data 参数是 interface{} 类型，因此得做类型断言。

```go
layout := "layout.html"

if data != nil {
  if dataMap, ok := data.(map[string]interface{}); ok {
    if layoutInter, ok := dataMap["layout"]; ok {
      layout = layoutInter.(string)
    }
  }
}
```

看看第 2 种方式如何实现：

```go
// NoNavRender 没有导航的 layout html 输出
func NoNavRender(ctx echo.Context, contentTpl string, data interface{}) error {
	ctx.Set("layout", "nonav_layout.html")

	return ctx.Render(http.StatusOK, contentTpl, data)
}
```

在 Render 中获取 layout 的值：

```go
layout := "layout.html"

layoutInter := ctx.Get("layout")
if layoutInter != nil {
  layout = layoutInter.(string)
}
```

两种方式个人觉得第 2 种更优雅。不过需要注意的是，两种方式要注意 layout 不能冲突，也就是不能他用。

另外，我个人建议，data 参数永远要么传递 nil，要么传递 map[string]interface{} 。个人感觉 Echo 的 Render 方法 data 参数的类型不应该用 interface{} 而是用 map[string]interface{}，这样可以更方便地往 data 中加入更多全局的数据。在简书项目中，我们会通过其他方式弥补这个问题。

## 小结

通过本节，你应该掌握了 Render 的使用、集成和大项目 layout 的处理。

额外提一句，因为 Context.Render 方法最终是调用的 Context.HTML 方法进行渲染，因此我们也完全可以抛弃 Render 方法，而是使用自己的 Render。目前简书的代码（后续会改掉）和 studygolang 的源码采用的就是完全抛弃 Context.Render 的方式，主要考虑还是有一些 Render 不能很好满足的地方，比如上面说的多 layout、data 类型等，不过也是可以解决的。因此还是建议采用 Echo 框架的 Render。

本节[完整代码点这里](https://github.com/polaris1119/go-echo-example/tree/0cd46e8b1f38317439e95d55e3fe29a173a2e3c1)。


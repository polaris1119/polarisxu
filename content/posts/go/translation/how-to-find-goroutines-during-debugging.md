---
title: "如何在调试过程中查找 Goroutine"
date: 2020-09-18T18:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - goroutine
  - Debug
---

Goroutines 是大多数用 Go 编写的程序的重要组成部分。但是，使用大量 goroutines 会使程序难以调试。那怎么办？在此博文中，我们将介绍如何使用自定义数据为 goroutine 加上标签，这是 GoLand 2020.1（现已包含在 [EAP](https://blog.jetbrains.com/go/tag/2020-1/) 中）的最新功能之一。

## 目录

- 在 IDE 下使用
- 在命令行下使用
- 性能影响
- 使用自定义库启用调试标签

让我们以向 Web 服务器发出请求的应用程序为例：

```go
package main
 
import (
    "io"
    "io/ioutil"
    "math/rand"
    "net/http"
    "strconv"
    "strings"
    "time"
)
 
func fakeTraffic() {
    // Wait for the server to start
    time.Sleep(1 * time.Second)
 
    pages := []string{"/", "/login", "/logout", "/products", "/product/{productID}", "/basket", "/about"}
 
    activeConns := make(chan struct{}, 10)
 
    c := &http.Client{
        Timeout: 10 * time.Second,
    }
 
    i := int64(0)
 
    for {
        activeConns <- struct{}{}
        i++
 
        page := pages[rand.Intn(len(pages))]
 
        // We need to launch this using a closure function to
        // ensure that we capture the correct value for the
        // two parameters we need: page and i
        go func(p string, rid int64) {
            makeRequest(activeConns, c, p, rid)
        }(page, i)
    }
}
 
func makeRequest(done chan struct{}, c *http.Client, page string, i int64) {
    defer func() {
        // Unblock the next request from the queue
        <-done
    }()
 
    page = strings.Replace(page, "{productID}", "abc-"+strconv.Itoa(int(i)), -1)
    r, err := http.NewRequest(http.MethodGet, "http://localhost:8080"+page, nil)
    if err != nil {
        return
    }
 
    resp, err := c.Do(r)
    if err != nil {
        return
    }
    defer resp.Body.Close()
 
    _, _ = io.Copy(ioutil.Discard, resp.Body)
 
    time.Sleep(time.Duration(10+rand.Intn(40)) + time.Millisecond)
}
```

## 在 IDE 下使用

如果我们在调试器（debugger）中分析此代码，我们如何知道 makeRequest goroutines 在做什么？当我们看这样的清单时，这些 goroutine 的执行上下文什么？

![debugger without labels](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/03/debugger-classic-without-labels-optimized.png)

这就是 GoLand 新版本支持读取 goroutines 标签的缘由。

我们调整下上面的代码：（polaris 注：pprof 是标准库的 runtime/pprof ）

```go
go func(p string, rid int64) {
    labels := pprof.Labels("request", "automated", "page", p, "rid", strconv.Itoa(int(rid)))
    pprof.Do(context.Background(), labels, func(_ context.Context) {
        makeRequest(activeConns, c, p, rid)
    })
}(page, i)
```

现在，当在调试器中运行相同的代码时，我们将看到以下视图：

![debugger with labels](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/03/debugger-classic-with-labels-optimized.png)

看起来好多了。现在，我们可以看到在标签中设置的所有信息。而且，最重要的是，我们还可以看到通过函数调用在后台启动的其他 goroutine，它们都会自动携带标签。

由于 HTTP HandleFunc 这种形式的处理程序非常受欢迎，并且可以与其他处理程序类型进行比较，因此让我们看一下如何调整下面的代码以设置标签。

我们的原始代码将 m 用作 `*http.ServeMux`（或 `*github.com/gorilla/mux.Router`），看起来像这样：`m.HandleFunc("/", homeHandler)`。

应用标签代码后，它将变为如下所示：

```go
m.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    labels := pprof.Labels("path", r.RequestURI, "request", "real")
    pprof.Do(context.Background(), labels, func(_ context.Context) {
        homeHandler(w, r)
    })
})
```

这将标记处理每个 HTTP 请求的 goroutine，如下所示。

![debugging http middleware with labels](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/03/debugger-http-with-labels-optimized.png)

由于可以访问请求对象，因此可以使用比示例代码中更复杂的数据填充标签。

## 在命令行下使用

如果直接在命令行中使用 Delve，则需要使用 [1867862](https://github.com/go-delve/delve/commit/186786235fc9c2bd9b16c26bb4b0aef60ffb731c) 或更高版本的 Delve。这些更改将包含在下一个版本中，而当前v1.4.0 版本中未包含。

要查看标签，请在调试会话期间调用 `goroutines -l` 命令，以查看到与 IDE 中相同的数据。

![debugger dlv from command line with labels](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/03/debugger-dlv-with-labels-optimized.png)

## 性能影响

随之而来的自然问题是：使用上述代码对性能会有影响吗？

答案是肯定的，设置这些标签确实会降低性能。通常，它的影响很小，但是仍然会存在，因此最好使用一些基准测试代码在自己的硬件上进行测试。

考虑到这种影响，就会出现下一个问题：如果涉及性能，则意味着每次需要进行调试时，我都需要应用和撤消代码。这会影响我的开发速度，这能做得更好吗？

## 使用自定义库启用调试标签

要回答上述问题并允许我们的调试代码在不影响性能的情况下进行编译，请使用 [github.com/dlsniper/debugger](https://github.com/dlsniper/debugger) 库并更改我们的 makeRequest 代码以包括以下函数调用：

```go
func makeRequest(done chan struct{}, c *http.Client, page string, i int64) {
    defer func() {
        // Unblock the next request from the queue
        <-done
    }()
 
    debugger.SetLabels(func() []string {
        return []string{
            "request", "automated",
            "page", page,
            "rid", strconv.Itoa(int(i)),
        }
    })
	// ..
}
```

在调试器中运行此代码之前，我们需要进行其他更改。我们需要在运行配置的 Go 工具参数字段中添加 `-tags debugger`。否则，该库将加载生产代码，标签将不起作用。

![debugger - run configuration](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/03/debugger-run-configuration-optimized.png)

此处显示的库支持标准的 http.HandlerFunc 签名，以方便在现有应用程序中使用。

回到我们的代码，如下所示：`m.HandleFunc("/", homeHandler)`。

要将标签添加到这些处理程序，我们可以将代码更改为如下所示：

```go
m.HandleFunc("/", debugger.Middleware(homeHandler, func(r *http.Request) []string {
    return []string{
        "request", "real",
        "path", r.RequestURI,
    }
}))
```

**专业提示：**

在单个函数或方法中对 [debugger.SetLabels](https://pkg.go.dev/github.com/dlsniper/debugger?tab=doc#SetLabels) 函数进行多次调用，可以更轻松地跟踪执行进度并过滤掉不需要的数据。

**专业提示：**

可以复制运行配置，从而可以在有和没有调试器构建标记（build tag）的情况下使用代码。

**注意：**

如上所示，设置标签会导致性能下降。因此，仅在对性能要求不高的环境中使用 `-tags=debugger` 构建的二进制文件，或确保通过改善调试体验来抵消性能损失。

今天就这样。我们学习了如何使用 GoLand 调试复杂的 Go 应用程序并在 goroutine 中添加标签，从而使生活变得更轻松。

这篇文章中的所有代码都可以在 [github.com/dlsniper/debugger](https://github.com/dlsniper/debugger) 上找到。用于测试该库的示例代码可在  [github.com/dlsniper/serverdemo](https://github.com/dlsniper/serverdemo) 上找到。

> 作者：[Florin Pățan](https://blog.jetbrains.com/go/author/florin-patanjetbrains-com/)
>
> 原文链接：https://blog.jetbrains.com/go/2020/03/03/how-to-find-goroutines-during-debugging/
>
> 翻译：polaris


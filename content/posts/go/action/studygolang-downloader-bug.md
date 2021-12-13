---
title: "网友很强大，发现了Go并发下载的Bug"
date: 2021-07-07T22:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 并发
---

大家好，我是 polarisxu。

前几天我写了一篇文章：[Go项目实战：一步步构建一个并发文件下载器](https://polarisxu.studygolang.com/posts/go/action/build-a-concurrent-file-downloader/)，有小伙伴评论问，请求 `https://studygolang.com/dl/golang/go1.16.5.src.tar.gz` 为什么没有返回 Accept-Ranges。在写那篇文章时，我也试了，确实没有返回，因此我以为它不支持。

但有一个小伙伴很认真，他改用 GET 方法请求这个地址，结果却有 Accept-Ranges，于是就很困惑，问我什么原因。经过一顿操作猛如虎，终于知道原因了。记录下排查过程，供大家参考！（小伙伴的留言可以查看那篇文章）

## 01 排查过程

通过 curl 命令，分别用 GET 和 HEAD 方法请求这个地址，结果如下：

```bash
$ curl -X GET --head https://studygolang.com/dl/golang/go1.16.5.src.tar.gz
HTTP/1.1 303 See Other
Server: nginx
Date: Wed, 07 Jul 2021 09:09:35 GMT
Content-Length: 0
Connection: keep-alive
Location: https://golang.google.cn/dl/go1.16.5.src.tar.gz
X-Request-Id: 83ee595c-6270-4fb0-a2f1-98fdc4d315be

$ curl --head https://studygolang.com/dl/golang/go1.16.5.src.tar.gz
HTTP/1.1 200 OK
Server: nginx
Date: Wed, 07 Jul 2021 09:09:44 GMT
Connection: keep-alive
X-Request-Id: f2ba473d-5bee-44c3-a591-02c358551235
```

虽然都没有 Accept-Ranges，但有一个奇怪现象：一个状态码是 303，一个是 200。很显然，303 是正确的，HEAD 为什么会是 200？

我以为是 Nginx 对 HEAD 请求做了特殊处理，于是直接访问 Go 服务的方式（不经过 Nginx 代理），结果一样。

于是，我用 Go 实现一个简单的 Web 服务，Handler 里面也重定向。

```go
func main() {
	http.HandleFunc("/dl", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/", http.StatusSeeOther)
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello World")
	})
	http.ListenAndServe(":2022", nil)
}
```

用 curl 请求 `http://localhost:2022/dl`，GET 和 HEAD 都返回 303。于是我怀疑是不是 Echo 框架哪里的问题（studygolang 使用 Echo 框架构建的）。

所以，我用 Echo 框架写个 Web 服务测试：

```go
func main() {
	e := echo.New()
  
	e.GET("/dl", func(ctx echo.Context) error {
    return ctx.Redirect(http.StatusSeeOther, "/")
  })
  e.GET("/", func(ctx echo.Context) error {
    return ctx.String(http.StatusOK, "Hello World!")
  })
	
	e.Logger.Fatal(e.Start(":2022"))
}
```

同样用 curl 请求  `http://localhost:2022/dl`，GET 返回 303，而 HEAD 报 405 Method Not Allowed，这符合预期。我们的路由设置只允许 GET 请求。但为什么 studygolang 没有返回 405，因为它也限制只能 GET 请求。

于是我对随便一个地址发起 HEAD 请求，发现都返回 200，可见 HTTP 错误被“吞掉”了。查找 studygolang 的中间件，发现了这个：

```go
func HTTPError() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(ctx echo.Context) error {
			if err := next(ctx); err != nil {

				if !ctx.Response().Committed {
					if he, ok := err.(*echo.HTTPError); ok {
						switch he.Code {
						case http.StatusNotFound:
							if util.IsAjax(ctx) {
								return ctx.String(http.StatusOK, `{"ok":0,"error":"接口不存在"}`)
							}
							return Render(ctx, "404.html", nil)
						case http.StatusForbidden:
							if util.IsAjax(ctx) {
								return ctx.String(http.StatusOK, `{"ok":0,"error":"没有权限访问"}`)
							}
							return Render(ctx, "403.html", map[string]interface{}{"msg": he.Message})
						case http.StatusInternalServerError:
							if util.IsAjax(ctx) {
								return ctx.String(http.StatusOK, `{"ok":0,"error":"接口服务器错误"}`)
							}
							return Render(ctx, "500.html", nil)
					}
				}
			}
			return nil
		}
	}
}
```

这里对 404、403、500 错误都做了处理，但其他 HTTP 错误直接忽略了，导致最后返回了 200 OK。只需要在上面 switch 语句加一个 default 分支，同时把 err 原样 return，采用系统默认处理方式：

```go
default:
	return err
```

这样 405 Method Not Allowed 会正常返回。

同时，为了解决 HEAD 能用来判断下载行为，针对下载路由，我加上了允许 HEAD 请求，这样就解决了小伙伴们的困惑。

## 02 curl 和 Go 代码行为异同

不知道大家发现没有，通过 curl 请求 `https://studygolang.com/dl/golang/go1.16.5.src.tar.gz` 和 Go 代码请求，结果是不一样的：

```bash
$ curl -X GET --head https://studygolang.com/dl/golang/go1.16.5.src.tar.gz
HTTP/1.1 303 See Other
Server: nginx
Date: Thu, 08 Jul 2021 02:05:10 GMT
Content-Length: 0
Connection: keep-alive
Location: https://golang.google.cn/dl/go1.16.5.src.tar.gz
X-Request-Id: 14d741ca-65c1-4b05-90b8-bef5c8b5a0a3
```

返回的是 303 重定向，自然没有 Accept-Ranges 头。

但改用如下 Go 代码：

```go
resp, err := http.Get("https://studygolang.com/dl/golang/go1.16.5.src.tar.gz")
if err != nil {
  fmt.Println("get err", err)
  return
}

fmt.Println(resp)
fmt.Println("ranges", resp.Header.Get("Accept-Ranges"))
```

返回的是 200，且有 Accept-Ranges 头。可以猜测，应该是 Go 根据重定向递归请求重定向后的地址。可以查看源码确认下。

通过这个可以看到：<https://docs.studygolang.com/src/net/http/client.go?s=20406:20458#L574>，核心代码如下（比较容易看懂）：

```go
// 循环处理所有需要处理的 url（包括重定向后的）
for {
		// For all but the first request, create the next
		// request hop and replace req.
		if len(reqs) > 0 {
      // 如果是重定向，请求重定向地址
			loc := resp.Header.Get("Location")
			if loc == "" {
				resp.closeBody()
				return nil, uerr(fmt.Errorf("%d response missing Location header", resp.StatusCode))
			}
			u, err := req.URL.Parse(loc)
			if err != nil {
				resp.closeBody()
				return nil, uerr(fmt.Errorf("failed to parse Location header %q: %v", loc, err))
			}
			host := ""
			if req.Host != "" && req.Host != req.URL.Host {
				// If the caller specified a custom Host header and the
				// redirect location is relative, preserve the Host header
				// through the redirect. See issue #22233.
				if u, _ := url.Parse(loc); u != nil && !u.IsAbs() {
					host = req.Host
				}
			}
			ireq := reqs[0]
			req = &Request{
				Method:   redirectMethod,
				Response: resp,
				URL:      u,
				Header:   make(Header),
				Host:     host,
				Cancel:   ireq.Cancel,
				ctx:      ireq.ctx,
			}
			if includeBody && ireq.GetBody != nil {
				req.Body, err = ireq.GetBody()
				if err != nil {
					resp.closeBody()
					return nil, uerr(err)
				}
				req.ContentLength = ireq.ContentLength
			}

			// Copy original headers before setting the Referer,
			// in case the user set Referer on their first request.
			// If they really want to override, they can do it in
			// their CheckRedirect func.
			copyHeaders(req)

			// Add the Referer header from the most recent
			// request URL to the new one, if it's not https->http:
			if ref := refererForURL(reqs[len(reqs)-1].URL, req.URL); ref != "" {
				req.Header.Set("Referer", ref)
			}
			err = c.checkRedirect(req, reqs)

			// Sentinel error to let users select the
			// previous response, without closing its
			// body. See Issue 10069.
			if err == ErrUseLastResponse {
				return resp, nil
			}

			// Close the previous response's body. But
			// read at least some of the body so if it's
			// small the underlying TCP connection will be
			// re-used. No need to check for errors: if it
			// fails, the Transport won't reuse it anyway.
			const maxBodySlurpSize = 2 << 10
			if resp.ContentLength == -1 || resp.ContentLength <= maxBodySlurpSize {
				io.CopyN(io.Discard, resp.Body, maxBodySlurpSize)
			}
			resp.Body.Close()

			if err != nil {
				// Special case for Go 1 compatibility: return both the response
				// and an error if the CheckRedirect function failed.
				// See https://golang.org/issue/3795
				// The resp.Body has already been closed.
				ue := uerr(err)
				ue.(*url.Error).URL = loc
				return resp, ue
			}
		}

		reqs = append(reqs, req)
		var err error
		var didTimeout func() bool
		if resp, didTimeout, err = c.send(req, deadline); err != nil {
			// c.send() always closes req.Body
			reqBodyClosed = true
			if !deadline.IsZero() && didTimeout() {
				err = &httpError{
					// TODO: early in cycle: s/Client.Timeout exceeded/timeout or context cancellation/
					err:     err.Error() + " (Client.Timeout exceeded while awaiting headers)",
					timeout: true,
				}
			}
			return nil, uerr(err)
		}

  	// 确认重定向行为
		var shouldRedirect bool
		redirectMethod, shouldRedirect, includeBody = redirectBehavior(req.Method, resp, reqs[0])
		if !shouldRedirect {
			return resp, nil
		}

		req.closeBody()
	}
```

可以进一步看 redirectBehavior 函数 <https://docs.studygolang.com/src/net/http/client.go?s=20406:20458#L497>：

```go
func redirectBehavior(reqMethod string, resp *Response, ireq *Request) (redirectMethod string, shouldRedirect, includeBody bool) {
	switch resp.StatusCode {
	case 301, 302, 303:
		redirectMethod = reqMethod
		shouldRedirect = true
		includeBody = false

		// RFC 2616 allowed automatic redirection only with GET and
		// HEAD requests. RFC 7231 lifts this restriction, but we still
		// restrict other methods to GET to maintain compatibility.
		// See Issue 18570.
		if reqMethod != "GET" && reqMethod != "HEAD" {
			redirectMethod = "GET"
		}
	case 307, 308:
		redirectMethod = reqMethod
		shouldRedirect = true
		includeBody = true

		// Treat 307 and 308 specially, since they're new in
		// Go 1.8, and they also require re-sending the request body.
		if resp.Header.Get("Location") == "" {
			// 308s have been observed in the wild being served
			// without Location headers. Since Go 1.7 and earlier
			// didn't follow these codes, just stop here instead
			// of returning an error.
			// See Issue 17773.
			shouldRedirect = false
			break
		}
		if ireq.GetBody == nil && ireq.outgoingLength() != 0 {
			// We had a request body, and 307/308 require
			// re-sending it, but GetBody is not defined. So just
			// return this response to the user instead of an
			// error, like we did in Go 1.7 and earlier.
			shouldRedirect = false
		}
	}
	return redirectMethod, shouldRedirect, includeBody
}
```

很清晰了吧。

## 03 总结

很开心，还是有读者很认真的在看我的文章，在跟着动手实践，还对其中的点提出质疑。希望通过这篇文章，大家能够对 HTTP 协议有更深的认识，同时体会问题排查的思路。

有其他问题，也欢迎留言交流！

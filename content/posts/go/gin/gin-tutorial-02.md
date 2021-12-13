---
title: "Gin 系列教程 02：构建 API 端点"
date: 2021-09-18T22:00:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - Go
  - Gin
---

大家好，我是 polarisxu。

本文主要讲解 API Endpoint 相关内容，包括定义 API、实现 HTTP 路由等。

为了更好地讲解，以一个书店应用为例。

## 01 定义 Model

接着上节，将 main.go 中的内容重置：

```go
package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.Run()
}
```

在该文件中定义一个 struct：

```go
type Book struct {
	ID      int       `json:"id"`
	Name    string    `json:"name"`
	ISBN    string    `json:"isbn"`
	Author  string    `json:"author"`
	PubTime time.Time `json:"pub_time"`
	Press   string    `json:"press"`
	Tags    []string  `json:"tags"`
}
```

后续 API 设计基于此进行。

## 02 HTTP API 定义

采用 Restful 风格定义如下 API：

| HTTP Method | 资源                | 描述                       |
| ----------- | ------------------- | -------------------------- |
| GET         | /books              | 返回图书列表               |
| GET         | /book/{id}          | 返回一本存在的图书         |
| POST        | /book               | 创建一本图书               |
| PUT         | /book/{id}          | 更新已经存在的一本图书信息 |
| DELETE      | /book/{id}          | 删除一本存在的图书         |
| GET         | /books/search?tag=X | 根据 tag 搜索图书          |

以上 API 是我们计划实现的。

## 03 实现 HTTP 路由

基于上面定义的 API，在 Gin 中实现对应的路由。

### POST /book

先看创建一本图书。为了方便讲解，避免过早引入数据库导致复杂性，本节中，图书不会入库，而是存在内存中。本系列后续讲解存储时，会将这部分内容替换为入库操作。

因此，我们需要初始化一个 Book 切片：

```go
var books []*Book
func init() {
  // 容量 8 没有特殊考虑
  books = make([]*Book, 0, 8)
}
```

接着在 main.go 中定义一个 NewBookHandler，同时实现它。

```go
func NewBookHandler(ctx *gin.Context) {
	var book = &Book{}
	if err := ctx.ShouldBindJSON(book); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	book.PubTime = time.Now()

	books = append(books, book)

	ctx.JSON(http.StatusOK, book)
}
```

这里使用了 ctx.ShouldBindJSON 将请求内容绑定到 Book 中，因此要求请求的 body 是 JSON 格式。除了这种方式，Gin 还支持如下 Bind 方式：

- ShouldBindXML
- ShouldBindYAML
- ShouldBindQuery
- ShouldBindHeader
- ShouldBindUri

从名字知道什么意思。此外，还有 ShouldBind，它能够根据 Context-Type 自动选择以上合适的 Bind 方法，不过只能是 JSON 和 XML，其他的会报错。

实际上，以上所有的 Bind 方法都是调用 ShouldBindWith 方法的，该方法第二个参数是绑定类型：

```go
func (c *Context) ShouldBindWith(obj interface{}, b binding.Binding) error
```

而 binding.Binding 有如下一些值：

```go
var (
	JSON          = jsonBinding{}
	XML           = xmlBinding{}
	Form          = formBinding{}
	Query         = queryBinding{}
	FormPost      = formPostBinding{}
	FormMultipart = formMultipartBinding{}
	ProtoBuf      = protobufBinding{}
	MsgPack       = msgpackBinding{}
	YAML          = yamlBinding{}
	Uri           = uriBinding{}
	Header        = headerBinding{}
)
```

此外，还有对应的一系列方法：BindXxx，和 ShouldBindXxx 的不同在于解析出错时的处理方式。BindXxx 在出错时会返回 400/BadRequest 响应，而 ShouldBindXxx 不会。

然后绑定该 Handler：

```go
func main() {
	router := gin.Default()
	router.POST("/book", NewBookHandler)
	router.Run()
}
```

启动 HTTP 服务：

```bash
$ go run main.go
```

通过 Postman 来测试我们的创建图书 API：

### GET /books

创建图书 API 搞定后，先看获取所有图书列表的 API。因为图书都保存在 books 中，因此直接返回 books 即可：

```go
func ListBooksHandler(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, books)
}
```

同时在 main 函数中增加上路由：

```go
router.GET("/books", ListBooksHandler)
```


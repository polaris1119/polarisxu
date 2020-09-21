# 定制篇1：自定义 Binder，处理 Request 数据绑定

Web 开发，数据获取和校验是两个最基本的功能。在数据获取时，我们可以通过标准库的 `*http.Request` 提供的相关功能进行获取。然而这样效率是很低，重复工作较多，而且考虑到数据自动校验，我们更应该做到自动绑定。

在讲述 Echo 的 Binder 前，先探讨一下客户端数据一般通过什么方式发送给服务端的。

## 客户端如何传递数据给服务端？

这个问题其实对大部分人来说太简单了，然而，很多客户端的人却不清楚。工作中，我接触过不少客户端的人，对于数据怎么传递给服务端，他们是没有概念的，找到一个能用的方法发送给服务端就行了。比如，一个普通的数据通过 HTTP Header 来发送；分不清自己发送的数据是 key=json 形式还是 Body 中直接放 JSON，也就是不清楚 Content-Type 相关的含义。

为了让大家更容易掌握相关知识点，我通过问题的形式讲解。

### 问题 1：Get 和 Post 参数如何获取

讲再多都不如一个实际的程序演示来的清楚明白。

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		req.ParseMultipartForm(32 << 20)

		data := map[string]interface{}{
			"form":      req.Form,
			"post_form": req.PostForm,
		}

		fmt.Fprintln(w, data)
	})

	log.Fatal(http.ListenAndServe(":2020", nil))
}
```

这是一个简单的 Server，启动它：

> go run main.go

接着，我们通过 [httpie](https://github.com/jakubroztocil/httpie) 来模拟请求，看不同的输出。（关于 httpie 的使用可以看官方文档）

1）`http -v :2020 name==polaris`

命令的输出：

```bash
GET /?name=polaris HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: localhost:2020
User-Agent: HTTPie/2.0.0



HTTP/1.1 200 OK
Content-Length: 46
Content-Type: text/plain; charset=utf-8
Date: Fri, 21 Feb 2020 07:27:56 GMT

map[form:map[name:[polaris]] post_form:map[]]
```

作为一个服务端工程师，很有必要了解 HTTP 请求报文和响应报文。

从输出可以看出，GET 参数放在了 req.Form 中，实际开发中，一般这样获取 GET 的参数：`req.FormValue("name")`。因为默认情况下，参数并没有解析，也就是 Form 中没有，这也就是我们上面代码中 `req.ParseMultipartForm(32 << 20)` 这样代码的作用。而 req.FormValue 会判断有没有解析。

2）`http -v --form :2020 name==polaris name=xuxinhua sex=male`

直接看命令的输出：

```bash
POST /?name=polaris HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 22
Content-Type: application/x-www-form-urlencoded; charset=utf-8
Host: localhost:2020
User-Agent: HTTPie/2.0.0

name=xuxinhua&sex=male

HTTP/1.1 200 OK
Content-Length: 92
Content-Type: text/plain; charset=utf-8
Date: Fri, 21 Feb 2020 07:35:56 GMT

map[form:map[name:[xuxinhua polaris] sex:[male]] post_form:map[name:[xuxinhua] sex:[male]]]
```

这里发起了一个 POST 请求。需要关注以下几点：

- 请求中有参数：name=polaris
- 请求头：Content-Type: application/x-www-form-urlencoded; charset=utf-8
- 请求体（body）：name=xuxinhua&sex=male

因为 name 在 url 和 body 中分别有一个值：polaris 和 xuxinhua，因此，form 中 name 包含了两个值。从响应中结果可以看出，Form 同时包含了 url 参数和 body 的 key=value；而 PostForm 只包含 body 中的 key=value。（PUT 和 POST 是一样的效果）

因此，req.FormValue() 可以获取所有请求参数；而 req.PostFormValue() 获取 POST 之类的参数，如果同一个参数有多个值，只会取第一个，而 POST 参数优先级高于 URL 参数。

> 小问题：上面例子中，如果想要获取 name=polaris，而不是 name=xuxinhua，怎么做？

### 问题 2：客户端传递 JSON 怎么办？

继续基于上面的例子，执行如下命令：

```bash
$ http -v :2020 name=xuxinhua sex=male
```

输出如下：

```bash
POST / HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 35
Content-Type: application/json
Host: localhost:2020
User-Agent: HTTPie/2.0.0

{
    "name": "xuxinhua",
    "sex": "male"
}

HTTP/1.1 200 OK
Content-Length: 32
Content-Type: text/plain; charset=utf-8
Date: Fri, 21 Feb 2020 07:58:05 GMT

map[form:map[] post_form:map[]]
```

这次请求头的 Content-Type 值是：application/json，表明客户端将参数通过 JSON 格式传递，具体参数放在了 Body 中：

```json
{
    "name": "xuxinhua",
    "sex": "male"
}
```

从服务端的输出可以看到，Form 和 PostForm 都没有获取到这些参数，怎么办？答案是从 Body 中读取。如下：

```go
reqBody, err := ioutil.ReadAll(req.Body)
if err != nil {
  http.Error(w, err.Error(), http.StatusInternalServerError)
  return
}
data["json_data"] = string(reqBody)
```

最后简单说下 Content-Type 是 multipart/form-data 的情况。

当需要进行文件上传时，要求 Content-Type 设置为 multipart/form-data，对应的页面表单就是：

```html
<form action="/" method="POST" enctype="multipart/form-data"></form>
```

这样的表单才能进行文件上传。对文件上传的处理，Go 中对应的是 req.MultipartForm 和 req.FormFile()。

当然，除此之外，Content-Type 还有其他值（一般叫做 MIME），但常用的已经介绍了（相较而言，GET 只有一种 Content-Type: application/x-www-form-urlencoding）。

## Echo 的 Binder 是如何做的？

上面介绍的都是标准库 net/http 的相关 API，回到 Echo，有如下对应关系：

- Conetxt#QueryParam() 和  QueryParams() 方法获取 URL 参数；
- Context#FormValue() 和 FormParams() 方法获取 Form 参数，对应标准库的 PostForm；
- Context#FormFile() 和 MultipartForm() 方法处理文件上传；

除此之外，因为 Echo 路由支持路径参数（Path Param），对应的获取方法：Context#Param() 和 ParamNames()。

对于 Binder，Echo 默认提供了一个实现：echo.DefaultBinder，通常情况下，这个默认实现就能够满足要求。我们先看看它的实现。

### DefaultBinder 的实现

首先，Echo 定义了一个接口：

```go
type Binder interface{
  Bind(i interface{}, c Context) error
}
```

任何 Binder 必须实现该接口，也就是提供 Bind 方法。一起看看 DefaultBinder 的 Bind 方法实现：

```go
func (b *DefaultBinder) Bind(i interface{}, c Context) (err error) {
	req := c.Request()

	names := c.ParamNames()
	values := c.ParamValues()
	params := map[string][]string{}
	for i, name := range names {
		params[name] = []string{values[i]}
	}
	if err := b.bindData(i, params, "param"); err != nil {
		return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
	}
	if err = b.bindData(i, c.QueryParams(), "query"); err != nil {
		return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
	}
	if req.ContentLength == 0 {
		return
	}
	ctype := req.Header.Get(HeaderContentType)
	switch {
	case strings.HasPrefix(ctype, MIMEApplicationJSON):
		if err = json.NewDecoder(req.Body).Decode(i); err != nil {
			if ute, ok := err.(*json.UnmarshalTypeError); ok {
				return NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Unmarshal type error: expected=%v, got=%v, field=%v, offset=%v", ute.Type, ute.Value, ute.Field, ute.Offset)).SetInternal(err)
			} else if se, ok := err.(*json.SyntaxError); ok {
				return NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Syntax error: offset=%v, error=%v", se.Offset, se.Error())).SetInternal(err)
			}
			return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
		}
	case strings.HasPrefix(ctype, MIMEApplicationXML), strings.HasPrefix(ctype, MIMETextXML):
		if err = xml.NewDecoder(req.Body).Decode(i); err != nil {
			if ute, ok := err.(*xml.UnsupportedTypeError); ok {
				return NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Unsupported type error: type=%v, error=%v", ute.Type, ute.Error())).SetInternal(err)
			} else if se, ok := err.(*xml.SyntaxError); ok {
				return NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Syntax error: line=%v, error=%v", se.Line, se.Error())).SetInternal(err)
			}
			return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
		}
	case strings.HasPrefix(ctype, MIMEApplicationForm), strings.HasPrefix(ctype, MIMEMultipartForm):
		params, err := c.FormParams()
		if err != nil {
			return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
		}
		if err = b.bindData(i, params, "form"); err != nil {
			return NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
		}
	default:
		return ErrUnsupportedMediaType
	}
	return
}
```

一起分析下这个方法：

- DefaultBinder 的 bindData 方法进行实际的数据绑定，主要通过反射进行处理，要求被绑定的类型是 map[string]interface{} 或 struct（实际是时间它们的指针），有兴趣的可以查看它的源码；<https://github.com/labstack/echo/blob/master/bind.go#L86>
- 通过给 Struct 的字段加上不同的 Tag 来接收不同类型的值：
  - param tag 对应路径参数；
  - query tag 对应 URL 参数；
  - json tag 对应 application/json 方式参数；
  - form tag 对应 POST 表单数据；
  - xml tag 对应 application/xml 或 text/xml；
- 从代码的顺序可以看出，当同一个字段在多种方式存在值时，优先级顺序：param < query < 其他；

讲解完了，来一个实际的例子加深理解。

```go
package main

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

type User struct {
	Name string `query:"name" form:"name" json:"name"`
	Sex  string `query:"sex" form:"sex" json:"sex"`
}

func main() {
	e := echo.New()

	e.Any("/", func(ctx echo.Context) error {
		user := new(User)
		if err := ctx.Bind(user); err != nil {
			return err
		}

		return ctx.JSON(http.StatusOK, user)
	})

	e.Logger.Fatal(e.Start(":2020"))
}
```

同样使用 httpie 来进行测试。

**1）GET 请求**

```bash
$ http -v :2020 name==xuxinhua sex==male
```

输出：

```bash
GET /?name=xuxinhua&sex=male HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: localhost:2020
User-Agent: HTTPie/2.0.0



HTTP/1.1 200 OK
Content-Length: 33
Content-Type: application/json; charset=UTF-8
Date: Fri, 21 Feb 2020 09:27:25 GMT

{
    "name": "xuxinhua",
    "sex": "male"
}
```

能够正确绑定值。

**2）POST 请求**

特意加上 URL 参数混淆下，看看结果

```bash
$ http -v --form :2020 name==polaris name=xuxinhua sex=male
```

输出如下：

```bash
POST /?name=polaris HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 22
Content-Type: application/x-www-form-urlencoded; charset=utf-8
Host: localhost:2020
User-Agent: HTTPie/2.0.0

name=xuxinhua&sex=male

HTTP/1.1 200 OK
Content-Length: 33
Content-Type: application/json; charset=UTF-8
Date: Fri, 21 Feb 2020 09:46:09 GMT

{
    "name": "xuxinhua",
    "sex": "male"
}
```

从结果 name 是 xuxinhua 可以看出，URL 参数的优先级较低。

**3）请求参数是 JSON**

```bash
$ http -v :2020  name=xuxinhua sex=male
```

输出如下：

```bash
POST / HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 35
Content-Type: application/json
Host: localhost:2020
User-Agent: HTTPie/2.0.0

{
    "name": "xuxinhua",
    "sex": "male"
}

HTTP/1.1 200 OK
Content-Length: 33
Content-Type: application/json; charset=UTF-8
Date: Fri, 21 Feb 2020 09:48:48 GMT

{
    "name": "xuxinhua",
    "sex": "male"
}
```

一切正常。

**4）试试 XML ？**

目前 XML 用的还是比较少，基本是 JSON。所以，我们的例子代码默认并没有支持 XML。

我们先创建一个 XML 文件，作为输入：

```xml
<?xml version="1.0"?>
<user>
	<name>xuxinhua</name>
	<sex>male</sex>
</user>
```

接着执行如下命令：

```bash
$ http -v :2020 @user.xml
```

输出如下：

```bash
POST / HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 78
Content-Type: application/xml
Host: localhost:2020
User-Agent: HTTPie/2.0.0

<?xml version="1.0"?>

<user>
	<name>xuxinhua</name>
	<sex>male</sex>
</user>

HTTP/1.1 200 OK
Content-Length: 21
Content-Type: application/json; charset=UTF-8
Date: Fri, 21 Feb 2020 09:55:54 GMT

{
    "name": "",
    "sex": ""
}
```

一方面，请求的 Content-Type 是 application/xml，但响应却不对。原因是 User 结构中，我们没有为字段指定 xml 这个 tag，加上 tag 再试一下就会正确：

```go
type User struct {
	Name string `query:"name" form:"name" json:"name" xml:"name"`
	Sex  string `query:"sex" form:"sex" json:"sex" xml:"sex"`
}
```

实际中，需要设置什么 tag，你应该心里有数，没必要把所有支持的 tag 都设置上。

## 自定义 Binder

Echo 默认提供的 Binder 已经满足了大部分的需求，那什么时候需要自定义 Binder 呢？

现在一般接口都是用 JSON 作为数据交换格式，假如你老板觉得 JSON 性能不够，希望换其他格式，比如 [msgpack](https://msgpack.org/) 格式。这时候，echo 默认的 DefaultBinder 已经没法满足我们的需求了，这时候就需要自定义 Binder。类似的还有 protobuf 等。

### 自定义 MsgpackBinder

现在，我们就自己实现一个支持 msgpack 格式的 Binder。

```go
type MsgpackBinder struct{}

func (b *MsgpackBinder) Bind(i interface{}, ctx echo.Context) (err error) {
	// 也支持默认 Binder 相关的绑定
	db := new(echo.DefaultBinder)
	if err = db.Bind(i, ctx); err != echo.ErrUnsupportedMediaType {
		return
	}

	req := ctx.Request()
	ctype := req.Header.Get(echo.HeaderContentType)
	if strings.HasPrefix(ctype, echo.MIMEApplicationMsgpack) {
		if err = msgpack.NewDecoder(req.Body).Decode(i); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error()).SetInternal(err)
		}

		return
	}

	return echo.ErrUnsupportedMediaType
}
```

我们的自定义 Binder 除了支持 msgpack 外，还支持默认 Binder 支持的绑定方式。所以，在 Bind 方法入口，先实例化了一个 DefaultBinder，用它进行绑定处理。只有它返回的 err 是 ErrUnsupportedMediaType 时，才进行我们自定义 Binder 的处理逻辑。关于 msgpack 的解析，使用了第三方库：github.com/vmihailenco/msgpack ，使用方式和 JSON 类似。

这样，自定义的 Binder 就完成了。接下来需要替换到 Echo 默认的 Binder：

```go
e := echo.New()

e.Binder = new(MsgpackBinder)
```

即在得到 echo.Echo 的实例后，通过 e.Binder 来覆盖默认的 Binder。

### 验证自定义的 Binder

因为 msgpack 是二进制格式，不方便直接使用 httpie 进行验证。我们写一个简单的客户端工具进行验证。代码如下：

```go
package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/vmihailenco/msgpack"
)

func main() {
	type User struct {
		Name string
		Sex  string
	}

	b, err := msgpack.Marshal(&User{Name: "xuxinhua", Sex: "male"})
	if err != nil {
		panic(err)
	}

	resp, err := http.DefaultClient.Post("http://localhost:2020/", "application/msgpack", bytes.NewReader(b))
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	result, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	fmt.Printf("%s\n", result)
}
```

启动服务端，然后运行客户端。我本地试验，输出结果如下：

```json
{"name":"xuxinhua","sex":"male"}
```

表明我们的自定义 Binder 生效了。

> 说明一下，跟标准库的 json 一样，没有 tag 时，msgpack 库能根据导出字段识别出对应关系。默认情况，msgpack 库使用 msgpack 这个 tag，同时可以通过 UseJSONTag 方法来退而求其次使用 json 这个 tag。当然，我们这里没有使用 tag，而是根据导出字段自动识别对应关系的。

## 小结

到这里，自定义 Binder 就介绍完了。内容比较简单，但是必须掌握，这是基础知识。另外，这里没有提到 cookie，标准库和 echo 都提供了相关的方法进行处理，但一般 cookie 不需要进行数据绑定，额外处理即可。

本文完整代码：<https://github.com/polaris1119/go-echo-example/tree/master/cmd/binder>
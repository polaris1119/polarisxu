---
title: "Go Team Leader — rsc 大神新开源了一个库，增强模板功能"
date: 2021-05-12T12:30:00+08:00
toc: true
isCJKLanguage: true
tags:
  - Go
  - rsc
  - tmplfunc
---

大家好，我是站长 polarisxu。

今天给大家分享一个 rsc 新开源的一个库：[rsc.io/tmplfunc](https://pkg.go.dev/rsc.io/tmplfunc)。

这个库是对 Go 标准库模板的扩展，可以像调用函数一样调用模板。通过一个例子看怎么使用。

## 01 标准库

因为 text/template 和 html/template 基本是一样的，且 tmplfunc 这个包同时支持两者，本文使用 text/template 来演示。

有如下代码：

```go
package main

import (
	"os"
	"text/template"
)

var stdstr = `{{link "https://golang.org" "The Go language"}}
{{link "https://studygolang.com" "Go语言中文网"}}
`

func main() {
	testStdlib()
}

func testStdlib() {
	funcMap := template.FuncMap{
		"link": func(url, title string) string {
			return `<a href="` + url + `">` + title + `</a>`
		},
	}
	t, err := template.New("tmplstd").
		Funcs(funcMap).
		Parse(stdstr)
	if err != nil {
		panic(err)
	}

	err = t.Execute(os.Stdout, nil)
	if err != nil {
		panic(err)
	}
}

```

这个例子在 Go 代码中定义了一个模板函数，构造一个 URL 链接。在模板中，通过调用这个函数生成 URL，达到了复用的目的。以上代码输出：

```bash
<a href="https://golang.org">The Go language</a>
<a href="https://studygolang.com">Go语言中文网</a>
```

## 02 使用 rsc.io/tmplfunc

现在使用 rsc.io/tmplfunc 这个库改写这个例子，代码如下：

```go
package main

import (
	"os"
	"text/template"

	"rsc.io/tmplfunc"
)

var tmplstr = `{{define "link url text"}}<a href="{{.url}}">{{.text}}</a>{{end}}
{{link "https://golang.org" "The Go language"}}
{{link "https://studygolang.com" "Go语言中文网"}}
`

func main() {
	testTmplfunc()
}

func testTmplfunc() {
	t := template.New("tmplfunc")
	err := tmplfunc.Parse(t, tmplstr)
	if err != nil {
		panic(err)
	}

	err = t.Execute(os.Stdout, nil)
	if err != nil {
		panic(err)
	}
}
```

- 主意 tmplstr 这个变量的内容，相比标准库版本多了这一句 `{{define "link url text"}}<a href="{{.url}}">{{.text}}</a>{{end}}`，这其实是定义模板的语法，tmplfunc 重用了它。link 可以理解为函数，url 和 text 理解为函数的参数。
- 在 testTmplfunc 函数中，得到 template 实例后，没有直接调用其 Parse 方法，而是调用了 tmplfunc 的函数 Parse，并将 template 的实例作为第一参数传递。

其他的和标准库没有区别。运行后输出是一样的。

## 03 学习更多

通过上面的例子，基本上我们已经掌握了该包的用法，同时也可以看出，该包让模板重用在模板页面完成，而不需要在 Go 代码中进行，目前我能想到的使用场景不多，但知晓有这么个库，也许在实际中有这样的需求。

关于该包，需要额外补充一点。在 define 定义时，除了上面例子的形式，还支持可选参数。可选参数通过 ? 表示，如：

```html
{{define "link url text?"}}<a href="{{.url}}">{{or .text .url}}</a>{{end}}
```

还支持可变参数，这和 Go 的语法一样，通过三个点表示：

```html
{{define "myprint names..."}}
	{{range .names}}
		{{.}}
	{{end}}
{{end}}
{{myprint "polarisxu" "studygolang"}}
```

定义是注意顺序：普通参数、可选参数、可变参数。

关于标准库中对应的 Parse，该库提供了对应的函数，具体可以查看文档。

密切关注大神的动态，努力跟随大神的步伐~加油！！！


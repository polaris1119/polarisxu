---
title: "快一个月，Go1.16 才发现了比较严重的 Bug，但这个 Bug 有点 Low。。。"
date: 2021-03-11T18:12:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Bug
---

大家好，我是站长 polarisxu。

Go 1.16 是 2021 年 2 月 16 日发布的。新版本发布，大家一般会等等，坐等 1.16.1 发布。没想到快一个月了才等到。

和之前一样，小版本是修复 Bug，会同时发布两个版本，这次是 Go1.16.1 和 Go1.15.9。那具体什么 Bug 呢？

## Bug 1：encoding/xml 包相关

这个 Bug 不是 1.16 引入的，而是之前版本就存在。所以，Go 1.15.9 也修复了该 Bug。

具体是：在通过 xml.NewTokenDecoder 获得一个 Decoder 指针时，如果参数 TokenReader 是自定义的，可能会出现死循环。

> The Decode, DecodeElement, and Skip methods of an xml.Decoder provided by xml.NewTokenDecoder may enter an infinite loop when operating on a custom xml.TokenReader which returns an EOF in the middle of an open XML element.

详情见 issue：<https://github.com/golang/go/issues/44915>。

## Bug 2：archive/zip 包相关

当调用该包中的 Render.Open 方法时，如果 zip 包含以 `../` 开头的文件，该方法会 panic。这个方法是 Go1.16 新增的，因为返回了 io/fs.File 类型。

```go
func (r *Reader) Open(name string) (fs.File, error)
```

当跟踪修复该 Bug 的代码时，有点掉价。。。（见：<https://github.com/golang/go/commit/634d28d78ccbeb6e86f8bfeba030ea8be518f8fa>）

![](/Users/xuxinhua/opensource/polarisxu/content/posts/go/dynamic/imgs/go1.16.1.png)

 完整的修复前的代码：

```go
func toValidName(name string) string {
	name = strings.ReplaceAll(name, `\`, `/`)
	p := path.Clean(name)
	if strings.HasPrefix(p, "/") {
		p = p[len("/"):]
	}
	for strings.HasPrefix(name, "../") {
		p = p[len("../"):]
	}
	return p
}
```

通过 for 循环处理 p 中的 `../`，结果 for 里面用的却是 name 变量，这个 bug 有点 low。。。可见大神们也有犯低级错误的时候。所以，如果你团队成员偶尔犯了低级错误，别太责备，让他抄写对应 Bug 100 遍即可，哈哈哈哈！

以上两个 Bug 都定义为安全问题。Go Team 正在为 Go 版本中的漏洞提出一个新的安全策略。有兴趣的可以参与讨论：<https://github.com/golang/go/issues/44918>。

---

如果你使用了 Go1.16，而且可能用了 zip 包，建议大家升级到 Go1.16.1 版本。而 xml，可能很多人都没用到？！Go 语言中文网已经为你准备好了下载地址：<https://studygolang.com/dl>，当然也可以使用喜欢的方式升级。


# Go 源代码中的复活节彩蛋

## 前言

前段时间，我在某个 Slack 工作区与朋友聊天：

> 朋友：“有人知道为什么`time.minWall` 的默认值是 1885 吗？”
> 我：“不知道，也许是从《*回到未来 3*》那一年开始的？”

我那么说基本是在开玩笑，因为我也不知道为什么将其设置为 1885 年。尽管其背后的事实与我在 Go 中的日常编码没有任何关系，但我还是情不自禁地询问了幕后花絮。我在团队聊天中问了我的同伴 Gophers，但似乎没人能找到相关的线索。

最后，我直接向 Russ Cox（[@_rsc](https://twitter.com/_rsc)）发送了一封电子邮件，以了解背景。

## time.minWall

一个 const 值`time.minWall`设置为 1885，在如下代码中：

- [src/time/time.go](https://github.com/golang/go/blob/release-branch.go1.15/src/time/time.go#L153)

```go
const (
    hasMonotonic = 1 << 63
    maxWall      = wallToInternal + (1<<33 - 1) // year 2157
    minWall      = wallToInternal               // year 1885
    nsecMask     = 1<<30 - 1
    nsecShift    = 30
)
```

这是个常数值，它定义了时间包中值的时代。这是一个常量值，它定义了 time 包的时间纪元。我们经常使用 UNIX 纪元（即 1970 年 1 月 1 日 UTC 的 00:00:00），但这只是几个用于表示日期时间值的标准或实现中的一个纪元，当然 Go 是一种多平台语言，因此 Go 中的纪元需要涵盖所有这些平台。

Russ Cox 在以下地方公开评论了 Go 的纪元。第一个是在 [GitHub issue 上](https://github.com/golang/go/issues/12914#issuecomment-277335863)：

> 已合入 Go 1.9。我将内部纪元移到 1885 年（最大年份为 2157 年），以避免 NTP 纪元派生的时间出现任何可能的问题。我还调整了设计文档，以调整此更改和一些较小的编码更改。

但是这个评论只提到了为什么以及何时将内部纪元移到 1885 年，而没有提及为什么他们没有移至其他年份，例如 1900 年。

第二个是内部纪元移动的提案文档。

- [提案：Go 中的单调时间测量](https://github.com/golang/proposal/blob/master/design/12914-monotonic.md)

> 基于 Unix 的系统通常使用 1970，而基于 Windows 的系统通常使用 1980。我们不知道任何使用更早默认壁钟时间（Wall Time）的系统，但是由于 NTP 协议纪元使用 1900，因此选择 1900 之前的年份似乎更具前瞻性。

可见，理论依据也只是支持 1900 年之前的任何年份，而不是特指 1885 年。我几乎可以肯定，这一年来自“*回到未来 3”*，但我想 100％ 确定这一年，所以我联系了肯定知道这一点的人，即向 Russ Cox 发送了一封电子邮件，询问原因。他在一天之内做出了回应（考虑到 EDT 和 JST 之间的时区差异，这是非常快的）：

> 是的，人们说服我移到 1900 年之前，而 1885 年是显而易见的选择，因为它对加利福尼亚的希尔山谷（Hill Valley）具有历史意义。:-)

这就是我知道的！！同样，我很高兴能够从谁做出决定中得到真正的答案。

## http.aLongTimeAgo

尽管我很欣赏 Russ 的回答，但这还不是故事的结局。Russ 的回信中还有另外一行。

> 另请参见 http.aLongTimeAgo，现在将其设置为 time.Unix(1, 0)，但以前是 time.Unix(233431200, 0)。

正如他所说，在 Go1.15 中，它设置为`time.Unix(1, 0)`。

- [Go 1.15: src/net/http/http.go](https://github.com/golang/go/blob/dev.boringcrypto.go1.15/src/net/http/http.go#L30)

```
// aLongTimeAgo is a non-zero time, far in the past, used for
// immediate cancellation of network operations.
var aLongTimeAgo = time.Unix(1, 0)
```

因此，我们在源码中确认其原始值。你可以在 Go 1.8 中找到它。

- [Go 1.8: src/net/http/http.go](https://github.com/golang/go/blob/dev.boringcrypto.go1.8/src/net/http/http.go#L23)

```
// aLongTimeAgo is a non-zero time, far in the past, used for
// immediate cancelation of network operations.
var aLongTimeAgo = time.Unix(233431200, 0)
```

我们将 UNIX 时间转换为人类可读的格式。当然，Go 提供了超级简单的方法。

- [示例代码：以人类可读的格式读取 UNIX 时间](https://play.golang.org/p/c4u1lF5Q6xQ)

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    pdt, _ := time.LoadLocation("America/Los_Angeles")
    t := time.Unix(233431200, 0).In(pdt)
    fmt.Println(t)
}
```

结果是：

```
1977-05-25 11:00:00 -0700 PDT
```

我们得到 2 条提示：“A Long Time Ago”和 “1977-05-25”。这两个是：

![](imgs/eggs01.jpeg)

当然，除了*《星球大战：第四集》外*，别无其他。它于1977年5月25日发布的（[Wikipedia](https://en.wikipedia.org/wiki/Star_Wars_(film))）

Go 包中如何使用此值呢？这是通过指定过去时间的截止日期来强制取消现有连接，例如：

```
cr.conn.rwc.SetReadDeadline(aLongTimeAgo)
```

当该值被改为 `time.Unix(1, 0)` 时，有人注意到了，因此对此作了一些评论（比如 1977-05-25 是谁的生日吗？）。我喜欢看到这些评论。这些有趣的聊天有时会在更改列表中进行。

- [net, net/http: 调整过去的时间到更早的时间](https://github.com/golang/go/commit/6983b9a57955fa12ecd81ab8394ee09e64ef21b9)

## 致谢

- Russ Cox：感谢您回答我的问题和其他信息。另外，感谢您允许公开分享此内容。引用他的评论：

> 放心吧。这里没有秘密。

- [Chris Broadfoot](https://twitter.com/broady) 和 [Valentin Deleplace](https://twitter.com/val_deleplace)：感谢你们在群聊中一起找到线索。
- [mattn](https://twitter.com/mattn_jp)：感谢您让我知道人们对此价值[有何](https://twitter.com/mattn_jp)反应的 GitHub 评论线。

## 注意

该文最初于 2020-07-17 发布于我的日语博客中。

- https://ymotongpoo.hatenablog.com/entry/2020/07/17/093000

> 原文链接：https://dev.to/ymotongpoo/easter-eggs-in-go-source-code-2l02
>
> 作者：Yoshi Yamaguchi
>
> 编译：polarisxu
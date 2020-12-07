---
title: "欢迎加入 GoLand 2020.1 抢先体验计划"
date: 2019-12-24T14:17:51+08:00
toc: true
tags: 
  - GoLand
  - 开发工具
categories:
  - 开发工具
---

GoLand 2020.1 抢先体验计划已经启动。对于此发行版，我们着重于易用性，性能以及减少浪费在样板代码和 IDE 中的冗余操作上的时间。我们还包括对 Go Modules 支持的升级，和其他更多功能。您可以在 2020.1 的[路线图博客](https://blog.jetbrains.com/go/2019/12/24/whats-next-goland-2020-1-roadmap/)文章中找到简短说明。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/blog@2x.jpg)

你可以通过 [Toolbox App](https://www.jetbrains.com/toolbox/app/?_ga=2.109771525.1651118980.1581665300-159533074.1581665300) 获得它，也可以从[网站上下载](https://www.jetbrains.com/go/nextversion/)，也可以使用快照包（对于 Ubuntu）；或者直接在 GoLand 中通过自动更新的方式获取。*Preferences / Settings | Appearance & Behavior | System Settings | Updates*。

如果您想知道什么是抢先体验计划，这里有一个简短的解释：

> EAP 版本使您可以试用 Goland 仍在开发中的最新功能和增强功能。这些版本尚未经过全面测试，可能会不稳定，但是您可以在这里为我们提供帮助。通过将这些内部版本和功能用于实际项目和场景中来测试，您可以帮助我们完善它们。这样，当最终版本准备就绪时，它将为您更好地工作。

- EAP 使您可以首先试用所有最新功能;
- 自构建日期起 30 天内免费使用 EAP 版本。您可以将这段时间用作 GoLand 的扩展试用版；
- 我们会提供 EAP 版本，直到几乎可以发布稳定版本为止。对于即将推出的 2020.1 版本，EAP 期将大致持续到 3 月底；
- 在每个发布周期中，我们都会为他们提供免费的 1 年 GoLand 订阅和一件独家的 [GoLand T 恤](https://twitter.com/GoLandIDE/status/1116361899308912645)，以表彰他们中最活跃的评估人员。![](https://s2.ax1x.com/2020/02/15/1xBtL8.jpg)
- 此外，我们几乎每天都提供最新版本。因此，如果您不想等待正式的 EAP 版本公告，则只需下载这些夜间版本之一，即可通过 Toolbox App 获得。请注意，每晚构建的质量通常低于我们的标准，并且没有随附发行说明。与 EAP 版本一样，它们也将在发布后 30 天内过期；

因此，让我们看一下第一个 EAP 版本中包含的内容。

## Go Modules

现在，您可以通过 go.mod 文件中的 **Alt-Enter** 来获取缺失的依赖项并删除未使用的依赖项。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/go-mod-file-support.gif)

## Go 1.14 支持

Go 1.14 增加了对嵌入重叠接口的支持，我们也是如此！当您使用重叠的接口时，GoLand 不会将重复的方法报告为错误。

为什么将此功能添加到语言中？

主要好处是我们可以使用嵌入定义接口，而不需要手动定义。这是一个例子：

```go
type Person interface {
	Name() string
	String() string
}
 
type Employee interface {
	Person
	Department() string
	String() string
}
```

在 Go 1.14 之前，我们无法在 Employee 接口上添加 String() 方法，因为该方法已在 Person 接口上定义了。现在，我们可以使用接口嵌入定义它，如果 Person 接口有更新，我们自己更可控。

## 代码补全/完成增强

我们对样板代码说不！GoLand 为常见的错误处理模式添加了代码完成功能。现在，当您在函数中键入`if `时，您可以选择 `err！= nil {…}` 以自动完成它。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/code-completion-handling-errors.gif)

为了更快地定义接口和结构，现在，当您键入`type` 关键字时，IDE 会为它们建议模板。当您输入 `interface` 或 `struct` 时，将显示相同的补全内容。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/type-keyword-completion-struct-interfaces.gif)

现在，根据格式设置规则的要求，**Fill Fields** 操作会在冒号后添加空格，并在复合文字中的语句末尾添加逗号。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/field-name-completion.gif)

现在，当您使用 map 时，完成键类型后，代码补全将光标移到右括号后面。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/code-compltion-map.gif)

**智能代码补全**建议使用指向结构的指针。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/code-completion-for-pointer-to-struct-initializer.gif)

最终，代码补全变得更加智能，现在在断言和 type-switch-case 中会首先建议兼容类型。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/type-assertion-completion.gif)

## 代码编辑增强

当编写多值返回函数的签名时，GoLang 2020.1 将在逗号后面的返回类型周围自动添加括号。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/multi-value-return-function.gif)

此外，当您在字符串中粘贴一些文本时，GoLand 会自动转义双引号。

## Postfix 完成模板

`.else` Postfix 完成模板可以快速添加 `if` 语句，以检查表达式是否为假。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/else-postfix-completion.gif)

## 实时模板

我们添加了新的 *consts*, *vars*, *types*, 和 *import* 模板 。对于这些模板，默认情况下，GoLand 将在表达式周围添加括号。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/consts-vars-live-templates.gif)

fori 模板插入经典 for 循环的样板代码。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/fori-live-template.gif)

## 重构

现在，即使接口定义中省略了参数名称，*Implement Methods*（在 macOS 和 Windows/Linux 上为 Ctrl + I）也允许您指定参数名称。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/implement-methods.gif)

## 性能

现在 *Navigate to implementations*（在 MacOS 上为 ⌥⌘B，在 Windows/Linux 上为 Ctrl + Alt + B）和 *Navigate to Declaration or Usages*（在 macOS 上为 ⌘B，在 Windows/Linux 上为 Ctrl + B）速度更快，因为它们首先在项目范围内寻找实现。另外，搜索结果在非项目元素之前显示项目元素，而不是按字母顺序对它们进行排序。

我们还限制了 dep 和 Go Modules 项目的参考搜索范围，以提高其搜索性能。

## JetBrains Mono 字体

如果您想知道本博客文章中的屏幕截图和 GIF 使用的是哪种字体 — 我们在 JetBrains 上为开发人员创建了一种新的字体，称为 [JetBrains Mono](https://www.jetbrains.com/lp/mono/)。现在默认情况下它在 GoLand 中可用，请打开 *Preferences / Settings | Editor | Font*，然后选择 JetBrains Mono 尝试一下。

![](https://d3nmt5vlzunoa1.cloudfront.net/go/files/2020/02/jetbrains-mono-font.png)

## 拼写检查器

前一段时间，我们宣布了一个名为 Grazie 的插件。此插件可为您在 IDE 中编写的文本提供智能的拼写和语法检查，并且支持 15 种以上的语言，包括英语，德语，俄语，中文等。在此 EAP 版本和即将发布的 2020.1 版本中，默认情况下捆绑了 Grazie。要了解更多信息，请阅读此[博客文章](https://blog.jetbrains.com/idea/2019/11/meet-grazie-the-ultimate-spelling-grammar-and-style-checker-for-intellij-idea/)。

## 默认配色方案改回为亮色

许多用户要求我们为 Default 和 Darcula 配色方案中突出显示的语义代码增加更多种类，而我们在 2019.2 版本中进行了添加。一些用户很高兴，而其他用户则不满意，请我们还原更改。

因此，为了使所有人感到高兴，我们决定恢复默认配色方案，但使用了新名称 Classic Light。

要切换配色方案，请打开 *Preferences/Settings | Editor | Color Scheme* 选择。

## JBR8 支持终止

从现在开始，我们将完全转向 JetBrains Runtime 11（JBR11），并且将不再分发带有 JetBrains Runtime 8（JBR8）的内部版本。请注意，IDE 和工具箱应用程序中的所有 GoLand 2020.1 更新都将随附 JBR11。

请记住，我们始终感谢您的反馈，因此请在留言区，Twitter 或 [issue tracker](https://youtrack.jetbrains.com/issues/GO) 中与我们分享您的试用情况。

> 由 Ekaterina Zharova 在 2020 年 2 月 6 日发布
>
> 原文：https://blog.jetbrains.com/go/2020/02/06/welcome-to-the-goland-2020-1-eap/


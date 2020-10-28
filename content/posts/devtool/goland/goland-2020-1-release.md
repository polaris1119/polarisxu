---
title: "还在用 2019.3 就 Out 了：GoLand 2020.1 版本正式发布"
date: 2020-04-10T14:17:51+08:00
toc: true
tags: 
  - GoLand
  - 开发工具
  - 发布
---

北京时间 2020 年 4 月 10 日凌晨，Jetbrains 宣布正式发布 GoLand 2020.1 版本。

该版本主要的变化有：

引入了对 Go 模块支持的各种升级以及代码编辑功能，这些功能几乎不需要用户交互，也不需要扩展的代码补全系列。

除此之外，还添加了新的代码检查、快速修复和其他改进，例如新的 LightEdit 模式（可让您在文本编辑器中打开文件，而无需创建或加载项目）、智能拼写和语法检查以及用于 Web 开发和数据库处理的新功能。

Go 语言中文网在 2020.1 还未正式发布之前，就发过关于该版本特性的文章，现在 2020.1 正式发布了，相关功能特性稳定了，我们再次介绍下相关新特性。

## Go 模块改进

2020.1 现已支持 Go 1.13 的环境变量 GOPROXY、GOPRIVATE、GOSUMDB、GONOPROXY 和 GONOSUMB。

使用 Go Modules 项目模板配置其默认值。只需点击 Environment 字段中的 Browse 图标即可打开新的 Environment Variables 对话框。

go.mod 文件支持 go、module、require、replace 和 exclude 关键字代码补全、依赖项名称以及本地路径替换。

此外，也可以使用 Rename 和 Move 重构。 重命名或移动由 replace 语句引用的目录时，GoLand 将相应地更改 go.mod 文件中的路径。

现在，您还可以通过 Project 视图调用 Find Usages，以探索 go.mod 文件中特定目录路径的使用位置。

在 GoLand 2020.1 中，您可以通过 Alt-Enter 获取缺失的依赖项并移除未使用的依赖项。

最后但同样重要的是，如果存在本地路径替换，则新版本将在您提交之前显示一条通知，这样您就不会意外提交它们。

## 您无需学习如何使用的代码补全功能

GoLand 2020.1 将建议 if err != nil { ... } 来补全错误处理模式。 只需在表达式内输入 if。

只需输入 type 关键字或 struct 和 interface，即可更快地定义结构和接口类型。

Fill Fields 操作在格式化规则要求时会在冒号后面添加空格。 它还会在组合文字声明中语句的末尾添加逗号。

现在，使用 map 时，代码补全会在您补全键类型后将光标移到右中括号后面。

对于函数的返回类型，补全功能将为局部变量和零值提供适合相应返回值类型的建议。

## 智能代码补全（⌥⇧Space 或 Ctrl+Shift+Space）

智能代码补全会建议一个指向结构初始值设定项的指针。

它还会建议在断言和类型 switch 用例中首先使用兼容类型。

在类型断言中，它提供已赋值变量的类型。

最后，它提供了表达式中可能指针的建议列表。

## 基本代码补全（⌃空格或 Ctrl+空格）

为注释添加了基本代码补全，这将使编写文档更加轻松！ 它可为当前包声明建议名称，并为函数和方法建议参数名称。除此之外，基本代码补全还可以建议文字和转换。

## 代码编辑

编写多值返回函数的签名时，GoLand 2020.1 会在逗号后面的返回类型周围添加括号。当您在字符串文字中粘贴一些文本时，IDE 会转义双引号。

## Go 1.14 支持

1）支持重叠接口

Go 1.14 添加了对嵌入重叠接口的支持，我们也添加了此功能！ 当您使用重叠接口描述类型的不同方面时，GoLand 不会将这些方面的重复方法报告为错误。

2）自动 vendoring 模式

如果模块根包含 vendor 目录，则会在 Go 1.14 中自动启用 vendoring 模式。 对于 GoLand 2020.1，我们决定为 Go 1.13 及更早版本实现类似的行为。 IDE 会自动将导入解析到 vendor/ 文件夹（如果模块中存在）。

## 调试器更新

1）分析器标签支持

为了帮助您在调试或核心转储分析过程中更轻松地区分 goroutine，我们为其添加了分析器标签。更多详情请参考：[如何在调试过程中查找 Goroutine](https://mp.weixin.qq.com/s/ANNUlYvWshNikNwCw6qSHw)。

2）宏支持

现在，可以将宏用作运行或调试应用程序的参数。 在 Run/Debug Configurations 对话框中，点击 Go Tool 中的 + 或 Program arguments 字段即可打开新的 Macros 对话框，其中会列出要使用的可用宏。

此外，您现在还可以将配置文件存储在项目中。 在 Run/Debug Configurations 对话框的顶部，选择 Store 作为项目文件选项。

## 后缀补全

`.else` *Postfix Completion* 模板可以快速添加 `if` 语句来检查表达式是否为假。

## 快速修复

按下 Alt+Enter，可立即将非格式化调用更改为格式化调用。现在，Create variable 快速修复会显示预期的类型提示，以便您更轻松地输入正确的值。

## 代码检查

新代码检查可以警告您注意非指针接收器上指针方法的无效调用，并提供了快速修复。

如果错误使用 uintptr 和 unsafe.Pointer 将整数转换为指针，Invalid conversions of uintptr to unsafe.Pointer 代码检查会发出警告。

Unmarshal is called with incorrect argument 检查可以分析对 json.Unmarshal 以及 encoding/json、encoding/xml 和 encoding/gob 包的类似函数的调用。

Locks mistakenly passed by value 代码检查可帮助您避免意外复制包含锁定的值。

## 实时模板

添加了新模板来帮助您快速创建声明组。 其中包括 consts、vars、types 和 imports。 当您使用这些模板之一时，GoLand 将在声明名称周围添加大括号。

fori 模板可为经典的 for 循环插入样板代码。

## 重构

Extract Method 重构会保留父函数和方法参数的原始顺序。Rename 重构现在会自动检测声明的重命名。 这意味着当您手动重命名声明时，IDE 将显示一个间距图标，此图标会建议重命名其所有用法。

## 导航

Navigate to implementations（macOS 上为 ⌥⌘B，Windows/Linux 上为 Ctrl+Alt+B）和 Navigate to Declaration 或 Usages（macOS 上为 ⌘B，Windows/Linux 上为 Ctrl+B）现在会首先显示当前项目中的结果。

此外，默认情况下，Find Usages（Windows/Linux 上为 Alt+F7，macOS 上为 ⌥F7）操作现在会始终查找接口方法的用法。 要像以前一样查找当前方法的用法，请在 Windows/Linux 上使用 Alt+Shift+Ctrl+F7 或在 macOS 上使用 ⌥⇧⌘F7。

## 改进 VCS

1）新 Commit 工具窗口

现在，新的 Commit 工具窗口包含 *Local Changes* 和 *Shelf* 选项卡。 此工具窗口涵盖了与提交有关的所有任务，例如检查差异，选择要提交的文件和块，以及输入提交消息。 Commit 是位于屏幕左侧的垂直工具窗口，这样就为整个编辑器留出了显示差异的空间。

2）改进了 Branches 弹出窗口

*Branches* 弹出窗口在多个方面进行了重新设计：

- 我们添加了一个显式搜索字段，您可以借助此字段查找现有的远程和本地分支。
- 现在，您可以使用 *Refresh* 按钮更新现有的远程分支。
- 传入（蓝色）和传出（绿色）提交指示器已添加到状态栏。

3）Interactively Rebase from Here 对话框

大幅重新设计了 Interactively Rebase from Here。 您可以利用此对话框编辑、组合及移除之前的提交，从而让您的提交历史记录更加清晰易懂。

要调用此对话框，请转到 Git 工具窗口的 Log 选项卡，在要编辑的一系列提交中选择最旧的提交，点击右键，然后选择 Interactively Rebase from Here。

## 数据库更新

- 使用 *Run configurations* 运行脚本文件和代码段。 这样，您可以在启动前一次运行多个文件，对它们进行重新排序，添加新文件以及运行其他程序或配置。
- 现在，您可以在代码编辑器中查看结果。 默认情况下，此选项处于禁用状态。 要启用此功能，请转到 *Settings/Preferences | Database | General | Show output results in the editor*。
- 创建 SSH 隧道的配置，并在许多数据源或项目中使用。
- 我们添加了以 Excel 格式导出数据的功能。
- 另外，您也可以在提取程序下拉列表中选择首选数据格式。

## Web开发

1）用于 JavaScript 和 TypeScript 的新智能意图和检查

使用新的智能意图和检查 (Alt+Enter) 可在编码时节省时间！ 例如，您现在可以快速地将现有代码转换为可选链和/或空值合并，该语法已在最新版本的 JavaScript 和 TypeScript 中引入。

2）更有帮助的快速文档

对于 JavaScript 和 TypeScript，*Documentation* 弹出窗口现在会显示更多有用的信息，包括符号类型和可视性的详细信息以及定义符号的位置。

## 其他变更

- JetBrains 的新字体 *JetBrains Mono* 默认可用。 要详细了解该字体，请访问[此页面](https://www.jetbrains.com/lp/mono/)。
- 默认捆绑了 *Grazie*，此插件可为您在 IDE 中编写的文本提供智能的拼写和语法检查。
- 新的 *LightEdit 模式*允许您在文本编辑器中打开文件，而无需创建或加载项目。 要试用此这一功能，您首先需要从 *Tools | Create Command-line Launcher* 创建命令行启动器，如[此处](https://www.jetbrains.com/help/idea/working-with-the-ide-features-from-command-line.html)所述（如果您使用的是 Toolbox App，步骤[略有不同](https://www.jetbrains.com/help/idea/working-with-the-ide-features-from-command-line.html#toolbox)）。 有关如何打开文件、比较/合并文件甚至运行代码检查的详细说明，请参阅[此 Web 帮助部分](https://www.jetbrains.com/help/idea/opening-files-from-command-line.html)。
- 我们添加了新的 *Zen 模式*，它消除了可能的干扰，可帮助您完全专注于代码。 本质上，此模式结合了*免打扰模式*和*全屏模式*。 要启用此模式，请转到 *View | Appearance | Enter Zen Mod*，或者从 *Quick Switch Scheme* 弹出窗口中选择 (*Ctrl+` | View mode | Enter Zen Mode*)。
- *外部文档*现在指向 [https://pkg.go.dev](https://pkg.go.dev/) 而不是 [https://godoc.org](https://godoc.org/)。
- 我们恢复了*默认*配色方案，但采用新名称 *Classic Light*。

## 结语

新版本可以免费试用 30 天。新版本下载地址：<https://www.jetbrains.com/zh-cn/go/download/>。该下载页面支持通过微信和支付宝支付。

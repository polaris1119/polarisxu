---
title: "Go1.18 快讯：Module 工作区模式"
date: 2021-11-10T22:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Workspace
---

大家好，我是 polarisxu。

工作区模式（Workspace mode），可不是之前 GOPATH 时代的 Workspace，而是希望在本地开发时支持多 Module。

## 01 缘起

为了大家全面理解工作区模式，通过一个具体例子讲解。

本地有两个项目，分别是两个 module：mypkg 和 example。（Windows 系统请按自己方式创建目录）

```bash
$ cd ~/
$ mkdir polarisxu
$ cd polarisxu
$ mkdir mypkg example
$ cd mypkg
$ go mod init github.com/polaris1119/mypkg
$ touch bar.go
```

在 bar.go 中增加如下示例代码：

```go
package mypkg

func Bar() {
	println("This is package mypkg")
}
```

接着，在 example 模块中处理：

```bash
$ cd ~/polarisxu/example
$ go mod init github.com/polaris1119/example
$ touch main.go
```

在 main.go 中增加如下内容：

```go
package main

import (
    "github.com/polaris1119/mypkg"
)

func main() {
    mypkg.Bar()
}
```

这时候，如果我们运行 go mod tidy，肯定会报错，因为我们的 mypkg 包根本没有提交到 github 上，肯定找不到。

```bash
fatal: repository 'https://github.com/polaris1119/mypkg/' not found
```

go run main.go 也就不成功。

我们当然可以提交 mypkg 到 github，但我们每修改一次 mypkg，就需要提交，否则 example 中就没法使用上最新的。

针对这种情况，目前是建议通过 replace 来解决，即在 example 中的 go.mod 增加如下 replace：（v1.0.0 根据具体情况修改，还未提交，可以使用 v1.0.0）

```bash
module github.com/polaris1119/example

go 1.17

require github.com/polaris1119/mypkg v1.0.0

replace github.com/polaris1119/mypkg => ../mypkg
```

再次运行 go run main.go，输出如下：

```bash
$ go run main.go
This is package mypkg
```

当都开发完成时，我们需要手动删除 replace，并执行 go mod tidy 后提交，否则别人使用就报错了。

这还是挺不方便的，如果本地有多个 module，每一个都得这么处理。

## 02 工作区模式

针对上面的这个问题，Michael Matloob 提出了 Workspace Mode（工作区模式）。相关 issue 讨论：[cmd/go: add a workspace mode](https://github.com/golang/go/issues/45713)，[这里是 Proposal](https://go.googlesource.com/proposal/+/master/design/45713-workspace.md)。

为了能够试验工作区，请在本地使用 Go1.18beta2，建议[通过 goup 切换 Go 版本](https://mp.weixin.qq.com/s/yTblk9Js1Zcq5aWVcYGjOA)：

```bash
$ goup install 1.18beta2
$ goup show
|  VERSION  | ACTIVE |
|-----------|--------|
|   1.0.1   |        |
|    1.1    |        |
|  1.10.8   |        |
|  1.14.9   |        |
|  1.15.2   |        |
|  1.15.3   |        |
|  1.15.4   |        |
|   1.16    |        |
|  1.16.2   |        |
|   1.17    |        |
| 1.18beta2 |   *    |
|    1.4    |        |
|   1.4.3   |        |
|    tip    |        |
```

我本地当前版本：

```bash
$ go version
go version go1.18beta2 darwin/amd64
```

通过 go help work 可以看到 work 相关命令：

```bash
$ go help work
Go workspace provides access to operations on workspaces.

Note that support for workspaces is built into many other commands, not
just 'go work'.

See 'go help modules' for information about Go's module system of which
workspaces are a part.

A workspace is specified by a go.work file that specifies a set of
module directories with the "use" directive. These modules are used as
root modules by the go command for builds and related operations.  A
workspace that does not specify modules to be used cannot be used to do
builds from local modules.

go.work files are line-oriented. Each line holds a single directive,
made up of a keyword followed by aruments. For example:

	go 1.18

	use ../foo/bar
	use ./baz

	replace example.com/foo v1.2.3 => example.com/bar v1.4.5

The leading keyword can be factored out of adjacent lines to create a block,
like in Go imports.

	use (
	  ../foo/bar
	  ./baz
	)

The use directive specifies a module to be included in the workspace's
set of main modules. The argument to the use directive is the directory
containing the module's go.mod file.

The go directive specifies the version of Go the file was written at. It
is possible there may be future changes in the semantics of workspaces
that could be controlled by this version, but for now the version
specified has no effect.

The replace directive has the same syntax as the replace directive in a
go.mod file and takes precedence over replaces in go.mod files.  It is
primarily intended to override conflicting replaces in different workspace
modules.

To determine whether the go command is operating in workspace mode, use
the "go env GOWORK" command. This will specify the workspace file being
used.

Usage:

	go work <command> [arguments]

The commands are:

	edit        edit go.work from tools or scripts
	init        initialize workspace file
	sync        sync workspace build list to modules
	use         add modules to workspace file

Use "go help work <command>" for more information about a command.
```

根据这个提示，我们初始化 workspace：

```bash
$ cd ~/polarisxu
$ go work init mypkg example
$ tree
.
├── example
│   ├── go.mod
│   └── main.go
├── go.work
└── mypkg
    ├── bar.go
    └── go.mod
```

注意几点：

- 多个子模块应该在一个目录下。比如这里的 polarisxu 目录；（这不是必须的，但更好管理，否则 go work init 需要提供正确的子模块路径）
- go work init 需要在 polarisxu 目录执行；
- go work init 之后跟上需要本地开发的子模块目录名；

打开 go.work 看看长什么样：

```bash
go 1.18

use (
	./example
 	./mypkg
)
```

go.work 文件的语法和 go.mod 类似，因此也支持 replace。

现在，我们将 example/go.mod 中的 replace 语句删除，再次执行 go run main.go（在 example 目录下），得到了正常的输出。也可以在 polarisxu 目录下，这么运行：go run example/main.go，也能正常。

注意，go.work 不需要提交到 Git 中，因为它只是你本地开发使用的。

如果想要禁用 workspace，可以通过 `-workfile=off` 实现。

```bash
-workfile file
		in module aware mode, use the given go.work file as a workspace file.
		By default or when -workfile is "auto", the go command searches for a
		file named go.work in the current directory and then containing directories
		until one is found. If a valid go.work file is found, the modules
		specified will collectively be used as the main modules. If -workfile
		is "off", or a go.work file is not found in "auto" mode, workspace
		mode is disabled.
```

比如：go run -workfile=off main.go 或 go build -workfile=off，这样运行你会发现又报错了。但通过这种方式，你可以验证依赖包提交到 github 上之后的情况。

## 03 总结

在 GOPATH 年代，多 GOPATH 是一个头疼的问题。当时没有很好的解决，Module 就出现了，多 GOPATH 问题因此消失。但多 Module 问题随之出现。Workspace 方案较好的解决了这个问题。

下篇文章，我会进一步讲解，如何在 VSCode 中试验 Workspace。

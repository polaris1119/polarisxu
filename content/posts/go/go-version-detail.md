---
title: "发现 go version 的一个另类用法：你肯定想不到"
date: 2021-03-19T17:50:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 版本
---

大家好，我是站长 polarisxu。

对于 go version，大家应该不陌生。在很多入门教程，安装 Go 后，一般会建议执行 go version 看看是否安装成功；亦或遇到问题，别人会问你 Go 哪个版本，你也会通过 go version 命令查看。所以，go version 的一个作用是查看本地使用的 Go 版本。

但实际上，go version 还有其他用途，甚至可以说，输出本地 Go 版本号只是它功能的一个特例。先 go help version 看看：

```bash
$ go help version
usage: go version [-m] [-v] [file ...]

Version prints the build information for Go executables.

Go version reports the Go version used to build each of the named
executable files.

If no files are named on the command line, go version prints its own
version information.

If a directory is named, go version walks that directory, recursively,
looking for recognized Go binaries and reporting their versions.
By default, go version does not report unrecognized files found
during a directory scan. The -v flag causes it to report unrecognized files.

The -m flag causes go version to print each executable's embedded
module version information, when available. In the output, the module
information consists of multiple lines following the version line, each
indented by a leading tab character.

See also: go doc runtime/debug.BuildInfo.
```

可见这个命令主要是用于输出 Go 可执行文件的编译信息的，只是如果没有提供可执行文件，则输出当前安装的 Go 版本信息。

我们通过一个具体例子来看看 -v、-m 的作用。

## 01 初始化例子

创建一个 go module 和如下目录结构：

```bash
$ go mod init github.com/polaris1119/gopher

$ tree .
.
├── cmd
│   ├── bar
│   │   └── main.go
│   └── foo
│       └── main.go
└── go.mod
```

其中 main.go 就是一个简单的 Hello World。执行 go install 安装。

```bash
$ export GOBIN=~/gopher/bin
$ go install github.com/polaris1119/gopher/cmd/...
```

- export GOBIN 是为了将编译的结果放在当前目录的 bin 目录下，而不是默认的 `$GOPATH/bin` 下

成功后，执行 go version bin：

```bash
$ go version bin
bin/bar: go1.16.2
bin/foo: go1.16.2
```

而我本地的版本是 1.16.2。可见 `go version [file …]` 后的 file 可以是目录，这时会递归输出里面的文件的 Go 版本信息。

## 02 -v 选项

我们在 bin 目录下增加一个文本文件 api.txt 和一个可执行文件（php）。

```bash
$ tree bin
bin
├── api.txt
├── bar
├── foo
└── php
```

再次运行 go version：

```bash
$ go version bin
bin/bar: go1.16.2
bin/foo: go1.16.2
```

结果一样。试试加上 -v 参数。

```bash
$ go version -v bin
bin/api.txt: not executable file
bin/bar: go1.16.2
bin/foo: go1.16.2
bin/php: go version not found
```

可见 -v 参数能够输出无法识别的文件。

## 03 -m 选项

加上 -m 选项执行：（只看单个二进制文件，也可以跟上面一样是目录）

```bash
$ go version -m bin/foo
bin/foo: go1.16.2
	path	github.com/polaris1119/gopher/cmd/foo
	mod	github.com/polaris1119/gopher	(devel)
```

显示出当前二进制包路径和 mod 信息：包名和 devel。devel 表示这个二进制是开发版本。比如我们安装了 dlv，可以看看它的 Go 版本信息：（以下是我本地之前安装的）

```bash
$ go version -m ~/go/bin/dlv
/Users/xuxinhua/go/bin/dlv: go1.16beta1
	path	github.com/go-delve/delve/cmd/dlv
	mod	github.com/go-delve/delve	v1.6.0	h1:NImdy7K9essqNU8sazLhbX/oCicpmlapmjgA3qL1LZM=
	。。。
```

它没有 devel，而是具体的版本号（这里是 v1.6.0），`h1:NImdy7K9essqNU8sazLhbX/oCicpmlapmjgA3qL1LZM=` 这一串和 go.sum 中是一样的，`h1:` 是固定的，后面一串是 hash，是 Go modules 将目标模块版本的 zip 文件解包后，针对所有包内文件依次进行 hash，然后再把它们的 hash 结果按照固定格式和算法生成总的 hash 值。

下面，我们修改一下 cmd/foo/main.go 文件：（如果没有引入依赖，可以 go mod tidy 引入下）

```go
package main

import (
  "fmt"
  "github.com/polaris1119/foo"
)

func main() {
	fmt.Println(foo.Bar())
}
```

然后 go install 安装：

```bash
$ go install github.com/polaris1119/gopher/cmd/...
```

再次 -m 选项看看：

```bash
$ go version -m bin/foo
bin/foo: go1.16.2
	path	github.com/polaris1119/gopher/cmd/foo
	mod	github.com/polaris1119/gopher	(devel)
	dep	github.com/polaris1119/foo	v0.4.0	h1:fgXsULdtXQmElR8Qor10s29CQbeA1pjSa/Cj0kB2Aas=
```

dep 表明该二进制程序依赖了 github.com/polaris1119/foo 这个包，版本是 v0.4.0 ，h1 hash 是 fgXsULdtXQmElR8Qor10s29CQbeA1pjSa/Cj0kB2Aas=，这个信息和 go.mod 中是一致的。

## 04 总结

现在如果有一个 Go 语言实现的二进制程序，我们可以通过 go version 命令分析出它使用的 Go 版本信息，以及依赖包的信息。有些时候也许需要了解这些信息。
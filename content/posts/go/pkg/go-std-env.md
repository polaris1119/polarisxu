---
title: "Go 如何获取和设置环境变量"
date: 2021-10-29T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 环境变量
---

大家好，我是 polarisxu。

今天的文章比较基础，但却是必须掌握的，而且本文有些内容，也许你之前没想过。希望这篇文章能够让你理解环境变量并掌握 Go 环境变量相关操作。

## 01 从安装 Go 说起

其实不止是安装 Go，其他语言一本也会有类似的问题。一般来说，安装完 Go 后，会建议将 go 可执行程序配置到 PATH 环境变量中。

比如我本地的 PATH 环境变量的值：

```bash
$ echo $PATH
/Users/xuxinhua/.go/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Wireshark.app/Contents/MacOS:/Users/xuxinhua/.cargo/bin:/Users/xuxinhua/bin:/usr/local/git/bin:/Users/xuxinhua/.composer/vendor/bin:/Users/xuxinhua/go/bin
```

那么 PATH 环境变量的作用是什么呢？

简单一句话就是，让你在终端执行命令时，不需要输入绝对路径。比如 Go 安装在了 `~/.go/bin` 目录下，如果我们要执行 Go 命令，得类似这样：

```bash
$ ~/.go/bin/go version
```

是不是很麻烦？！但将 `~/.go/bin` 目录加入到 PATH 环境变量后，可以直接这样执行 Go 命令：

```bash
$ go version
```

这就是 PATH 环境变量的作用：告知去哪里查找要执行的命令。

那么环境变量的作用是什么呢？百科上关于环境变量的解释：

> 环境变量（environment variables）一般是指在操作系统中用来指定操作系统运行环境的一些参数，如：临时文件夹位置和系统文件夹位置等。

进程也会有自己的环境变量，一般从父进程继承，也可以人为指定。比如在终端运行某个程序时，可以给它传递环境变量：

```bash
$ NAME=polarisxu ./xxx
```

进程中就可以通过 NAME 获取到 polarisxu 这个值。

环境变量可以说无处不在，很多时候只是我们没有细想而已。

> 注：因为 PATH 环境变量的作用机制，在 Shell、Dockerfile 等中，你需要时刻意识到，PATH 环境变量的值是什么，有没有包含你的命令路径，对于这样的场景，可能更好的办法是写绝对路径，而不是依赖 PATH。

## 02 Go 如何使用环境变量

很多大型应用程序，会使用环境变量进行配置（当然也支持其他方式配置，比如 flag）。作为配置选项的环境变量大大简化了应用程序的部署。这些在云基础设施中也很常见。

通常，基于环境变量的配置，如果环境变量没设置，程序会有一个默认值。

在 Go 语言中，和环境变量相关的 API 主要在 os 包中。下面的 API 都加上了注释。

```go
// Environ 以 key=value 的形式返回所有环境变量。
func Environ() []string
// ExpandEnv 根据当前环境变量的值替换字符串中的 ${var} 或 $var。
// 对未定义变量的引用将被空字符串替换。
func ExpandEnv(s string) string
// Getenv 检索 key 这个键对应的环境变量的值。
// 如果该环境变量不存在，返回空字符串。
// 要区分空值和未设置值，请使用 LookupEnv。
func Getenv(key string) string
// LookupEnv 检索 key 这个键对应的环境变量的值。
// 如果该环境变量存在，则返回对应的值(可能为空)，并且布尔值为 true。
// 否则，返回值将为空，布尔值将为 false。
func LookupEnv(key string) (string, bool)
// Setenv 设置 key 这个键对应的环境变量的值。
// 如果出错会返回错误。
func Setenv(key, value string) error
// Unsetenv 取消设置单个环境变量。
func Unsetenv(key string) error
// Clearenv 将删除所有环境变量。
func Clearenv()
```

此外，os/exec 中有一个 LookPath 函数，和 PATH 环境变量有关：

```go
// 在 PATH 环境变量对应的目录中搜索名为 file 的可执行文件。
// 如果文件包含 /，则不会搜索 PATH，而是正常路径查找。
// 返回的结果可能是绝对路径或相对于当前目录的相对路径。
func LookPath(file string) (string, error)
```

现在，通过一个例子看看这些 API 如何使用。

```go
// main.go
package main

import (
	"fmt"
  "os"
)

func main() {
  name := os.Getenv("NAME")
  fmt.Println("name is:", name)
}
```

然后运行：

```bash
$ NAME=polarisxu go run main.go
name is: polarisxu
```

如果前面的 `NAME=polarisxu` 没有，则返回的 name 是空字符串。如果希望有默认值，该怎么做？

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    name := GetenvDefault("NAME", "xuxinhua")
    fmt.Println("name is:", name)
}

func GetenvDefault(key, defVal string) string {
    val, ok := os.LookupEnv(key)
    if ok {
        return val
    }
    return defVal
}
```

通过 os.LookupEnv 可以得到是否设置了环境变量。这时运行 go run main.go 的结果会是：`name is: xuxinhua`。

以上就是 Go 中会常用到获取环境变量的 API。

其他 API，用到的可能性不大。有两个 API 值得提一下：Environ() 和 ExpandEnv()。

前面提到过，进程会从父进程继承环境变量。这里最重要的就是 PATH 环境变量。有时候，我们通过 os/exec 包执行外部程序时，可能会提示找不到命令，这时需要确认 PATH 是否正确。可能 Shell 下 PATH 包含了命令所在目录，但进程可能没包含，我们可以在程序中输出所有环境变量：

```go
envs := os.Environ()
for _, env := range envs {
  fmt.Println(env)
}
```

一行是一个完整的环境变量，比如 `LANG=zh_CN.UTF-8`。

再看下 ExpandEnv() 函数。有以下代码：（省略 main 相关其他代码）

```go
host := os.ExpandEnv("127.0.0.1:$PORT")
fmt.Println(host)
```

`IP:PORT` 的形式是常见的，通常，我们会做字符串拼接：`host + ":" + port`，有了 os.ExpandEnv，不需要进行拼接了，它会将 `$PORT` 替换为 `os.Getenv("PORT")` 的值。

## 03 小结

环境变量你会用了吗？

本文没有通过代码试验的其他函数，建议你可以写代码试试，比如看看 os.Clearenv、os.Unsetenv 能不能删除环境变量。

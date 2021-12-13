---
title: "Go：如何获得项目根目录？"
date: 2021-10-31T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 标准库
---

大家好，我是 polarisxu。

项目中，特别是 Web 项目，经常需要获得项目的根目录，进而可以访问到项目相关的其他资源，比如配置文件、静态资源文件、模板文件、数据文件、日志文件等（Go1.16 后，有些可以方便的通过 embed 内嵌进来）。比如下面的目录结构：（路径是 `/Users/xuxinhua/stdcwd`）

```bash
├── bin
    ├── cwd
├── main.go
└── log
    ├── error.log
```

为了正确读取 error.log，我们需要获得项目根目录。学完本文知识可以解决该问题。

解决方案有多种，各有优缺点和使用注意事项，选择你喜欢的即可。

## 01 使用 os.Getwd

Go 语言标准库 os 中有一个函数 `Getwd`：

```go
func Getwd() (dir string, err error)
```

它返回当前工作目录。

基于此，我们可以得到项目根目录。还是上面的目录结构，切换到 /Users/xuxinhua/stdcwd，然后执行程序：

```bash
$ cd /Users/xuxinhua/stdcwd
$ bin/cwd
```

这时，当前目录（os.Getwd 的返回值）就是 `/Users/xuxinhua/stdcwd`。

但是，如果我们不在这个目录执行的 bin/cwd，当前目录就变了。因此，这不是一种好的方式。

不过，我们可以要求必须在 `/Users/xuxinhua/stdcwd` 目录运行程序，否则报错，具体怎么做到限制，留给你思考。

## 02 使用 exec.LookPath

在上面的目录结构中，如果我们能够获得程序 cwd 所在目录，也就相当于获得了项目根目录。

```go
binary, err := exec.LookPath(os.Args[0])
```

os.Args[0] 是当前程序名。如果我们在项目根目录执行程序 `bin/cwd`，以上程序返回的 binary 结果是 `bin/cwd`，即程序 cwd 的相对路径，可以通过 filepath.Abs() 函数得到绝对路径，最后通过调用两次 filepath.Dir 得到项目根目录。

```go
binary, _ := exec.LookPath(os.Args[0])
root := filepath.Dir(filepath.Dir(filepath.Abs(binary)))
```

## 03 使用 os.Executable

可能是类似的需求很常见，Go 在 1.8 专门为这样的需求增加了一个函数：

```go
// Executable returns the path name for the executable that started the current process.
// There is no guarantee that the path is still pointing to the correct executable.
// If a symlink was used to start the process, depending on the operating system, the result might be the symlink or the path it pointed to.
// If a stable result is needed, path/filepath.EvalSymlinks might help.
// Executable returns an absolute path unless an error occurred.
// The main use case is finding resources located relative to an executable.
func Executable() (string, error)
```

和 exec.LookPath 类似，不过该函数返回的结果是绝对路径。因此，不需要经过 filepath.Abs 处理。

```go
binary, _ := os.Executable()
root := filepath.Dir(filepath.Dir(binary))
```

> 注意，exec.LookPath 和 os.Executable 的结果都是可执行程序的路径，包括可执行程序本身，比如 /Users/xuxinhua/stdcwd/bin/cwd

细心的读者可能会注意到该函数注释中提到符号链接问题，为了获得稳定的结果，我们应该借助 filepath.EvalSymlinks 进行处理。

```go
package main

import (
    "fmt"
    "os"
    "path/filepath"
)

func main() {
    ex, err := os.Executable()
    if err != nil {
        panic(err)
    }
    exPath := filepath.Dir(ex)
    realPath, err := filepath.EvalSymlinks(exPath)
    if err != nil {
        panic(err)
    }
    fmt.Println(filepath.Dir(realPath))
}
```

最后输出的就是项目根目录。（如果你的可执行文件放在根目录下，最后的 filepath.Dir 就不需要了）

> 注意：exec.LookPath 也有软链接的问题。

exec.LookPath 和 os.Executable 函数，再提醒一点，如果使用 go run 方式运行，结果会是临时文件。因此，记得先编译（这也是比 go run 更好的方式，go run 应该只是用来本地测试）。

## 04 小结

既然 Go1.8 为我们专门提供了这样一个函数，针对本文提到的场景，我们应该总是使用它。

你用的什么方式呢？欢迎留言交流。


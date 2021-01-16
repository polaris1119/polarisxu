---
title: "Go 1.16 的这个新变化需要适应下：go get 和 go install 的变化"
date: 2020-12-27T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 1.16
  - 安装
---

大家好，我是站长 polarisxu。

一直以来，我们通常都是通过 `go get` 来下载并安装包的。但从 Go 1.16 起，不推荐通过 go get 来安装包（主要是说安装可执行文件），也就是说，go get 应该只是用来下载包，而且将来版本可能会给该命令始终加上 `-d` 标志。 你可能会问，这对我使用有什么影响呢？

让我们看一个实际的例子。

## 01 安装 Delve 的例子

我们在本地通过源码安装 Go 的调试器 Delve，可以这么做：

```bash
$ go get github.com/go-delve/delve/cmd/dlv
```

因为 go get 会下载、编译并安装包（如果有 main 包）。

Go 1.16 建议这么使用 go get：

```bash
$ go get -d github.com/go-delve/delve/cmd/dlv
```

这只会下载 delve，并不会构建和安装，而且将来 go get 只会用来下载。因此，你还需要手动执行安装。

## 02 go install 的变化

### GOPATH 年代

早在 GOPATH 年代，go install 的作用如下：

```bash
Install compiles and installs the packages named by the import paths.

The -i flag installs the dependencies of the named packages as well.
```

也就是说，go install 会将包编译成 `.a` 文件并安装到 `$GOPATH/pkg/$GOOS_$GOARCH` 下；如果是 main 包，会编译并生成可执行文件安装到 `$GOPATH/bin` 目录下（如果设置了 `$GOBIN`，则会安装到 `$GOBIN` 下 ）。这也是和 go build 不同之处。

### Go Module 年代

到了 Go Module 年代，情况发生了变化。大家似乎完全忘记了 go install 的存在（也有可能在 GOPATH 年代，大家就从来不用 go install），因为 go get、go build 就解决问题了。

特别是，从 Go Module 开始，工作目录没有了 src/pkg/bin 这三个目录，使得 go build 比 go install 更受欢迎。（GOPATH 年代，我更喜欢 go install，因为它会在项目生成和 GOROOT 一样的 src/pkg/bin，保持一致）。

看看 Module 年代，go install 命令的作用：（基于 Go1.15.x）

```bash
Install compiles and installs the packages named by the import paths.

Executables are installed in the directory named by the GOBIN environment
variable, which defaults to $GOPATH/bin or $HOME/go/bin if the GOPATH
environment variable is not set. Executables in $GOROOT
are installed in $GOROOT/bin or $GOTOOLDIR instead of $GOBIN.

When module-aware mode is disabled, other packages are installed in the
directory $GOPATH/pkg/$GOOS_$GOARCH. When module-aware mode is enabled,
other packages are built and cached but not installed.

The -i flag installs the dependencies of the named packages as well.
```

Module 没启用时，和 GOPATH 年代的作用是一样的。当启用 Module 模式时，go install 对普通包（非 main 包）不再安装（即没有了 `pkg/$GOOS_$GOARCH`），这和 go build 一样了。而对于 main 包，会将生成的可执行文件安装到 `$GOBIN` 目录下（`$GOBIN` 的默认值是 `$GOPATH/bin`，如果 `$GOPATH` 没有设置，则是 `$HOME/go/bin`）。

那么，Module 模式下，什么情况下你可能会使用 go install 呢？

如果你有这样的习惯会使用 go install。

> $GOBIN 在 PATH 环境变量下，这样，GOBIN 下面的可执行文件可以方便的运行。比如你的工作 module 是：github.com/polaris1119/test ，可以通过 `go install github.com/polaris1119/test` 将 test 安装到 GOBIN 下，然后直接执行 test 运行。

### Go 1.16 及以后

从 Go 1.16 起，go install 可以接受带有版本后缀的参数（例如 go install example.com/cmd@v1.0.0）。这将导致 go install 以模块感知模式构建和安装包，而忽略当前目录或任何父目录（如果有）中的 go.mod 文件。这对于在不影响主模块依赖性的情况下安装可执行文件很有用。

如本文开头提到的，go get 不建议用来构建和安装包了。

所以，Go 1.16 及以后，go get 和 go install 应该什么时候使用呢？

- 如果要安装第三方库的可执行文件，比如上面的 Delve，使用 go install，但需要带上版本后缀，比如 @latest；（不清楚为什么设计成必须带上版本号）
- 普通的库，继续使用 go get，建议加上 -d 标志；

注意，虽然 go install 一个普通的第三方包（不过必须带上版本后缀）也会下载对应的包，但不会修改 go.mod，这和 go get 是不同的。

## 03 总结

总结一下这个变化：（Go 1.16 还不会有影响，将来就会有影响，所以可以提前习惯下）

- 日常的开发，还和之前一样使用 go get 即可；
- 但如果是要源码安装一些第三方可执行文件，比如 vscode-go 插件依赖的可执行文件，则应该使用 go install；
- 如果你本地编译习惯了我文中提到的方式，继续使用 go install 即可，虽然绝大部分人喜欢使用 go build。
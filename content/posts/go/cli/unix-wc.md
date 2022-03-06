---
title: "用 Go 构建一个类似 Unix 的 wc 工具"
date: 2022-02-05T22:00:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - Go
  - Unix
  - wc
---

大家好，我是 polarisxu。

Go 官方 2020 年调查报告显示，有 65% 的用户使用 Go 构建 CLI 工具，排名第二：

![Bar chart of Go use cases from 2019 to 2020 including API or RPC services, CLIs, frameworks, web services, automation, agents and daemons, data processing, GUIs, games and mobile apps](https://go.dev/blog/survey2020/app_yoy.svg)

GitHub 上也有各种 CLI 相关项目，也有不少 Unix 常用工具的轮子，有些不是简单的轮子，是比之前更好的轮子。

新手学习 Go，总是苦恼没有项目实战，其实有很多轮子可以练习。为了带大家一起更好地实战 Go，我计划造一些 Unix 工具轮子，因为是为了练习，这些轮子不一定会像原工具那么强大，但如果你有兴趣，完全可以完善得更强大。

由于不同类 Unix 系统的工具功能有一些差异，为了方便，本文统一按照 Linux 版本来设计。使用的 Go 版本是 Go1.17.x。

今天开始第一个工具：wc（word count）。

## 1、了解 wc

要用 Go 实现一个 wc 工具，先要了解 wc 工具。

在 Linux 系统执行 man wc，可以看到如下帮助文档：

```bash
NAME
       wc - print newline, word, and byte counts for each file

SYNOPSIS
       wc [OPTION]... [FILE]...
       wc [OPTION]... --files0-from=F

DESCRIPTION
       Print newline, word, and byte counts for each FILE, and a total line if more than one FILE
       is specified.  A word is a non-zero-length  sequence  of  characters  delimited  by  white
       space.

       With no FILE, or when FILE is -, read standard input.

       The  options below may be used to select which counts are printed, always in the following
       order: newline, word, character, byte, maximum line length.

       -c, --bytes
              print the byte counts

       -m, --chars
              print the character counts

       -l, --lines
              print the newline counts

       --files0-from=F
              read input from the files specified by NUL-terminated names in file F; If  F  is  -
              then read names from standard input

       -L, --max-line-length
              print the maximum display width

       -w, --words
              print the word counts

       --help display this help and exit

       --version
              output version information and exit
```

wc 工具的功能是统计指定的文件中字节数（字符）、字数、行数，并将统计结果输出。

如果是 Mac（BSD），看到的帮助会有所区别，参数的解释更详细：

```bash
-c      The number of bytes in each input file is written to the standard output.
        This will cancel out any prior usage of the -m option.

-l      The number of lines in each input file is written to the standard output.

-m      The number of characters in each input file is written to the standard out-
        put.  If the current locale does not support multibyte characters, this is
        equivalent to the -c option.  This will cancel out any prior usage of the -c
        option.

-w      The number of words in each input file is written to the standard output.
```

不过它们的行为有些许差异。我们实现的版本以 Linux 版为准。

但我们的版本只会实现 BSD（Mac）中的这四个选项，Linux 版本的其他选项忽略，同时只实现这些选项独立的功能。

看两个 wc 应用的例子。

**1）统计文件信息**

创建一个文件 polarisxu.txt，填入如下内容：

```bash
a b c
d e 中
```

接着执行 wc 命令：

```bash
$ wc polarisxu.txt
 2  6 14 polarisxu.txt
```

2 6 14 这四个数字分别是 2 lines、6 words 和 14 bytes（因为 polarisxu.txt 文件是 UTF-8 编码，中占 3 个字节）。可见，默认没有输出字符数。

我们可以把四个选项都带上，看看结果：

```bash
$ wc -mlcw polarisxu.txt
 2  6 12 14 polarisxu.txt
```

其中的 12 就是字符数。

**2）日志统计**

在日志统计中，wc 经常会用到。一般是经过 grep、awk 等处理后，通过管道的方式接上 wc，统计行数，因此常用的是 `wc -l`。比如统计 polarisxu.txt 行数：

```bash
$ cat polarisxu.txt | wc -l
2
```

## 2、Go 语言实现 wc

计划将 Go 实现的 cli 工具都放在 <https://github.com/polaris1119/sak> 上。建议你创建自己的仓库试验。

先初始化项目：

```bash
$ go mod init github.com/polaris1119/sak
```

然后创建 wc 的目录，并在其中创建 main.go 文件：

```bash
$ mkdir -p cmd/wc
$ cd cmd/wc
$ touch main.go
```

用你喜欢的编辑器开始编码吧。（推荐 VSCode 或 GoLand）

先从最简单的形式开始：从标准输入读取。以下是代码框架：

```go
package main

import (
	"fmt"
	"io"
	"os"
)

func main() {
	fmt.Println(count(os.Stdin))
}

// count 从 io.Reader 中读取数据，统计相关数据
func count(r io.Reader) int {
	wc := 0

	return wc
}
```

先实现统计字数（words）。标准库 bufio 包有一个结构体类型 Scanner，可以很好地满足统计需求。

关于 Scanner 的相关讲解可以参考我写的开源图书：[《Go 语言标准库》](https://books.studygolang.com/The-Golang-Standard-Library-by-Example/chapter01/01.4.html#142-scanner-%E7%B1%BB%E5%9E%8B%E5%92%8C%E6%96%B9%E6%B3%95)。

```go
func count(r io.Reader) int {
	scanner := bufio.NewScanner(r)
	scanner.Split(bufio.ScanWords)

	wc := 0

	for scanner.Scan() {
		wc++
	}

	return wc
}
```

因为 Scanner 默认的分隔符是换行，这里改为 bufio.ScanWords，即单词（words），代码很简单。

### 验证正确性

可以执行运行代码，看看效果：

```bash
$ echo "a b 中" |  go run ./cmd/wc/main.go
3
```

但更正式的应该是写单元测试。

在 cmd/wc 目录下创建 main_test.go 文件，内容如下：

```go
package main

import (
	"bytes"
	"testing"
)

func TestCountWords(t *testing.T) {
	tests := []struct {
		input    string
		expected int
	}{
		{"a b 中", 3},
		{"polarisxu studygolang", 2},
		{"polarisxu Go 语言 中文网", 4},
	}

	var b = new(bytes.Buffer)
	for _, tt := range tests {
		b.Reset()
		b.WriteString(tt.input)
		if got := count(b); got != tt.expected {
			t.Errorf("count() = %v, want %v", got, tt.expected)
		}
	}
}
```

通过 go test 执行测试：

```bash
$ go test -v ./cmd/wc
=== RUN   TestCountWords
--- PASS: TestCountWords (0.00s)
PASS
ok  	github.com/polaris1119/sak/cmd/wc	0.334s
```

### 增加选项（flag）

接下来增加选项的支持（即 flag）。这里使用标准库 flag 实现。增加如下代码：

```go
var (
	cFlag bool
	lFlag bool
	mFlag bool
	wFlag bool
)

func init() {
	flag.BoolVar(&cFlag, "c", false, `The number of bytes in each input file is written to the standard output.`)
	flag.BoolVar(&lFlag, "l", false, `The number of lines in each input file is written to the standard output.`)
	flag.BoolVar(&mFlag, "m", false, `The number of characters in each input file is written to the standard output.`)
	flag.BoolVar(&wFlag, "w", false, `The number of words in each input file is written to the standard output.`)
}
```

bufio 中的 Scanner 支持不同的分隔方式，刚好 bufio 中定义了四个函数：ScanBytes、ScanLines、ScanRunes 和 ScanWords，刚好对应上面的四个 flag 要实现的功能。

```go
func main() {
	flag.Parse()

	split := bufio.ScanWords
	switch {
	case cFlag:
		split = bufio.ScanBytes
	case lFlag:
		split = bufio.ScanLines
	case mFlag:
		split = bufio.ScanRunes
	case wFlag:
		split = bufio.ScanWords
	}

	fmt.Println(count(os.Stdin, split))
}
```

同时将 count 的签名修改为：

```go
func count(r io.Reader, split bufio.SplitFunc) int
```

这样就支持了各个选项。可以同时完善下单元测试代码，这里不列出了。

## 3、总结

一个简版的 wc 工具就完成了，相比 Linux 的 wc 工具还是差不少。有兴趣的可以接着完善。

此外，这个版本的 wc 不支持从文件读取数据统计，也等着你完善。
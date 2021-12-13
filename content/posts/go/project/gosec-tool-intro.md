---
title: "担心密码提交到 GitHub？建议使用这个 Go 开源工具"
date: 2021-08-10T22:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 工具
---

大家好，我是 polarisxu。

最近跟安全扛上了！这是我分享的 Go 安全相关的第 5 篇文章，前 4 篇文章如下：

- [《Go 团队开始重视安全问题了》](https://mp.weixin.qq.com/s/-Zv1QwM1lYNWEvIoUNjmXQ)
- [《Go Module 有漏洞？免费的 Go 漏洞扫描 VSCode 插件》](https://mp.weixin.qq.com/s/NkxIEoOHXbjgqLPhWsKYRA)
- [《这个工具真好：看看你的Go项目依赖有无漏洞》](https://mp.weixin.qq.com/s/pzCefw0g82f6fNqiW3wqEg)
- [重磅！GitHub 为 Go 社区带来安全支持](https://mp.weixin.qq.com/s/m3VkJU-m_TXnY59ELW12fQ)

今天要分享的这个开源工具，我个人认为更实用，可以当作一个 vet 工具使用，切切实实检查日常开发经常会忽略的安全问题，最常见的，比如将密码提交到 GitHub 上了。。。

这个工具就是 gosec，GitHub 地址：<https://github.com/securego/gosec>，截止目前 Star 数 4.9k+，目测这一波能涨不少~

## 01 简介

这个工具通过扫描 Go 代码的 AST 树来发现安全问题，具体来说，它通过一些规则来检查代码的安全。有专门的官网：<https://securego.io/>。

![gosec](imgs/gosec-logo.png)

## 02 安装

官方提供了几种安装方式。作为一个 Go 程序员，我喜欢使用 go get 或 go install 安装。

> Go1.16 开始，安装可执行 Go 程序使用 go install，下载安装普通库，使用 go get

因为目前最新版本是 v2，因此这么安装：

```bash
$ go install github.com/securego/gosec/v2/cmd/gosec@latest
```

当然，你也可以使用官方编译好的安装：

```bash
# binary will be $(go env GOPATH)/bin/gosec
curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b $(go env GOPATH)/bin vX.Y.Z

# or install it into ./bin/
curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s vX.Y.Z

# In alpine linux (as it does not come with curl by default)
wget -O - -q https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s vX.Y.Z

# If you want to use the checksums provided on the "Releases" page
# then you will have to download a tar.gz file for your operating system instead of a binary file
wget https://github.com/securego/gosec/releases/download/vX.Y.Z/gosec_vX.Y.Z_OS.tar.gz
```

如果你想将其和 CI 工具集成，可以参考和 GitHub Action 的集成方式：

```yaml
name: Run Gosec
on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master
jobs:
  tests:
    runs-on: ubuntu-latest
    env:
      GO111MODULE: on
    steps:
      - name: Checkout Source
        uses: actions/checkout@v2
      - name: Run Gosec Security Scanner
        uses: securego/gosec@master
        with:
          args: ./...
```

## 03 使用和规则介绍

本地安装好后，执行 gosec -h 可以看到使用帮助：（请确保 gosec 在 PATH 环境变量中）

```bash
$ gosec -h

gosec - Golang security checker

gosec analyzes Go source code to look for common programming mistakes that
can lead to security problems.

VERSION: dev
GIT TAG:
BUILD DATE:

USAGE:

	# Check a single package
	$ gosec $GOPATH/src/github.com/example/project

	# Check all packages under the current directory and save results in
	# json format.
	$ gosec -fmt=json -out=results.json ./...

	# Run a specific set of rules (by default all rules will be run):
	$ gosec -include=G101,G203,G401  ./...

	# Run all rules except the provided
	$ gosec -exclude=G101 $GOPATH/src/github.com/example/project/...


OPTIONS:

  -color
    	Prints the text format report with colorization when it goes in the stdout (default true)
  -conf string
    	Path to optional config file
  -confidence string
    	Filter out the issues with a lower confidence than the given value. Valid options are: low, medium, high (default "low")
  -exclude string
    	Comma separated list of rules IDs to exclude. (see rule list)
  -exclude-dir value
    	Exclude folder from scan (can be specified multiple times)
  -fmt string
    	Set output format. Valid options are: json, yaml, csv, junit-xml, html, sonarqube, golint, sarif or text (default "text")
  -include string
    	Comma separated list of rules IDs to include. (see rule list)
  -log string
    	Log messages to file rather than stderr
  -no-fail
    	Do not fail the scanning, even if issues were found
  -nosec
    	Ignores #nosec comments when set
  -nosec-tag string
    	Set an alternative string for #nosec. Some examples: #dontanalyze, #falsepositive
  -out string
    	Set output file for results
  -quiet
    	Only show output when errors are found
  -severity string
    	Filter out the issues with a lower severity than the given value. Valid options are: low, medium, high (default "low")
  -sort
    	Sort issues by severity (default true)
  -stdout
    	Stdout the results as well as write it in the output file
  -tags string
    	Comma separated list of build tags
  -tests
    	Scan tests files
  -verbose string
    	Overrides the output format when stdout the results while saving them in the output file.
    	Valid options are: json, yaml, csv, junit-xml, html, sonarqube, golint, sarif or text
  -version
    	Print version and quit with exit code 0


RULES:

	G101: Look for hardcoded credentials
	G102: Bind to all interfaces
	G103: Audit the use of unsafe block
	G104: Audit errors not checked
	G106: Audit the use of ssh.InsecureIgnoreHostKey function
	G107: Url provided to HTTP request as taint input
	G108: Profiling endpoint is automatically exposed
	G109: Converting strconv.Atoi result to int32/int16
	G110: Detect io.Copy instead of io.CopyN when decompression
	G201: SQL query construction using format string
	G202: SQL query construction using string concatenation
	G203: Use of unescaped data in HTML templates
	G204: Audit use of command execution
	G301: Poor file permissions used when creating a directory
	G302: Poor file permissions used when creation file or using chmod
	G303: Creating tempfile using a predictable path
	G304: File path provided as taint input
	G305: File path traversal when extracting zip archive
	G306: Poor file permissions used when writing to a file
	G307: Unsafe defer call of a method returning an error
	G401: Detect the usage of DES, RC4, MD5 or SHA1
	G402: Look for bad TLS connection settings
	G403: Ensure minimum RSA key length of 2048 bits
	G404: Insecure random number source (rand)
	G501: Import blocklist: crypto/md5
	G502: Import blocklist: crypto/des
	G503: Import blocklist: crypto/rc4
	G504: Import blocklist: net/http/cgi
	G505: Import blocklist: crypto/sha1
	G601: Implicit memory aliasing in RangeStmt
```

拿 Go 语言中文网试验一下，切换到 studygolang 源码目录，执行：

```bash
$ gosec ./...
...
Summary:
  Gosec  : dev
  Files  : 186
  Lines  : 27434
  Nosec  : 0
  Issues : 292
```

中间过程输出内容很多，最后进行了汇总。根据默认规则，一共发现了 292 个 issue。但别慌，这里面有些规则太严格了，比如：

```bash
[/Users/xuxinhua/project/golang/studygolang/cmd/studygolang/background.go:57] - G104 (CWE-703): Errors unhandled. (Confidence: HIGH, Severity: LOW)
    56: 		// 生成阅读排行榜
  > 57: 		c.AddFunc("@daily", genViewRank)
    58:
```

因为 c.AddFunc 会返回 error，这个 error 一般不需要处理（这是启动定时任务进行处理），它提示没有处理，对应的规则是 G104。所以，我们将该规则排除掉：

```bash
$ gosec -exclude ./...
...
Summary:
  Gosec  : dev
  Files  : 186
  Lines  : 27434
  Nosec  : 0
  Issues : 51
```

这次 issue 只剩下 51 个。查看过程中指出的问题代码，依然发现有些规则可以忽略，比如：

```bash
[/Users/xuxinhua/project/golang/studygolang/logic/sitemap.go:266] - G307 (CWE-703): Deferring unsafe method "Close" on type "*os.File" (Confidence: HIGH, Severity: MEDIUM)
    265: 	}
  > 266: 	defer file.Close()
    267:
```

对应规则是 G307：Deferring a method which returns an error。大家一般都会这么做，因此这个规则也可以排除。

有兴趣的可以一步步看，默认提供的 30 来个规则都检测了哪些问题，根据你的项目情况，排除或使用哪些规则。

接下来，看一下密码安全问题规则，这是第一个规则：G101，只使用这个规则检测 studygolang 试试：

```bash
$ gosec -include=G101 ./...
...
[/Users/xuxinhua/project/golang/studygolang/http/http.go:437] - G101 (CWE-798): Potential hardcoded credentials (Confidence: LOW, Severity: HIGH)
    436: const (
  > 437: 	TokenSalt       = "b3%JFOykZx_golang_polaris"
    438: 	NeedReLoginCode = 600

Summary:
  Gosec  : dev
  Files  : 186
  Lines  : 27434
  Nosec  : 0
  Issues : 1
```

挺厉害，检查出了 TokenSalt 写死在代码里了，这是当时准备做 APP 时写的一个 Token，虽然影响不大（因为没有使用），也提醒了这样的应该提前写在配置文件中。

那 gosec 是怎么检测到的呢？在官网对这个规则有说明。它根据名称是否类似下面这些来判断的：

- “password”
- “pass”
- “passwd”
- “pwd”
- “secret”
- “token”

此外，安全相关特别要注意的就是 XSS 和 SQL 注入，这方面 gosec 也会有相关规则检测，比如 G201、G202、G203。

注意：通过 gosec 检测出的 issue，不代表一定有问题，但对我们是一个很好的提醒，让我们能够审视自己的代码，确保相关地方没问题，知道自己为什么这么写。

gosec 工具其他的使用，可以看文档说明，自己尝试。

## 04 总结

安全问题，我们永远不能忽视。很多时候，可能不会有问题，但真出了问题可能就是大问题。在写代码时，我们难免会有疏忽，通过使用 gosec 这样的工具，可以为我们把好最后一道关。

赶紧用 gosec 检验一下你的项目吧。
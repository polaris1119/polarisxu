---
title: "Go 1.17 新特性提前学之测试执行随机化"
date: 2021-05-30T22:20:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 1.17
---

大家好，我是 polarisxu。

Go1.17 预计在 8 月份发布。目前 tip.golang.org 可以浏览 Go1.17 的相关内容，<https://tip.golang.org/doc/go1.17> 也有了 Go1.17 相关改动的部分文档。这段时间，我会陆续给大家分享 Go1.17 中相关的新特性，提前学习。。。好吧，提前卷了~

今天先聊聊在测试中增加的随机化 flag：shuffle。

## 01 安装 tip 版本

由于 Go1.17 还未发布，因此为了体验它的新特性，我们需要安装 tip 版本。这是一个正在开发的版本，也就是仓库的 master 分支代码。因此，我们需要通过源码编译安装。

这里我使用 [goup](https://mp.weixin.qq.com/s/yTblk9Js1Zcq5aWVcYGjOA) 这个管理工具进行安装：

```bash
$ goup install tip
```

安装成功后，查看版本信息（你看到的大概率和我的不一样）：

```bash
$ go version
go version devel go1.17-1607c28172 Sun May 30 02:37:38 2021 +0000 darwin/amd64
```

## 02 新的 shuffle flag

安装完 tip 版本后，执行如下命令：

```bash
$ go help testflag
```

然后找到下面这个 flag：

```text
-shuffle off,on,N
		Randomize the execution order of tests and benchmarks.
		It is off by default. If -shuffle is set to on, then it will seed
		the randomizer using the system clock. If -shuffle is set to an
		integer N, then N will be used as the seed value. In both cases,
		the seed will be reported for reproducibility.
```

这是 Go1.17 新增的，提交的代码见：<https://golang.org/cl/310033>。

从名称可以看出，这是控制测试执行顺序是否随机的 flag。它有三个值：off、on 和 N，其中默认是 off，即不启用随机，这相当于 Go1.17 版本之前的测试行为。而 on 表示启用 shuffle，那 N 是什么意思？它也表示启用随机。on 和 N 的区别解释下：

> 因为是随机，就涉及到随机种子（seed）问题。当值是 on 时，随机数种子使用系统时钟；如果值是 N，则直接用这个 N 当做随机数种子。注意 N 是整数。
>
> 当测试失败时，如果启用了 shuffle，这个种子会打印出来，方便你重现之前测试场景。

## 03 例子体验下

创建一个包 calc，增加「加减乘除」四个函数：

```go
func Add(x, y int) int {
	return x + y
}

func Minus(x, y int) int {
	return x - y
}

func Mul(x, y int) int {
	return x * y
}

func Div(x, y int) int {
	return x / y
}
```

并为这四个函数写好单元测试（代码太长，这里只列出 Add 的，写法不重要，按你喜欢的方式写单元测试即可）：

```go
func TestAdd(t *testing.T) {
	type args struct {
		x int
		y int
	}
	tests := []struct {
		args args
		want int
	}{
		{
			args{1, 2},
			3,
		},
		{
			args{-1, 3},
			3,		// 特意构造一个 failure 的 case
		},
	}
	for _, tt := range tests {
		if got := Add(tt.args.x, tt.args.y); got != tt.want {
			t.Errorf("Add() = %v, want %v", got, tt.want)
		}
	}
}
```

然后运行单元测试（不加 shuffle flag）：

```bash
$ go test -v ./...
=== RUN   TestAdd
    calc_test.go:27: Add() = 2, want 3
--- FAIL: TestAdd (0.00s)
=== RUN   TestMinus
--- PASS: TestMinus (0.00s)
=== RUN   TestMul
--- PASS: TestMul (0.00s)
=== RUN   TestDiv
--- PASS: TestDiv (0.00s)
FAIL
FAIL	test/shuffle	0.441s
FAIL
```

多次运行，发现执行顺序都是你文件中写好的单元测试顺序，我这里是 Add、Minus、Mul、Div。

加上 shuffle flag 后运行：

```bash
$ go test -v -shuffle=on ./...
-test.shuffle 1622383890431866000
=== RUN   TestMul
--- PASS: TestMul (0.00s)
=== RUN   TestDiv
--- PASS: TestDiv (0.00s)
=== RUN   TestAdd
    calc_test.go:27: Add() = 2, want 3
--- FAIL: TestAdd (0.00s)
=== RUN   TestMinus
--- PASS: TestMinus (0.00s)
FAIL
FAIL	test/shuffle	0.177s
FAIL
```

输出有两处变化:

- 多了 `-test.shuffle 1622383890431866000`，即上面说到的种子。如果不是 on 而是 N，则这里的值就是 N 的值；
- 顺序不确定。你多次运行，发现每次顺序可能不一样；

顺便提一句，对于 benchmark，shuffle 这个 flag 也是适用的。

## 04 有什么用

有人可能会问，这个玩意有啥用？

确实，大部分时候这个特性没啥用。但如果你不希望测试之间有依赖关系，而担心实际上依赖了，可以加上这个 flag，以便发现潜在的问题。

其实，这个 flag 早在 2015 年 bradfitz 就提 [issue](https://github.com/golang/go/issues/10655) 建议加上，原计划在 Go1.6 加上的，但没有人写提案，因此搁置了。6 年过去了，才加上该功能，可见需求不强烈。日常工作中，你大概率也不会用到，但知晓有这么个东西还是有用处的，万一需要时，可以用上。


---
title: "Go1.17 新特性：testing 包的相关变化"
date: 2021-09-04T19:10:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - testing
  - 新特性
---

大家好，我是 polarisxu。

今天介绍下 Go1.17 中的特性：testing 包的一些变化。先看 Release Notes 关于 testing 变化的描述：

> Added a new testing flag -shuffle which controls the execution order of tests and benchmarks.
>
> The new T.Setenv and B.Setenv methods support setting an environment variable for the duration of the test or benchmark.

关于 shuffle 这个 flag，1.17 还未发布时，我就写过文章介绍：[Go1.17这个新特性竟然是6年前提出来的](https://mp.weixin.qq.com/s/8Ju2-daS0s-esDAezP-lZw)。关于它的作用，记住关键一点：我们写测试时，测试之间别相互依赖，应该是独立的。

本文着重介绍另外一个特性：T.Setenv 和 B.Setenv。

从名字可以看出，这是设置环境变量用的。T 是单元测试，而 B 是基准测试。

你可能会说，os 包不是有 Setenv 吗？

`os.Setenv` 会影响当前进程的环境变量，而 T.Setenv 和 B.Setenv 只会影响当前测试函数的环境变量，不会对其他测试函数造成影响。通过它们，可以做到每个测试有自己的独立的环境变量。

Go 源码中，有不少测试文件使用了这个新功能，比如：

```go
func TestImportVendor(t *testing.T) {
	testenv.MustHaveGoBuild(t) // really must just have source

	t.Setenv("GO111MODULE", "off")

	ctxt := Default
	wd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	ctxt.GOPATH = filepath.Join(wd, "testing/demo")
	p, err := ctxt.Import("c/d", filepath.Join(ctxt.GOPATH, "src/a/b"), 0)
	if err != nil {
		t.Fatalf("cannot find vendored c/d from testdata src/a/b directory: %v", err)
	}
	want := "a/vendor/c/d"
	if p.ImportPath != want {
		t.Fatalf("Import succeeded but found %q, want %q", p.ImportPath, want)
	}
}
```

具体源码：<https://github.com/golang/go/blob/891547e2d4bc2a23973e2c9f972ce69b2b48478e/src/go/build/build_test.go#L556>。

如果你项目中的测试依赖环境变量，可以考虑使用这个新的函数。

注意：在 Parallel 测试中不能使用 Setenv。


---
title: "字节跳动面试真的也会问这样的问题？！"
date: 2020-11-12T18:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - Golang
  - 面试题
---

大家好，我是站长 polarisxu。

网上看到有人分享去字节跳动的[面试 Go 的经验](https://zhuanlan.zhihu.com/p/132813717)，从面试题来看，应该是比较初级的职位。

这份面试经验总结中（其实谈不上总结，只是面试题的记录，并没有总结分析答案），有一道 Go 相关的题，也是一个老生常谈的问题：以下代码有什么问题，怎么解决？

```go
total, sum := 0, 0
for i := 1; i <= 10; i++ {
    sum += i
    go func() {
        total += i
    }()
}
fmt.Printf("total:%d sum %d", total, sum)
```

## 01 考点一

我相信很多人应该一眼看出了其中的一个问题，那就是 i 使用的问题。常见的题目是这样的：以下代码，输出什么？

```go
for i := 1; i <= 10; i++ {
  go func() {
    fmt.Println(i)
  }()
}
time.Sleep(1e9)
```

相信很多人知道，输出 10 个 11，而不是期望的输出 1 到 10。

怎么改进？你应该也知晓。

```go
for i := 1; i <= 10; i++ {
  go func(i int) {
    fmt.Println(i)
  }(i)
}
time.Sleep(1e9)
```

（当然这里的输出顺序是乱的，大家应该清楚）

## 02 考点二

该题的第二个考点：data race。因为存在多 goroutine 同时写 total 变量的问题，所以有数据竞争。可以加上 -race 参数验证：

```bash
$ go run -race main.go
==================
WARNING: DATA RACE
Read at 0x00c0001b4020 by goroutine 8:
  main.main.func1()
      /Users/xuxinhua/main.go:12 +0x57

Previous write at 0x00c0001b4020 by main goroutine:
  main.main()
      /Users/xuxinhua/main.go:9 +0x10b

Goroutine 8 (running) created at:
  main.main()
      /Users/xuxinhua/main.go:11 +0xe7
==================
```

这可以通过加锁的方式解决：

```go
var mutex sync.Mutex
total, sum := 0, 0
for i := 1; i <= 10; i++ {
  sum += i
  go func(i int) {
    mutex.Lock()
    total += i
    mutex.Unlock()
  }(i)
}
```

此外，也可以通过 atomic 包解决：（注意 total 的类型，因为 atomic.AddInt64 需要）

```go
var total int64
sum := 0
for i := 1; i <= 10; i++ {
  sum += i
  go func(i int) {
    atomic.AddInt64(&total, int64(i))
  }(i)
}
```

通过 -race 你验证，发现 data race 没了。

细心的你不知道发现没有，以上代码我故意把最后的 fmt 输出那一行去掉了，因为它用了 total 变量，避免它导致 data race。这引出考点三。

## 03 考点三

我上面都没有给完整的代码，因为经过上面两步，最终的结果还是不对的。从上面说的 fmt 输出代码去掉就说明还有问题。

初学 Go 应该遇到类似这样的问题，下面代码一般没有输出。

```go
package main

import "fmt"

func main() {
	go func() {
		fmt.Println("Hello World!")
	}()
}
```

原因是 main 函数先退出了，开启的 goroutine 根本没有机会执行。所以，常见的解决办法是在最后加一个 Sleep：

```go
package main

import "fmt"

func main() {
	go func() {
		fmt.Println("Hello World!")
	}()
  
  time.Sleep(1e9)
}
```

Sleep 会让 main goroutine 休眠，调度器调度其他 goroutine 运行。

回到开头的题目其实也存在这个问题，通过在 fmt 语句之前加上 Sleep，基本能得到正确的结果：

```go
var total int64
sum := 0
for i := 1; i <= 10; i++ {
    sum += i
    go func(i int) {
        atomic.AddInt64(&total, int64(i))
    }(i)
}
time.Sleep(1e9)

fmt.Printf("total:%d sum %d", total, sum)
```

但如果加上 -race 发现还是有问题：

```bash
$ go run -race main.go
==================
WARNING: DATA RACE
Read at 0x00c00001c0b0 by main goroutine:
  main.main()
      /Users/xuxinhua/main.go:20 +0xe4

Previous write at 0x00c00001c0b0 by goroutine 7:
  sync/atomic.AddInt64()
      /Users/xuxinhua/.go/current/src/runtime/race_amd64.s:276 +0xb
  main.main.func1()
      /Users/xuxinhua/main.go:15 +0x44

Goroutine 7 (finished) created at:
  main.main()
      /Users/xuxinhua/main.go:14 +0xa4
==================
total:55 sum 55Found 1 data race(s)
```

所以，这种方式是不靠谱的，这时正确的方式是使用 sync.WaitGroup。

```go
package main

import (
    "sync/atomic"
    "sync"
    "fmt"
)

func main() {
    var wg sync.WaitGroup
    var total int64
    sum := 0
    for i := 1; i <= 10; i++ {
        wg.Add(1)
        sum += i
        go func(i int) {
            defer wg.Done()
            atomic.AddInt64(&total, int64(i))
        }(i)
    }
    wg.Wait()

    fmt.Printf("total:%d sum %d", total, sum)
}
```

## 04 总结

通过上面的分析，发现看起来是一个简单的题目，其实考点好几个。这个题目还是挺好的，字节跳动面试官出的这道题还是有点水平。你觉得呢？


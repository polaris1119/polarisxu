---
title: "Go1.16 中的新函数 signal.NotifyContext 怎么用？"
date: 2021-06-01T12:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 信号
---

大家好，我是 polarisxu。

os/signal 这个包大家可能用的不多。但自从 Go1.8 起，有些人开始使用这个包了，原因是 Go1.8 在 net/http 包新增了一个方法：

```go
func (srv *Server) Shutdown(ctx context.Context) error
```

有了它就不需要借助第三方库实现优雅关闭服务了。具体怎么做呢？

```go
func main() {
	server = http.Server{
		Addr: ":8080",
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(time.Second * 10)
		fmt.Fprint(w, "Hello world!")
	})
  
	go server.ListenAndServe()

	// 监听中断信号（CTRL + C）
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	<-c

	// 重置 os.Interrupt 的默认行为
	signal.Reset(os.Interrupt)

	fmt.Println("shutting down gracefully, press Ctrl+C again to force")

	// 给程序最多 5 秒时间处理正在服务的请求
	timeoutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(timeoutCtx); err != nil {
		fmt.Println(err)
	}
}
```

- 这里利用 os/signal 包监听 Interrupt 信号；
- 收到该信号后，16 行 `<-c` 会返回；
- 为了可以再次 CTRL + C 强制退出，通过 Reset 恢复 os.Interrupt 的默认行为；（这不是必须的）

优雅退出的关键：1）新请求进不来；2）已有请求给时间处理完。所以，在接收到信号后，调用 server.Shutdown 方法，阻止新请求进来，同时给 5 秒等待时间，让已经进来的请求有时间处理。

在 Go1.16 中，os/signal 包新增了一个函数：

```go
func NotifyContext(parent context.Context, signals ...os.Signal) (ctx context.Context, stop context.CancelFunc)
```

功能和 Notify 类似，但用法上有些不同。上面的例子改用 NotifyContext：

```go
func after() {
	server = http.Server{
		Addr: ":8080",
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(time.Second * 10)
		fmt.Fprint(w, "Hello world!")
	})

	go server.ListenAndServe()
	
  // 监听中断信号（CTRL + C）
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	<-ctx.Done()

  // 重置 os.Interrupt 的默认行为，类似 signal.Reset
	stop()
	fmt.Println("shutting down gracefully, press Ctrl+C again to force")

  // 给程序最多 5 秒时间处理正在服务的请求
	timeoutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(timeoutCtx); err != nil {
		fmt.Println(err)
	}
}
```

和上面的写法有区别，完成的功能一样的。其实 NotifyContext 的内部就是基于 Notify 实现的：

```go
func NotifyContext(parent context.Context, signals ...os.Signal) (ctx context.Context, stop context.CancelFunc) {
	ctx, cancel := context.WithCancel(parent)
	c := &signalCtx{
		Context: ctx,
		cancel:  cancel,
		signals: signals,
	}
	c.ch = make(chan os.Signal, 1)
	Notify(c.ch, c.signals...)
	if ctx.Err() == nil {
		go func() {
			select {
			case <-c.ch:
				c.cancel()
			case <-c.Done():
			}
		}()
	}
	return c, c.stop
}
```

只是在返回的 stop 被调用时，会执行 os/signal 包中的 Stop 函数，这个 Stop 函数的功能和 Reset 类似。因此上面 Notify 的例子，Reset 的地方可以改为 Stop。

从封装上看，NotifyContext 做的更好。而且，如果在某些需要 Context 的场景下，它把监控系统信号和创建 Context 一步搞定。

NotifyContext 的用法，优雅的关闭服务，你掌握了吗？希望你实际动手试验下，启动服务，通过 `curl http://localhost:8080/` 访问，然后按 CTRL + C，看看具体效果。只看不动手，基本知识不是你的。

关于 NotifyContext 函数的文档可以在这里查看：<https://docs.studygolang.com/pkg/os/signal/#NotifyContext>。


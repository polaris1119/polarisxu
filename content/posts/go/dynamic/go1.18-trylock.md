---
title: "Go1.18 新特性：TryLock"
date: 2021-12-26T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - TryLock
---

大家好，我是 polarisxu。

我们知晓，Go 标准库的 sync/Mutex、RWMutex 实现了 sync/Locker 接口， 提供了 Lock() 和 UnLock() 方法，可以获取锁和释放锁，我们可以方便的使用它来控制对共享资源的并发控制。（其他语言，比如 Java 是有类似 TryLock 的功能的）

```go
type Locker interface {
    Lock()
    Unlock()
}
```

但是锁被获取后，在未释放之前其他 goroutine 再调用 Lock 则会被阻塞住，这种设计在有些情况下可能不能满足需求。有时我们希望尝试获取锁，如果获取到了则继续执行，如果获取不到，我们也不想阻塞住，而是去调用其它的逻辑，这个时候我们就想要 TryLock 方法：即尝试获取锁，获取不到也不堵塞。

这个需求，2013 年就有人提出，但官方没有采纳。2018 年又有人提出：<https://github.com/golang/go/issues/27544>，建议增加 TryLock，但没有下文。直到 2021 年 4 月，有人再次提出，同时也给出了标准库中需要的场景：<https://github.com/golang/go/issues/45435>。

不过，Go Team 的负责人 rsc 提出了反对的意见：

> Locks are for protecting invariants. If the lock is held by someone else, there is *nothing* you can say about the invariant.
>
> TryLock encourages imprecise thinking about locks; it encourages making assumptions about the invariants that may or may not be true. That ends up being its own source of races.
>
> There are definitely locking issues in http2. Adding TryLock would let us paper over them to some extent, but even that would not be a real fix. It would be more like the better your 4-wheel-drive the farther out you get stuck.
>
> I don't believe http2 makes a compelling case for TryLock.

他认为 TryLock 会鼓励设计者对锁进行不精确的思考，这可能最终会成为 race（竞态） 的根源。同时，他认为仅为 http2 提供 TryLock 不值得，希望有更具说服力的案例。

然后大家进行了一些讨论，同时 rsc 给了一个实现，并提到：

> sync: add Mutex.TryLock, RWMutex.TryLock, RWMutex.TryRLock 
>
> Use of these functions is almost (but not) always a bad idea.
>
> Very rarely they are necessary, and third-party implementations (using a mutex and an atomic word, say) cannot integrate as well with the race detector as implmentations in package sync itself.

也就是现在 Go1.18 中实现的三个方法。不过，rsc 建议，大家尽量别使用它。

可见，最后 rsc 妥协了，因为有人提出了一些实现 TryLock 的代码。就像 neild 说的，虽然大部分时候可能确实不需要 TryLock，但出现各种第三方版本的 TryLock，并非好事，而应该有一个官方的实现。

看看 Mutex.TryLock 官方的实现：<https://pkg.go.dev/sync@master#Mutex.TryLock>，强调虽然存在正确使用 TryLock 的情况，但很少见。可见官方是勉为其难的添加了它。

关于 TryLock，2017 年鸟窝大佬写过一篇文章， 如何自己实现一个，而且对比了几种实现方式的性能，感兴趣的可以阅读：<https://colobu.com/2017/03/09/implement-TryLock-in-Go/>。


---
title: "泛型版 singleflight：Go 中如何防止缓存击穿？"
date: 2021-12-30T13:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - singleflight
---

大家好，我是 polarisxu。

并发是 Go 的优势，但并发也需要很好的进行控制。标准库中有 sync 包，经常使用的功能有 sync.Mutex、sync.WaitGroup 等。其实，除了标准库，还有一个官方的扩展库，也叫 sync，其中有一个子包：sync/singleflight，专门做并发控制，比如防止缓存击穿。

## 01 从例子说起

看一个模拟缓存的例子，有如下代码：

```go
package main

import (
	"errors"
	"flag"
	"log"
	"sync"
)

var errorNotExist = errors.New("not exist")

var n int

func init() {
	flag.IntVar(&n, "n", 5, "模拟的并发数，默认 5")
}

func main() {
	flag.Parse()

	var wg sync.WaitGroup
	wg.Add(n)

	// 模拟并发访问
	for i := 0; i < n; i++ {
		go func() {
			defer wg.Done()
			// 假设都获取 id = 1 这篇文章
			article := fetchArticle(1)
			log.Println(article)
		}()
	}
	wg.Wait()
}

type Article struct {
	ID      int
	Content string
}


func fetchArticle(id int) *Article {
	article := findArticleFromCache(id)

	if article != nil && article.ID > 0 {
		return article
	}

	return findArticleFromDB(id)
}

var (
	cache   = make(map[int]*Article)
	rwmutex sync.RWMutex
)

// 模拟从缓存获取数据
func findArticleFromCache(id int) *Article {
	rwmutex.RLock()
	defer rwmutex.RUnlock()
	return cache[id]
}

// 模拟从数据库中获取数据
func findArticleFromDB(id int) *Article {
	log.Printf("SELECT * FROM article WHERE id=%d", id)
	article := &Article{ID: id, Content: "polarisxu"}
	rwmutex.Lock()
	defer rwmutex.Unlock()
	cache[id] = article
	return article
}
```

我们模拟 5 个用户并发访问，同时获取 ID=1 的文章，因为缓存中不存在，因此都到后端 DB 获取具体数据。从运行结果可以看出这一点：

```bash
$ go run main.go
2021/12/30 10:32:36 SELECT * FROM article WHERE id=1
2021/12/30 10:32:36 SELECT * FROM article WHERE id=1
2021/12/30 10:32:36 &{1 polarisxu}
2021/12/30 10:32:36 &{1 polarisxu}
2021/12/30 10:32:36 SELECT * FROM article WHERE id=1
2021/12/30 10:32:36 &{1 polarisxu}
2021/12/30 10:32:36 SELECT * FROM article WHERE id=1
2021/12/30 10:32:36 &{1 polarisxu}
2021/12/30 10:32:36 SELECT * FROM article WHERE id=1
2021/12/30 10:32:36 &{1 polarisxu}
```

显然这是我们不希望看到的。

## 02 使用 singleflight

官方的扩展包 golang.org/x/sync 下面有一个子包 singleflight：

```bash
Package singleflight provides a duplicate function call suppression mechanism.
```

它用来抑制函数的重复调用，这正好符合上面的场景：希望从数据库获取数据的函数只调用一次。

将 fetchArticle 函数改成这样：

```go
var g singleflight.Group

func fetchArticle(id int) *Article {
	article := findArticleFromCache(id)

	if article != nil && article.ID > 0 {
		return article
	}

	v, err, shared := g.Do(strconv.Itoa(id), func() (interface{}, error) {
		return findArticleFromDB(id), nil
	})

  // 打印 shared，看看都什么值
	fmt.Println("shared===", shared)

	if err != nil {
		log.Println("singleflight do error:", err)
		return nil
	}

	return v.(*Article)
}
```

singleflight.Group 是一个结构体类型，没有导出任何字段，它代表一类工作并形成一个命名空间，在该命名空间中可以抑制工作单元的重复执行。

该类型有三个方法，它们的功能见注释：

```go
// 执行并返回给定函数的结果，确保对于给定的键，fn 函数只会执行一次。
// 如果有重复的进来，重复的调用者会等待最原始的调用完成并收到相同的结果。
// 返回值 shared 指示是否将 v 提供给多个调用者。
// 返回值 v 是 fn 的执行结果
// 返回值 err 是 fn 返回的 err
func (g *Group) Do(key string, fn func() (interface{}, error)) (v interface{}, err error, shared bool)
// 和 Do 类似，但返回一个 channel（只能接收），用来接收结果。Result 是一个结构体，有三个字段，即 Do 返回的那三个。
func (g *Group) DoChan(key string, fn func() (interface{}, error)) <-chan Result
func (g *Group) Forget(key string)
```

因此，改后的代码，通过 Group.Do，即使并发多次调用，findArticleFromDB 也只会执行一次，并且这一次的结果会被并发多次执行共享。

运行后，结果如下：

```bash
$ go run main.go
2021/12/30 11:55:44 SELECT * FROM article WHERE id=1
shared=== true
2021/12/30 11:55:44 &{1 polarisxu}
shared=== true
2021/12/30 11:55:44 &{1 polarisxu}
shared=== true
2021/12/30 11:55:44 &{1 polarisxu}
shared=== true
2021/12/30 11:55:44 &{1 polarisxu}
shared=== true
2021/12/30 11:55:44 &{1 polarisxu}
```

和预期一样，findArticleFromDB 只执行了一次，shared 的值也表示结果被多个调用者共享。

所以，使用 Go 后，本地缓存再也不需要通过类似 Redis 中的 SETNX 这样的命令来实现类似的功能了。

## 03 Forget 的用途

上面 Group 的方法中，有一个没有给任何注释，即 Forget。从名字猜到，用来忘掉什么，那具体什么意思呢？

通过上面的例子，我们知晓，通过 Do，可以实现多个并发调用只执行回调函数一次，并共享相同的结果。而 Forget 的作用是：

> Forget tells the singleflight to forget about a key. Future calls to Do for this key will call the function rather than waiting for an earlier call to complete.

即告诉 singleflight 忘记一个 key，未来对此 key 的 Do 调用将调用 fn 回调函数，而不是等待更早的调用完成，即相当于废弃 Do 原本的作用。

可以在上面例子中 Do 调用之前，调用 g.Forget，验证是否 Do 的调用都执行 fn 函数即 findArticleFromDB 函数了。

## 04 泛型版本

细心的读者可能会发现，Do 方法返回的 v 是 interface{}，在 fetchArticle 函数最后，我们做了类型断言：`v.(*Article)`。

既然 Go1.18 马上要来了，有了泛型，可以有泛型版本的 singleflight，不需要做类型断言了。GitHub 已经有人实现并开源：<https://github.com/marwan-at-work/singleflight>。

改成这个泛型版本，要改以下几处：

- 导入包 marwan.io/singleflight，而非 github.com/marwan-at-work/singleflight，同时移除 golang.org/x/sync/singleflight

- g 的声明改为：`var g singleflight.Group[*Article]`

- Do 的调用，返回值由 interface{} 类型改为：`*Article`：

  ```go
  article, err, shared := g.Do(strconv.Itoa(id), func() (*Article, error) {
    return findArticleFromDB(id), nil
  })
  ```
- 最后返回时，直接返回 article，不需要做类型断言

## 05 总结

singleflight 很常用，你在 pkg.go.dev 搜索 singleflight，发现有很多轮子：<https://pkg.go.dev/search?q=singleflight>，好些项目不是使用官方的 golang.org/x/sync/singleflight，而是自己实现一个，不过这些实现基本只实现了最常用的 Do 方法。感兴趣的可以查看他们的实现。

下次项目中需要类似功能，记得使用 singleflight 哦！

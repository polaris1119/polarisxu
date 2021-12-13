---
title: "Go泛型系列：maps 包讲解"
date: 2021-12-05T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
---

大家好，我是 polarisxu。

[之前文章介绍了 slices 包](https://mp.weixin.qq.com/s/z30xJqiweIROlSp1YgcIsQ)，本文介绍另一个包，用于 map 相关操作，目前同样放在 golang.org/x/exp 包下。

> https://github.com/golang/exp/blob/master/maps/maps.go

## 01 真实的场景

不少新手，对 map 的输出是随机的有迷惑，曾经，map 的输出顺序是固定的，但官方怕大家依赖这个顺序，之后故意让输出顺序不固定。

但实际场景中，会有按某种顺序输出 map 的需求，怎么办呢？这需要对 map 的 key 进行排序，伪代码如下：

```go
for k := m {
  keys = append(keys, k)
}
sort(keys)
```

类似的代码会经常需要写，关键是，因为没有泛型，我们还没法写一个通用函数，复用代码。

## 02 maps 包详解

目前 maps 包有 8 个函数：

```go
func Keys[M ~map[K]V, K comparable, V any](m M) []K
func Values[M ~map[K]V, K comparable, V any](m M) []V
func Equal[M1, M2 ~map[K]V, K, V comparable](m1 M1, m2 M2) bool
func EqualFunc[M1 ~map[K]V1, M2 ~map[K]V2, K comparable, V1, V2 any](m1 M1, m2 M2, eq func(V1, V2) bool) bool
func Clear[M ~map[K]V, K comparable, V any](m M)
func Clone[M ~map[K]V, K comparable, V any](m M) M
func Copy[M ~map[K]V, K comparable, V any](dst, src M)
func DeleteFunc[M ~map[K]V, K comparable, V any](m M, del func(K, V) bool)
```

其中 Keys 就是上面说的场景，提取出 map 中所有的 key，组成一个 slice，方便做排序。相应的，Values 函数就是获取所有的 value，组成一个 slice。

```go
func Keys[M ~map[K]V, K comparable, V any](m M) []K {
	r := make([]K, 0, len(m))
	for k := range m {
		r = append(r, k)
	}
	return r
}
```

留意类型约束：`~map[K]V`，表明只要底层类型是 map 就适用，即适用自定义的 map 类型。上面函数的类型约束还说明，map 中，key 必须是可比较的，即 comparable 的，而 value 可以是任意类型，即 any。

Equal 和 EqualFunc 用于比较两个 map 是否有相同的键值对，用的应该不多。

至于 Clone 和 Copy，Clone 用于克隆出一个新的 map，key 和 value 和原来的一致，不过不是深度克隆，也就是说 value 可能指向同一个。

而 Copy 可以将 src 中的 key/value 全部复制到 dst 中，如果 dst 中存在同样的 key，会覆盖。

Clear 和 DeleteFunc 用于删除 map 的键值对。

maps 包代码不到 100 行，实现很简单，很容易看懂。不过大家需要认真看懂函数的签名，因为泛型的引入，导致函数签名比之前的函数签名复杂很多。

## 03 总结

PHPer 可能不以为然：这些东西，PHP 一直就有，Go 越来越 PHP 了。。。

之前 Go 没有提供相关函数，主要是因为没有泛型，没法提供通用的函数。有了泛型，就可以写通用代码了，因此提供相关的便利函数。

关于 maps 包有什么建议，大家以后试用可以提建议，毕竟现在只是在 exp 包中，没有正式合入标准库。
---
title: "Go 1.18 中的 any 是什么？"
date: 2021-12-02T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 泛型
  - any
---

大家好，我是 polarisxu。

Go 1.18 因为泛型引入 any，这实际上是 interface{} 的别名：

```go
type any = interface{}
```

以下代码虽然不是泛型，但用 Go 1.18 可以正常运行，证明 any 和 interface{} 是一样的：（这里可以在线运行：<https://gotipplay.golang.org/p/dPeNhe-7nkA>）

```go
package main

import (
	"fmt"
)

// 这里的 any 并非泛型的约束，而是类型
func test(x any) any {
	return x
}

func main() {
	fmt.Println(test("a"))
}
```

泛型中，any 换为 interface{} 也可以：（这里可以在线运行：<https://gotipplay.golang.org/p/wKL3rKuldQX>）

```go
package main

import (
	"fmt"
)

// 注意其中的 T interface{}，正常应该使用 T any
func Print[T interface{}](s ...T) {
	for _, v := range s {
		fmt.Print(v)
	}
}

func main() {
	Print("Hello, ", "playground\n")
}
```

你也可以本地使用 tip 运行验证下。

可见，之所以引入 any 关键字，主要是让泛型修饰时短一点，少一些括号。any 比 interface{} 会更清爽~

此外，项目中如果想要做替换，可以通过 gofmt 将 interface{} 改为 any：

```bash
gofmt -w -r 'interface{} -> any' ./...
```
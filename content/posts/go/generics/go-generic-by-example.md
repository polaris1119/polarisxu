Go1.18 已经发布，通过例子学习泛型

大家好，我是 polarisxu。

Go1.18 已经发布，泛型也正式面世。也许你不一定要得到泛型，但还是有必要学习下。之前我出过两个泛型相关的教程，没有看的可以看看。

- [Go 泛型入门教程](https://polarisxu.studygolang.com/posts/go/generics/generics-tutorial/)
- [跟着 Go 作者学泛型](https://polarisxu.studygolang.com/posts/go/generics/gophercon2021-generics/)

今天通过另外一种方式学习泛型，即具体的例子，建议可以实际动手试验这些例子，同时也领会一下泛型的使用场景。

## 求最小值、最大值

直接上代码：

```go
package main

import (
	"fmt"

	"golang.org/x/exp/constraints"
)

func max[T constraints.Ordered](s []T) T {
	if len(s) == 0 {
		var zero T
		return zero
	}
	m := s[0]
	for _, v := range s {
		if m < v {
			m = v
		}
	}
	return m
}

func min[T constraints.Ordered](s []T) T {
	if len(s) == 0 {
		var zero T
		return zero
	}
	m := s[0]
	for _, v := range s {
		if m > v {
			m = v
		}
	}
	return m
}

func main() {
	fmt.Println(min([]int{10, 2, 4, 1, 6, 8, 2}))
	fmt.Println(max([]float64{3.2, 5.1, 6.2, 7.6, 8.2, 1.5, 4.8}))
}

```

注意，golang.org/x/exp/constraints 这个包是实验性的，生产环境代码建议定义自己的一套。

因为要进行大小比较，所以对泛型 T 做了类型约束：constraints.Ordered，只有可进行大小比较的类型才符合类型 T。

## 2、泛型版 slice 包含函数

标准库中，对字符串、字节数组实现了相关的函数，进行包含判断：strings.Contains 和 bytes.Contains。那对其他基本类型怎么办？比如判断一个 int 是否在一个 int slice 中呢？得自己实现一个。

有了泛型，可以来一个泛型版本：

```go
package main

import "fmt"

func contains[T comparable](elems []T, v T) bool {
    for _, s := range elems {
        if v == s {
            return true
        }
    }
    return false
}

func main() {
    fmt.Println(contains([]string{"a", "b", "c"}, "b"))
    fmt.Println(contains([]int{1, 2, 3}, 2))
    fmt.Println(contains([]int{1, 2, 3}, 10))
}
```

实际上，golang.org/x/exp/slices 包实现了这样的功能。

## 3、从 map 中获得 key 的 slice

因为 map 是无序的，但有时候我们需要根据 map 中 key 的顺序做处理，这时候需要提取 map 中的 key 组成一个 slice，然后排序。

不同的类型，都需要做一遍，有了泛型，可以直接出一个泛型版。

```go
package main

import (
    "fmt"
)

func keys[K comparable, V any](m map[K]V) []K {
    keys := make([]K, 0, len(m))
    for k := range m {
        keys = append(keys, k)
    }
    return keys
}

func main() {
    vegetableSet := map[string]bool{
        "potato":  true,
        "cabbage": true,
        "carrot":  true,
    }

    fruitRank := map[int]string{
        1: "strawberry",
        2: "raspberry",
        3: "blueberry",
    }

    fmt.Printf("vegetableSet keys: %+v\n", keys(vegetableSet))
    fmt.Printf("fruitRank keys: %+v\n", keys(fruitRank))
}
```

输出：

```bash
vegetableSet keys: [potato cabbage carrot]
fruitRank keys: [1 2 3]
```

实际上，golang.org/x/exp/maps 包提供了这样的功能。

## 4、通用的 slice 排序功能

上面提到了 slice 的排序，这是很常见的需求。Go 标准库提供了排序的包：sort，一般这么用：

```go
package main

import (
	"fmt"
	"sort"
)

func main() {
	ints := []int{5, 2, 6, 3, 1, 4} // unsorted
	sort.Ints(ints)
	fmt.Println(ints)

	s := []string{"Go", "Bravo", "Gopher", "Alpha", "Grin", "Delta"}
	sort.Strings(s)
	fmt.Println(s)
}
```

标准库 sort 中有看起来差不多的代码。

有了泛型就简单多了，golang.org/x/exp/slices 也提供了相应的实现：

```go
func Sort[E constraints.Ordered](x []E)
func SortFunc[E any](x []E, less func(a, b E) bool)
func SortStableFunc[E any](x []E, less func(a, b E) bool)
```

对不同的 slice，调用的同一个泛型函数：

```go
package main

import (
	"fmt"

	"golang.org/x/exp/slices"
)

func main() {
	ints := []int{5, 2, 6, 3, 1, 4} // unsorted
	slices.Sort(ints)
	fmt.Println(ints)

	s := []string{"Go", "Bravo", "Gopher", "Alpha", "Grin", "Delta"}
	slices.Sort(s)
	fmt.Println(s)
}
```

## 5、filter 功能的实现

函数式编程中，filter
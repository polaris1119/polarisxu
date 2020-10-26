# Go 标准错误 API — CockroachDB errors 库（第1篇）

这篇文章是关于 [“CockroachDB errors 库”](https://github.com/cockroachdb/errors)的系列文章的第 1 篇，“CockroachDB errors 库”实际上是 Go 的标准 errors 包的通用、开放源码的替代品。

那本篇文章主要谈论什么呢？

## 基本的 Go 错误：error 是值

Go 生态有一些非常流行、也非常基本的学习资源（文档）：

- [A Tour of Go: Errors](http://tour.studygolang.com/methods/19)。这是 Go 的官方教程。
- [Go By Example: errors](http://books.studygolang.com/gobyexample/errors/)。Go By Example 是一些系列文章，推荐给那些希望通过示例学习 Go 的朋友们。
- [Goland Docs: Errors and Exception handling in GoLang](https://golangdocs.com/errors-exception-handling-in-golang)。“Golang Docs” 是一系列文章，它涵盖了 Go 中的常见软件模式。

我们可以从这些文章中学到什么？

- Go 提供了一个预定义的接口类型 error，定义如下：

  ```go
  // an "error" is an object with an `Error()` method
  // which describes the situation that occurred.
  type error interface {
       Error() string
  }
  ```

- 编写 Go 函数/方法的惯用方法是让它们在常规返回值之外，再返回一个 error 类型值，并在每个调用点上进行测试

  ```go
  func div(x, y int) (int, error) {
      if y == 0 {
         return 0, fmt.Errorf("boo")
      }
      return x / y, nil
  }
  
  func main() {
      r, err := div(3, 2)
      if err != nil {
         fmt.Printf("woops: %v", err)
         return
      }
      fmt.Println("result:", r)
  }
  ```

- 如上面的示例所示，fmt.Printf 会知道如何调用 error 的 Error() 方法来显示错误文本。如果错误是通过%s、%q、%x/%X 打印的，它也会这样做。

## error 也是链表

如果你还不知道 [Dave Cheney](https://dave.cheney.net/) 是谁，现在是时候去了解下这位及其高产的 Go 大师程序员。

2015 年，Dave 创建了 pkg/errors 包（[源代码](https://github.com/pkg/errors)，[文档](https://pkg.go.dev/github.com/pkg/errors)），随后在 2016 年东京举行的 GoCon 春季会议上展示了它。下面这篇文章用散文的形式解释了这个故事：

[Dave Cheney：优雅的处理错误，而不仅仅只是检查错误](https://studygolang.com/articles/12484)

以下是 Dave 提到的主要创新：

- Go error 对象像链表一样构建，而且是不可变的。
- err 在任何时候都会指向列表的头部。
- 在首次发生错误时，将构造一个原子或"叶"错误对象，该对象将在列表的尾部。
- 当错误通过调用堆栈和软件组件返回时，通过向错误添加更多"层"、在现有错误列表的头部 push 更多列表元素或"包装器"来增加错误。

这在实践中给我们什么启发呢？主要用途是向错误对象添加消息前缀，以给出有关"错误发生在哪"的更多上下文。例如：

```go
import (
   "fmt"
   "github.com/pkg/errors"
)

func foo() error {
     return fmt.Errorf("boo")
}

func bar() error {
     return errors.Wrap(foo(), "bar")
}

func baz() error {
     return errors.Wrap(foo(), "baz")
}

func main() {
     r := rollDice()
     var err error
     if (r < 4) {
        err = bar()
     } else {
        err = baz()
     }
     fmt.Println(err)
}
```

使用 `errors.Wrap()`，添加一个前缀到错误消息，main 函数能报告：`bar: boo` 或 `baz:boo` 这样人类可读错误消息，方便知晓哪个函数被调用。如果没有 `errors.Wrap()`，哪个调用路径导致错误将不容易知晓。

在实践中，这是如何工作的，看起来有点像这样：

```go
// errorString represents a leaf error. This
// is what gets constructed by e.g. fmt.Errorf().
type errorString struct {
     msg string
}

// Error implements the error interface.
func (e *errorString) Error() string { return e.msg }

// msgWrap represents a wrapper which adds a prefix
// to an error. This is what gets constructed
// by e.g. pkg/errors.Wrap().
type msgWrap struct {
     cause error
     msg string
}

// instances of msgWrap are also instances of the error
// interface, by implementing the Error() method.
func (e *msgWrap) Error() string {
     return fmt.Sprintf("%s: %v", e.msg, e.cause)
}
```

## 错误消息、包装注释和 cause 发现

Dave Cheney 的基础逻辑是：

> The `Error` method on the `error` interface exists for humans, not code.

换句话说，程序代码不应检查或比较 Error() 方法的结果。

Dave 继续谴责两种 Go 编程模式，他认为令人厌恶，现在仍然不赞成：

- “哨兵错误（sentinel errors）"的概念，这是在代码中通过 error 实例进行比较。例如，`if err == ErrNotExists`。这种方式的主要问题是，如果错误是链表，也许是在列表的尾部找到哨兵，而头部有其他内容（例如，消息前缀）。Sentinel 的另一个更实际的问题是，为了能够执行比较，发生比较的包必须导入定义 sentinel 所在的包。这将导致依赖项。这种类型的硬依赖性使软件组合更加困难。
- 引用 "error types"（或错误包装类型）的概念，进行错误类型断言，例如，`if e, ok := err.(SomeType); ok`。此处的问题与上述问题相同：如果错误是链表，则它可能不起作用，并且还导致了包依赖。

Dave 建议应该采用这两种方式：

- 为调用者感兴趣的错误对象的属性定义接口。例如，错误是否可恢复可以通过 IsRecoverable() 方法来定义。然后，在任何包都可以断言此接口的实现，没有依赖关系：在 Go 中，接口断言基于结构相等，而不是命名相等。
- 注意错误链接列表结构，并在检查错误对象时正确遍及链表层级。

为了实现后一点，Dave Cheney 在 pkg/errors 中引入了 causer 接口，从而有了以下可重用的代码模式：

```go
// NB: causer is not exported by pkg/errors; instead
// any package can re-defined it as needed
type causer interface { Cause() error }

...
if err != nil {
   for {
       if _, ok := err.(SomeInterfaceWithProperty); ok {
          // ... do something ...
       }

       // Peel one layer, if wrapped.
       if c, ok = c.(causer); ok {
          err = c.Cause()
          continue
       }
       break
   }
}
```

此模式会将错误展开，根据错误链访问，直到叶子节点或链表尾部。

## 在 errors 中内嵌堆栈追踪

包 pkg/errors 的一个被低估的特性是，每次构造错误或包装错误时，它都会自动保留堆栈跟踪的副本。

这一点很重要，因为它使得在排除问题时能够分析”错误发生在哪里"：通常情况下，该错误仅对开发人员可见，或在实例化后很长一段时间，在调用者中的某个地方出现问题。各种 Go 并发模式使这种困难更加复杂，其中错误对象通过通道将错误对象从一个 goroutine 传输到下一个 goroutine。因此，仅仅查看源代码中的"一行"来查找错误的来源是不够的。

为此，pkg/error 使用极其轻量级且相当聪明的机制来在每个错误构造时保留调用堆栈的副本。

此堆栈跟踪不出现在 Error() 方法的结果中；相反，当通过 Printf 中的 %+v 谓词（这是最常见的情况，例如在调试期间）或通过检查错误链接列表某些层（例如与 [Sentry.io](https://sentry.io/) 集成）上是否存在 StackTrace() 方法时，将显示错误对象。

这种机制特别巧妙的是，堆栈跟踪的所有详细信息（包括函数/包名称）不会直接存储在错误对象中，而是在打印堆栈跟踪时检索它们。通常情况下，错误发生，但可能是无害的，这样可以节省时间和内存。

## Go 1.13 中的提升和 API 分裂

很难说 pkg/errors 包多么基础和重要。但目前直接依赖它的公开 Go 项目超过 5 万个，还有无法统计的私有 Go 存储库。

Go 语言的设计者认识到了这一点，并[在 2019 年将其语义集成到 Go 标准库](https://blog.golang.org/go1.13-errors)中，从 Go 1.13 开始：

- Go 1.13 的错误也是链表。
- Go 1.13 没有提供 `errors.Wrap()`，但是为 fmt.Errorf 做了扩充：使用格式化动词 %w，构造一个包装错误，并保持原来的错误对象放在链表尾部供检测；
  - 在 `pkg/errors`: `errors.Wrapf(err, "hello %s", "world")`
  - 在 Go 1.13: `fmt.Errorf("hello %s: %w", "world", err)`
- Go 1.13 简化了在错误链表的每个中间级别上测试属性的任务，使用以下 api：
  - errors.Is(err1, err2) 检查 err1 中的任何层是否等于 err2（会递归地测试哨兵）。这可以用来识别许多标准库的哨兵，例如 errors.Is(err, os.ErrNotExist) 检查是否由于找不到某个文件/目录而导致错误。
  - `errors.As(err1, <type>)` 检查 err1 中的任何层是否可以被转换为 `<type>`（接口或具体类型），并返回转换的结果。这可以用来断言错误属性，就 Dave Cheney 在 2015 年建议的那样。

然而存在一些争议，因为 Go 1.13 在社区中引发了 API 的分裂：

- error 对象上的展开方法称为 Unwrap()，而不是 Cause()。我个人很讨厌 Go 团队选择一个单独的方法名，因为这直接破坏了与所有基于 pkg/errors 构建的包的兼容性，而且没有很好这么做的原因。
- Go 1.13 没有提供像 pkg/errors 中的 error.Cause() 那样的 “unwrap 一切”的函数。
- 另外，遗憾的是，因为 Go 1.13 没有定义 Cause() 方法，所以不可能使用 pkg/errors 中的 error.Cause() 来解包装来自 Go 1.13 项目和为 pkg/errors API 设计的项目的混合错误对象。
- 非常遗憾的是，Go 1.13 没有像 pkg/errors 那样提供捕获堆栈跟踪的工具。由于上述 API 的不兼容性，不可能将 pkg/errors 与特定于 Go 1.13 的代码混合匹配来获得这种行为。

总结为如下表格：

| Feature                                              | Go’s <1.13 `errors` | `github.com/pkg/errors` | Go 1.13 `errors` |
| :--------------------------------------------------- | :------------------ | :---------------------- | :--------------- |
| leaf error constructors (`New`, `Errorf` etc)        | ✔                   | ✔                       | ✔                |
| abstraction: errors are linked lists                 |                     | ✔                       | ✔                |
| error causes via `Cause()`                           |                     | ✔                       |                  |
| error causes via `Unwrap()`                          |                     |                         | ✔                |
| best practice: test interfaces, not values/types     |                     | ✔                       | (partial)        |
| `errors.As()`, `errors.Is()`                         |                     |                         | ✔                |
| `errors.Wrap()`                                      |                     | ✔                       |                  |
| automatic error wrap when format ends with : %w      |                     |                         | ✔                |
| standard wrappers with efficient stack trace capture |                     | ✔                       |                  |

这种分裂是真实而悲哀的。发生这种情况的原因（也许令人惊讶）是 Go 团队无法确定一种好的方法来标准化打印错误。我们将在本系列的后续文章中了解其中的原因。

然而，pkg/error 社区的用户不能简单地加入到 Go 1.13 的潮流中去。这里有一个缺口，需要一些交叉兼容的库来弥补这个缺口。

这就是为什么 [CockroachDB 错误库](https://github.com/cockroachdb/errors/)能够做到这一点。您可以使用它作为 pkg/errors 和 Go 1.13 自己的 errors 包的临时替代。

> 原文链接：https://dr-knz.net/cockroachdb-errors-std-api.html
>
> 本文作者：Raphael ‘kena’ Poss
>
> 译者：polarisxu


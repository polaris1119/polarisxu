---
title: "除了 fmt.Errorf() 之外—Go 中的日常错误对象：CockroachDB errors 库（第4篇）"
date: 2020-11-04T21:00:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - CockroachDB
  - error
---

在 Go 中传递错误的惯用方式是使用预定义的类型错误。但是 Go 的标准库仅提供了非常简单的错误对象，errors.New() 和fmt.Errorf()。

本文介绍了 CockroachDB 的 error 库（它是 Go 标准库库 errors 的直接替代品），Go 程序员如何用它来描述和传播其代码中的错误和错误代号（code）。

## Go 标准库 errors 太简单

由 fmt.Errorf() 构造的 Go 中最常见的“简单”错误对象类似于带有错误接口的包含在结构中的字符串：其 Error() 方法返回构造错误时设置的字符串。

```go
err := fmt.Errorf("hello")
fmt.Println(err) // prints "hello"
```

什么都没有，仅此而已。打印错误对象也会显示该字符串。顺便说一句，使用 Go 的错误包 errors 的构造函数构建错误 errors.New() 结果一样。

## 日常代码的简单错误

如果使用 [Dave Cheney 的错误库](https://github.com/pkg/errors)，或者甚至更好的 [CockroachDB 错误库](https://github.com/cockroachdb/errors)（通过导入 `github.com/cockroachdb/errors`），则简单错误也会在构造错误时自动捕获堆栈跟踪。

仅当详细打印错误时才显示堆栈跟踪。这样可以更轻松地排除错误的来源：

```go
import (
   "fmt"
   "github.com/cockroachdb/errors"
)

func main() {
  err := errors.New("hello")
  fmt.Println(err) // still prints just "hello"

  fmt.Printf("%+v\n", err) // verbose mode
}
```

这会打印：

```bash
hello
(1) attached stack trace
  -- stack trace:
  | main.main
  |     /home/kena/src/errors-tests/test.go:10
  | runtime.main
  |     /usr/lib/go-1.14/src/runtime/proc.go:203
  | runtime.goexit
  |     /usr/lib/go-1.14/src/runtime/asm_amd64.s:1373
Wraps: (2) hello
Error types: (1) *withstack.withStack (2) *errutil.leafError
```

此详细输出包括第一行的 `.Error()` 结果，后跟堆栈跟踪内容。

经验一次又一次地表明，在程序中出现意外情况的确切点提取堆栈跟踪的能力对于查明确切原因并成功解决问题至关重要。没有这种能力，程序员会毫无线索，麻木排查，浪费大量时间。

仅出于这个原因，我不鼓励任何人使用 Go 自己的 fmt.Errorf() 或 errors.New()。相反，请导入 github.com/cockroachdb/errors 并仔细阅读以下内容：

- errors.New()：直接替换 Go 标准库的 errors.New()，但它会带有堆栈跟踪；
- errors.Errorf() 或 errors.Newf()：用堆栈跟踪的方式替换 Go 标准库的 fmt.Errorf()；

```go
package github.com/cockroachdb/errors

// New constructs a simple error and attaches a stack trace.
func New(msg string) error

// Newf constructs a simple error whose message is composed using printf-like formatting.
// It also attaches a stack trace.
func Newf(format string, args ...interface{}) error

// Errorf is an alias for Newf for convenience
// and drop-in compatibility with github.com/pkg/errors.
func Errorf(format string, args ...interface{}) error
```

## 在错误中添加消息前缀以识别上下文

当从多个位置调用相同的逻辑，并且可能因错误而失败时，则希望将消息前缀添加到任何返回的错误对象。

这有助于提供有关“错误发生的位置”的更多上下文，以便在运行时出现错误时（何时出现错误），可以清楚地了解哪个代码路径产生了错误。

例如：

```go
package main

import (
   "fmt"
   "github.com/cockroachdb/errors"
)

func foo() error {
     return errors.New("boo")
}

func bar() error {
     if err := foo(); err != nil {
        return errors.Wrap(err, "bar")
     }
     return nil
}

func baz() error {
     if err := foo(); err != nil {
        return errors.Wrap(err, "baz")
     }
     return nil
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

多亏了 errors.Wrap()，它为消息添加了前缀，main 函数可能报告 bar:boo 或 baz:boo，并且人可以很方便的知晓是调用了哪个函数导致的错误。如果没有 errors.Wrap()，则导致错误的调用路径将是无法发现的。

为方便起见，当提供 nil 错误作为输入时，errors.Wrap() 返回nil。在许多情况下，这使我们可以消除 if err != nil 条件。例如：

```go
func bar() error {
     return errors.Wrap(foo(), "bar")
}

func baz() error {
     return errors.Wrap(foo(), "baz")
}
```

最后，errors.Wrap() 还将辅助堆栈跟踪附加到错误对象，从而在对错误的来源进行故障排除时提供了额外的上下文。在 channel 的场景出现错误是特别有用。

对于 errors.New()，此堆栈跟踪仅在显示详细错误时可见。例如：

```go
import (
   "fmt"
   "github.com/cockroachdb/errors"
)

func foo() error { return errors.New("world") }
func bar(err error) error { return errors.Wrap(err, "hello") }
func baz() error { return bar(foo()) }

func main() {
  err := baz()
  fmt.Println(err) // still prints just "hello: world"

  fmt.Printf("%+v\n", err) // verbose mode
}
```

将打印：

```bash
hello: world
(1) attached stack trace
  -- stack trace:
  | main.bar
  |     /home/kena/src/errors-tests/test.go:10
  | [...repeated from below...]
Wraps: (2) hello
Wraps: (3) attached stack trace
  -- stack trace:
  | main.foo
  |     /home/kena/src/errors-tests/test.go:9
  | main.baz
  |     /home/kena/src/errors-tests/test.go:11
  | main.main
  |     /home/kena/src/errors-tests/test.go:14
  | runtime.main
  |     /usr/lib/go-1.14/src/runtime/proc.go:203
  | runtime.goexit
  |     /usr/lib/go-1.14/src/runtime/asm_amd64.s:1373
Wraps: (4) world
Error types: (1) *withstack.withStack (2) *errutil.withPrefix (3) *withstack.withStack (4) *errutil.leafError
```

和以前一样，`.Error()` 的结果显示在第一行。然后，打印出最外层的堆栈跟踪（errors.Wrap() 的结果）。这表明错误被包裹在第 10 行，但调用跟踪与下面显示的一样。

然后，详细显示将显示内部错误，并显示消息 `world` 及其自身的堆栈跟踪。此内部堆栈跟踪显示内部错误是在第 9 行生成的。

错误包装工具用途广泛：可以使用类似于 printf 的格式来编写消息前缀。这是完整的 API：

```go
package github.com/cockroachdb/errors

// Wrap adds a message prefix and also attaches an additional stack trace.
// If the first argument is nil, it returns nil.
func Wrap(err error, msg string) error

// Wrap adds a message prefix composed using printf-like formatting,
// and also attaches an additional stack trace.
// If the first argument is nil, it returns nil.
func Wrapf(err error, format string, args ...interface{}) error
```

此外，为了兼容 Go 1.13 的 fmt.Errorf()，上面看到的 errors.Newf() 和 errors.Errorf() 函数，它们还能识别出格式化动词 ％w，从而触发 wrap 逻辑。

例如：

```go
// The following is similar to errors.Wrapf(err, "hello").
// However, it does not return nil if err is nil!
err = errors.Newf("hello: %w", err)
```

请注意，只有 Newf()/Errorf() 可以识别 ％w：errors.Wrap() 无法识别。

> 提示：应该优先使用 errors.Wrap() 代替特殊动词 ％w：因为它会正确忽略作为输入给出的 nil 错误。

## 次要错误注解

每个中级 Go 程序员都会迅速陷入这一痛苦的境地：如果在处理错误时遇到错误，该怎么办？

一个常见的示例是在处理文件时遇到错误后清理文件系统：

```go
func writeConfig(out string, cfgA, cfgB Config) (resErr error) {
    // Create the destination directory.
    if err := os.MkDir(out); err != nil {
       return err
    }
    defer func() {
       // If an error is encountered below, remove
       // the destination directory upon exit.
       if resErr != nil {
          if dirErr := os.RemoveAll(out); dirErr != nil {
             // now... what?
             ...
         }
       }
    }()

    if err := writeCfg(out, cfgA, "a.json", "config A"); err != nil {
      return err
    }
    return writeCfg(out, cfgB, "b.json", "config B")
}

func writeCfg(outDir path, cfg Config, filename, desc string) error {
    j, err := json.Marshal(cfg)
    if err != nil {
       return errors.Wrapf(err, "marshaling %s", desc)
    }
    return ioutil.WriteFile(filepath.Join(out, filename), j, 0777)
}
```

本示例中的函数创建一个输出目录，以将两个配置对象写入其中。但是，在写入某些配置对象时可能会发生错误。在这种情况下，该函数希望通过删除刚刚创建的目录来对其进行清理。

如果在目录删除过程中发生错误，该怎么办？应该返回哪个错误？

- 如果返回原始错误，我们将看不到目录删除错误。
- 如果返回目录删除错误，我们将看不到文件生成错误。

我们希望以某种方式返回有关这两个错误的详细信息，以帮助进行故障排除。同时，出于原因分析的目的，我们要谨慎地将遇到的第一个错误保留为“主要”错误。

我们可以通过如下调整代码来实现：

```go
defer func() {
   // If an error is encountered below, remove
   // the destination directory upon exit.
   if resErr != nil {
      if dirErr := os.RemoveAll(out); dirErr != nil {
         // This attaches dirErr as an ancillary error
         // to the error object that was already stored in resErr.
         resErr = errors.WithSecondaryError(resErr, dirErr)
     }
   }
}()
```

通过这种编程模式，我们可以确信，在处理另一个错误时，我们可以保留遇到错误时所发生事件的全部情况。

次要错误注解不会影响主要错误上 `.Error()` 返回的文本。从相关代码以及标准 API error.Is() 的角度来看，代码的行为就像仅发生了主要错误一样。

但是，在详细打印过程中会发现第二个错误。例如：

```go
package main

import (
   "fmt"
   "github.com/cockroachdb/errors"
)

func main() {
  err := errors.New("hello")
  err = errors.WithSecondaryError(err, errors.New("friend"))
  fmt.Println(err) // prints just "hello"

  fmt.Printf("%+v\n", err) // verbose mode
}
```

打印：

```bash
hello
(1) secondary error attachment
  | friend
  | (1) attached stack trace
  |   -- stack trace:
  |   | main.main
  |   |         /home/kena/src/errors-tests/test.go:11
  |   | runtime.main
  |   |         /usr/lib/go-1.14/src/runtime/proc.go:203
  |   | runtime.goexit
  |   |         /usr/lib/go-1.14/src/runtime/asm_amd64.s:1373
  | Wraps: (2) friend
  | Error types: (1) *withstack.withStack (2) *errutil.leafError
Wraps: (2) attached stack trace
  -- stack trace:
  | main.main
  |     /home/kena/src/errors-tests/test.go:10
  | runtime.main
  |     /usr/lib/go-1.14/src/runtime/proc.go:203
  | runtime.goexit
  |     /usr/lib/go-1.14/src/runtime/asm_amd64.s:1373
Wraps: (3) hello
Error types: (1) *secondary.withSecondaryError (2) *withstack.withStack (3) *errutil.leafError
```

像以前一样，我们在第一行看到 `.Error()` 的文本。然后，我们看到附加的次要错误的详细打印输出，相对于主要错误向右缩进。次要错误自己的 `.Error()` 是 `friend`，首先打印它，然后打印次要错误的嵌入式堆栈跟踪。

然后，打印输出继续，不缩进地显示主要错误的堆栈跟踪。

API 概览：

```go
package github.com/cockroachdb/errors

// WithSecondaryError attaches secondary as an annotation
// to the primary error. If primary is nil, nil is returned.
func WithSecondaryError(primary error, secondary error) error

// CombineErrors attaches err2 to err1 as secondary error
// if both err1 and err2 are not nil. If err1 is nil, err2
// is returned instead.
func CombineErrors(err1, err2 error) errors
```

## 子任务更智能的错误处理

扩展包 [errgroup](https://godoc.org/golang.org/x/sync/errgroup) 提供了一个可重复使用的库，用于“为处理共同任务的子任务的 goroutine 组进行同步，错误传播和上下文取消”。

它的实现可以在这里找到：<https://github.com/golang/sync/blob/master/errgroup/errgroup.go>。

在较高的级别上，它使用 sync.WaitGroup 运行多个 goroutine，并在末尾添加一个屏障。此外，一旦它们中的任何一个因错误终止，它将取消该组中的所有其他 goroutine。

逻辑问题在于，如果两个或多个 goroutine 因错误而失败，则仅报告第一个错误。其他错误是“被遗忘的”：

```go
func (g *Group) Go(f func() error) {
     g.wg.Add(1)

     go func() {
             defer g.wg.Done()

             if err := f(); err != nil {
                     // errOnce.Do executes its argument just once. The second time an
                     // error is encountered, it is simply forgotten altogether! Not nice.
                     g.errOnce.Do(func() {
                             g.err = err
                             if g.cancel != nil {
                                     g.cancel()
                             }
                     })
             }
     }()
}
```

我们可以按以下方式解决此问题：

```go
type Group struct {
     ...
     errOnce sync.Once
     mu {
        sync.Mutex // makes .err race-free.
        err     error
     }
}

func (g *Group) Wait() error {
   ...
   return g.mu.err
}

func (g *Group) Go(f func() error) {
     ...
     go func() {
             ...
             if err := f(); !errors.Is(err, context.Canceled) {
                   g.mu.Lock()
                   defer g.mu.Unlock()
                   g.mu.err = errors.CombineErrors(g.mu.err, err)
             }
     }()
}
```

使用 errgroup.Group 的此备用版本，如果子任务中有两个或多个错误，则第一个将成为“主要”错误，而第一个之后的所有其他错误将作为辅助错误注解附加。

该代码还使用 errors.Is(err, context.Canceled) 来排除由组调用共享上下文的 cancel() 函数而产生的错误对象，这些对象只是噪音，可能在故障排除期间没有用。

## 检查错误的身份

在最常见的情况下，错误会传播，最终通过网络连接返回，或打印到日志文件。

但是，有时代码需要检查错误对象以决定其他行为。

为此，库可以定义一些特定的函数来处理这种情况。例如：

```go
package os

// IsExist returns a boolean indicating whether the error is known to report
// that a file or directory already exists. It is satisfied by ErrExist as
// well as some syscall errors.
func IsExist(err error) bool
```

可以这样使用：

```go
func ensureDirectoryExists(path string) error {
    if err := os.Mkdir(path); err != nil {
       if os.IsExist(err) {
         // The directory already exists. This is OK,
         // no need to report an error.
         err = nil
       }
       return err
    }
    fmt.Println("directory created")
}
```

此函数尝试创建目录。如果已经存在，它将不执行任何操作。如果遇到另一个错误（例如磁盘损坏等），则会报告该错误。

另一种技术是使用“前哨”错误，并将返回的错误对象与那些标记进行比较以检测特定情况。

我们看到了上面带有 error.Is(err, context.Canceled) 的示例。这是来自 SQL 客户端程序的另一个示例：

```go
func (c *sqlConn) Query(query string, args []driver.Value) (*sqlRows, error) {
     if err := c.ensureConn(); err != nil {
             return nil, err
     }
     rows, err := c.conn.Query(query, args)
     if errors.Is(err, driver.ErrBadConn) {
             // If the connection has been closed by the server or
             // there was some other kind of network error, close
             // the connection on our side so that the call to
             // ensureConn() above establishes a new connection
             // during the next query.
             c.Close()
             c.reconnecting = true
     }
     if err != nil {
             return nil, err
     }
     return &sqlRows{rows: rows.(sqlRowsI), conn: c}, nil
}
```

此代码检测 SQL 驱动程序何时返回 driver.ErrBadConn 并在这种情况下选择特殊行为。任何其他错误均按原样返回，并导致程序在此函数的调用程序中的某处停止。

> errors.is() 可以通过重复调用  Unwrap() 方法来检测整个错误的直接因果链中的前哨错误。因此，将忽略“在途中”发现的任何次要错误注解。这种行为是有意设计的：类似树的行为将使人们难以推理出错误是另一个“原因”的含义。还会在其他 API errors.As() 错误中引发有关遍历顺序的难题。就个人而言，经验还没有向我表明，除线性因果链之外，其他任何东西在实践中有用。

## 和 pkg/errors 的不同

自 2016 年以来，事实上是 Go 的错误包的标准替代品是 Dave Cheney 的 pkg/errors 库，该库位于 <https://github.com/pkg/errors>。

该包最初引入了链接列表错误对象的概念，自动包装错误并添加堆栈跟踪以在故障排除期间提供更多上下文。

不幸的是，Go 1.13 的发布使 pkg/errors 过时了：Dave Cheney 定义了自己的库，使用一种名为 Cause() 的方法来提取错误链的线性原因。当 Go 1.13 采纳用链接列表出错的想法时，它定义了另一个方法 Unwrap() 来提取原因。因此，Go 的errors.Is()和其他 API 无法理解源自 pkg/errors 的错误。

此外，来自 pkg/errors 的对象将严重遭受 Go Error 打印灾难，因此该库使自定义错误类型的实现非常困难。

CockroachDB 错误库接管了 pkg/errors：它采用 Go 1.13 约定，提供了 Go 1.13 标准 API 的直接替代品，并避免了 Go 错误打印灾难。它还实现了大多数 pkg/errors 接口，因此可以用作以前使用 Dave Cheney 库的程序的直接替代。

## 总结

Go 库通过 Go 自己的错误包中的 fmt.Errorf() 和 errors.New() 提供了错误接口的简化实现。

改用 CockroachDB 错误库，代替 Go 的错误包和 Dave Cheney的 pkg/errors，可以获得更好的体验。

它的错误构造函数 errors.New()/errors.Newf()（别名为 errors.Errorf()）自动在错误对象中包含堆栈跟踪，可以使用 `fmt.Printf("％+v" ,err)` 打印堆栈追踪。

它还提供了错误包装器的词汇表。最常见的是带有 errors.Wrap()/errors.Wrapf() 的消息前缀注释，用于注释从多个位置调用的函数的调用路径。这还包括幕后的堆栈跟踪。

另一个常见的包装器解决了在处理另一个错误时遇到错误时如何在 Go 中执行的令人困惑的问题：使用辅助原因注解，并使用 errors.WithSecondaryCause() 或 errors.CombineErrors() 附加，Go 代码可以保留两个错误，因此程序员在故障排除期间可以同时看到两者。

CockroachDB 错误库中的错误还提供了一致的行为，并且在详细格式化错误时提供了有用的显示结构，从而避免了巨大的 Go 错误打印灾难。我们将在本系列的后续文章中专门探讨实现自定义错误，以进一步探讨该主题。
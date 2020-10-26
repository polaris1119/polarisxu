# Go error 打印灾难 —  CockroachDB errors 库（第3篇）

这篇文章是关于 [“CockroachDB errors 库”](https://github.com/cockroachdb/errors)的系列文章的第 3 篇，“CockroachDB errors 库”实际上是 Go 的标准 errors 包的通用、开放源码的替代品。

Go 1.13 的标准库采用了 Dave Cheney 自 2015 年以来对错误处理的主要贡献：将 Go 错误对象构造为链表的想法。 唉，这种方式给 Go 开发人员造成了巨大的障碍：使打印错误对象变得困难、几乎不可能。

这就是我所说的 “Go error 打印灾难"，下面我们将准确地看到它是什么。

## 提醒：Go 错误为什么是链表，怎么做的

Go 的错误 API，从 v1.13 开始，如下所示：

```go
// error is a pre-defined type.
type error interface {
   // Error returns an error's short message string.
   // This is used e.g. when formatting an error with %s/%v.
   Error() string
}

// wrapper can be implemented by additional error
// “layers”, to decorate an error. This interface
// is not pre-defined in the language but should be
// implemented by API-conformant error decorators.
//
// This is the interface that powers the error identification
// facilities errors.Is() and errors.As().
type wrapper interface {
   // Unwrap accesses the next layer in the error object.
   // This used to be called “Cause” in Dave Cheney's
   // pkg/errors library.
   Unwrap() error
}
```

使用此 API，Go 生态系统中的代码可以通过两种方式构造 error 对象：

- 使用类似 fmt.Errorf() 或 errors.New() 构造"叶”错误；
- 使用修饰层 "包装" 错误，例如使用 errors.Wrap() 为错误增加前缀信息，errors.WithStack() 附加堆栈跟踪或使用 %w 动词的 fmt.Errorf() ，这是 1.13 新增的：`err = fmt.Errorf("some context: %w", err)`
- 包装类型通过实现 Unwrap() 方法来声明其"剥离"的能力。这是由 Go 的标准库检查和使用的，特别是 errors.Is()，它可以通过查看所有中间层来识别错误是否为特定类型的错误。

抽象的链表使得使用来自不相关的 Go 包的修饰类型将修饰附加到任何错误对象成为可能。通过将层之间的关系定义为”只是 error"，没有包依赖项，也不会有循环导入的问题。它还使得可以跨不同的项目分离装饰器/包装器的开发，同时保持互操作性。

有关这个主题的详细信息，请阅读本系列中的上一篇文章：[Go 标准错误 API](https://dr-knz.net/cockroachdb-errors-std-api.html)。

## 提醒：Go 的格式化设施

Go 库中最常用的、功能最全的打印设施是标准 fmt 包。它包含格式化各种 Go 为字符串，或输出到文件、buffer、终端。

例如 fmt.Println(v) 将 v 的值打印到终端。

fmt 中的大多数打印函数共享基础逻辑，为更强大的 Printf() API 提供支持。Printf() 使用格式字符串和变量参数列表，并显示根据格式的参数。这直接派生自 C 中类似的[标准 API](https://en.wikipedia.org/wiki/C_file_input/output)。

Go 的 fmt 可以打印任意数据类型，但 C 的 stdio 不能。

这是使用预定义逻辑的组合来处理 Go 自己的基本类型，能智能递归地打印结构类型、指针和数组类型，以及自定义类型：fmt 尝试在传递给 Print 样式函数的值上使用四个接口。

- fmt .Formatter 接口定义了 Format(…) 方法，可以通过实现该方法以完全覆盖格式。
- 如果 fmt.Formatter 不存在，然后 fmt 会识别预定义的 error 接口。在这种情况下，它调用 Error() 方法并打印该方法。
- 如果 fmt.Formatter 或 error 都不可用，则根据使用的格式动词，自定义类型可以实现 fmt.Stringer（一个 String() 方法）或 fmt.GoStringer（一个 GoString() 方法）用于驱动更简单、不太灵活的格式输出。

只有当这些接口都未实现时，fmt 才回退到使用其预定义逻辑。

有关本主题的详细信息，请阅读本系列中的上一篇文章：[Go 的格式化 API。](https://dr-knz.net/go-formatting-apis.html)

## 提醒：error 的简单打印

fmt 检测 error 参数并自动调用 Error() 方法。这工作得很好，即使对于包装错误：Error() 在最外层的包装器（链接列表的头部）上调用。因此，该包装器的 Error() 实现可以覆盖其尾部图层的错误。

例如：

- `errors.New("world").Error()` 返回 `world`。
- `errors.Wrap(errors.New("world"), "hello")` 返回 `hello: world`。
- 同上，`fmt.Errorf("hello %w", errors.New("world"))` 也构造了一个包装错误。

这样，当将错误传递到 fmt 时，我们会自动获得自然的"更长"，"更完整”的 Error() 结果。

一切似乎都很好，而且自从 Go v1.0 以来一直很好，但是详细的打印又如何呢？

## 提醒：详细的打印模式

当使用 %+v 格式参数时，fmt 内部逻辑将采用"详细"模式，以显示参数列表中的相应值。默认情况下，详细模式会触发例如在结构类型中显示字段名称。

例如：

```go
s := struct { a int }{123}
fmt.Printf("%v\n", s)  // prints {123}
fmt.Printf("%+v\n", s) // verbose mode: prints {a:123}
```

"详细模式”的定义有一个新的抽象：某些数据在常见情况下不可见，但可根据请求变为可见。

这在进行 “printf debugging” 或事件日志记录时非常有用，因为查看调试或日志记录输出是给专业用户查看的，可以查看比程序常规输出中显示更多的信息。

自定义类型只能通过实现 fmt.Formatter 接口来自定义详细模式的输出。formatter 接口。只有该接口的 Format() 方法能获取有关是否请求详细模式的信息。fmt 包的其他接口不够强大。

特别是，error 接口和隐式 wrapper 接口都没有为错误类型提供一种自定义 fmt 中显示方式的方法。

## 详细打印 Go 错误的可取之处

除了调用 Error() 方法提供的简单模式外，Go 生态系统还构建了单独的详细模式来打印错误对象的需求。

例如，Dave Cheney 的 pkg/errors 包和 CockroachDB 的 [errors](https://github.com/cockroachdb/errors) 库都会自动在错误对象中嵌入堆栈跟踪。此堆栈跟踪不会出现在 Error() 的输出中，因此在简单模式下打印错误对象时不包括此堆栈跟踪。当程序遇到错误，发现自己无法令人满意地处理它时，程序员可以使用 %+v 进入详细模式以查看堆栈跟踪。这有助于了解错误的来源和在程序中的位置。

此外，程序可以选择使用错误包装器将不是错误消息的控制信息嵌入到程序中，例如，指示调用方函数中错误处理期间应执行操作的特殊数字代码。调用方函数可以使用标准 API errors.As() 从错误链接链表中提取此数据。

如果程序员在排除的疑难 Bug 时想要可视化此信息，该信息不包括在 Error() 的输出中，怎么办？同样，将此信息输出为"详细模式”的一部分，似乎这是一种自然的选择。

不幸的是，实现这个目标是相当困难的。

## 基本缺陷 1：在包装器中无法自定义

我们试验和设计自己的错误类型，其中一些隐藏的信息只在详细模式下显示。我们可以这样做，如下所示：

```go
type myError struct {
   msg string // public message
   code int // hidden code
}

// Error implements the error interface.
func (e *myError) Error() string { return e.msg }

// Format implements the fmt.Formatter interface.
func (e *myError) Format(s fmt.State, verb rune) {
   if verb == 'v' && s.Flag('+') {
      // Verbose mode.
      fmt.Fprintf(s, "(code: %d) %s", e.code, e.msg)
   } else {
      fmt.Fprint(s, e.msg)
   }
}
```

说明：当我们用 %v 打印 `*myError` 的实例时，我们得到 msg 的值；使用 %+v 时，我们得到相同的内容，但有前缀 (code: NNN)  和字段 code 的值。

精明的读者可能会注意到此代码看起来不完整，因为它不处理 %q 等格式动词。这在本节中不直接相关，因此我们暂时忽略它。

除了最后一点， 代码似乎工作正常？

唉！

尝试以下代码：

```go
err := &myError{"hello", 123}
err = fmt.Errorf("wazaa: %w", err)
fmt.Println(err)         // simple mode: prints just "wazaa: hello"
fmt.Printf("%+v\n", err) // verbose: prints... what?
```

我们希望本示例中的代码打印 `zawaa: (code: 213) hello`。不幸的是，它不是：由 fmt.Errorf 返回的错误类型，fmt.Formatter 接口不起作用。因此，使用 fmt.Errorf 时，myError 中的自定义信息丢失了！

换句话说，在 “标准 Go” 中，通过 `Unwrap()` 方法创建良好的包装错误类型还不够；因此，在"标准 Go"中创建成形良好的错误包装类型是不够的。还必须实现适当的 Format() 方法，在包装错误中，通过 fmt.Formatter  处理任何可能的自定义格式。

这样有两个主要问题：

- 有一点很明确：必须实现 Format() 方法，即使自定义包装不需要自定义格式，以免 fmt.Formatter 接口对于所有参与者都毫无用处。
- Go 库中没有文档说明此问题。所以大家根本不了解也不知道。实际上，粗略的检查显示，Go 生态系统中的许多自定义错误包装器类型均未实现 Format()，因此会在其 “尾巴” 中破坏格式自定义。

## 基本缺陷 2：转发（forwarding） fmt.Formatter 的困难

如果我们愿意支付抽象税，并同意所有包装错误类型也将实现 fmt.Formatter，那又会这样？怎么会这样呢？

作为支持示例，让我们尝试一个非常简单的包装，它没有任何特殊功能：

```go
type myWrapper struct {
   cause error // tail of linked list
}

// Error implements the error interface.
func (e *myWrapper) Error() string { return e.cause.Error() }

// Unwrap implements the unwrap interface.
func (e *myWrapper) Unwrap() error { return e.cause }
```

然后，我们可以开始实现 fmt.Formatter。至少，它应该区分冗长和非冗长模式。

但是，如果我们不确定错误原因（error cause）是否实际实现 fmt.Formatter？也许没有。因此，为了减少的惊讶，我们需要做"与 fmt 相同的一些事"。实现此目的的最佳方法是调用 fmt 本身逻辑：

```go
// Format implements the fmt.Formatter interface.
func (e *myWrapper) Format(s fmt.State, verb rune) {
   if verb == 'v' && s.Flag('+') {
      // Verbose mode. Make fmt ask the cause
      // to print itself verbosely.
      fmt.Fprintf(s, "%+v", e.cause)
   } else {
      // Simple mode. Make fmt ask the cause
      // to print itself simply.
      fmt.Fprint(s, e.cause)
   }
}
```

这是一个繁琐的模式，只是为了确保 e. cause 得到打印。

此外，如果 e.cause 想要了解有关原始格式的信息，那该内容会如何呢？如果与 %#v 一起使用时，使用 #v？还是 %#+v？还是 %q？

遗憾的是，fmt 中没有标准 API 来正确将所有状态转发到递归调用。自 Go 1.15 起，将所有格式状态（formatting state）完全转发到错误原因而不打印任何其他内容的代码量最低如下：

```go
// Format implements the fmt.Formatter interface.
func (e *myWrapper) Format(s fmt.State, verb rune) {
    var f strings.Builder
    f.WriteByte('%')
    if s.Flag('+') {
        f.WriteByte('+')
    }
    if s.Flag('-') {
        f.WriteByte('-')
    }
    if s.Flag('#') {
        f.WriteByte('#')
    }
    if s.Flag(' ') {
        f.WriteByte(' ')
    }
    if s.Flag('0') {
        f.WriteByte('0')
    }
    if w, wp := s.Width(); wp {
        f.WriteString(strconv.Itoa(w))
    }
    if p, pp := s.Precision(); pp {
        f.WriteByte('.')
        f.WriteString(strconv.Itoa(p))
    }
    f.WriteRune(verb)
    fmt.Fprintf(f.String(), e.cause)
}
```

这看起来非常不方便，容易出错。

即使是 Dave Cheney 的 pkg/errors 包也没有做到这一点，它仅在包装器中按如下方式实现 Format()，如下所示：

```go
func (w *withMessage) Format(s fmt.State, verb rune) {
    switch verb {
    case 'v':
        if s.Flag('+') {
            fmt.Fprintf(s, "%+v\n", w.Cause())
            io.WriteString(s, w.msg)
            return
        }
        fallthrough
    case 's', 'q':
        io.WriteString(s, w.Error())
    }
}
```

此代码对于谓词 %q 不正确，同时完全省略其他格式标记（如 %#v 等），并且无法识别除 v、s 或 q 以外的任何谓词。

在 Go 生态系统中探索发现，很少有自定义错误包装类型实现 Format()。

实现适当的自定义 Format()， 以及没有预定义 （也不建议） 机制在 fmt 中转发 Format() 调用这一事实是如此困难，这是 Go 标准库的基本限制。

（安利：上面的正确代码的副本可作为可重用的 fmtfwd.MakeFormat() 函数，在 [go-mtfwd](https://github.com/knz/go-fmtfwd) 包中。然而，这不是万能药。）

## 基本缺陷 3：不更改 API 无法修复的问题

Go 的团队称自己构建的语言可以最大限度地保持向后兼容性。标准库的添加是通过引入或替换功能，但不会影响现有代码的语义。

在这种情况下，Go 开发人员可以做什么来"修复"上面确定的问题，而不破坏现有的 error 代码，也不需要现有包添加"缺失"的粘附代码，如缺少的 Format() 转发器？

事实证明，在 fmt 包中可以直接做的工作不多。

在高级别上，不可能的任务是确保错误链中的所有细节以详细模式打印，同时考虑 Format() 方法中的自定义行为。

由于不是链中的每一个错误都提供 Format() 方法，因此 fmt 代码需要使用 Unwrap() 方法迭代自身。然后在每个层上都需要打印...东西。但究竟是什么？

- 它无法调用 Error()，因为包装器上的 Error() 本身将递归，并获取链中其他层的字符串片段；
- 它无法调用 Format()，因为包装器上的 Format() 已经（根据当前生态系统）对错误原因递归递处理。

因为 fmt.Formatter 接口 Format() 方法的第一个参数 fmt.State，是一个接口类型，因此实际在 fmt 中会是一个特定的 State 实例，可以"分离"当前错误层内的直接打印，从进一步递归执行打印。

例如，如下 Format() 实现：

```go
// Format implements the fmt.Formatter interface.
func (e *myWrapper) Format(s fmt.State, verb rune) {
   if verb == 'v' && s.Flag('+') {
      // Verbose mode. Make fmt ask the cause
      // to print itself verbosely.
      fmt.Fprintf(s, "(code %d) %+v", e.code, e.cause)
   } else {
      // Simple mode. Make fmt ask the cause
      // to print itself simply.
      fmt.Fprint(s, e.cause)
   }
}
```

通过此代码可见，在 Format 内部调用的 fmt.Fprintf 或 fmt.Fprint 的第一参数是 fmt.State 的实例，这是 fmt 包负责注入的。简单字符串和非错误值可以传递，每次看到错误值时，它都会被”忽略”，以便外部 fmt 循环可以转到下一层，而不会重复输出。

这个想法的问题， 要知晓 Format() 方法中是怎么使用 fmt.State 的。它不适用于实现以下函数的软件包：

```go
func (w *withMessage) Format(s fmt.State, verb rune) {
    switch verb {
        // ...
    case 's', 'q':
        io.WriteString(s, w.Error())
    }
}
```

（这个例子来自 pkg/errors）。

请注意，与 Go 生态系统中的许多其他实现一样，此实现也挫败了我们的想法：某些打印使用 fmt.State 的 io.Writer 子接口并将 `.Error()` 字符串直接传递给它。当包装器的 Format() 正在打印下一层错误时，无法可靠地从 fmt.State 中进行检测，从而捕获该错误以执行其他操作。

因此，Go 生态系统中“将错误作为链接列表”的集成与 fmt.Formatter 抽象发生冲突，并创建了一个坑，社区中的每个人都陷入困境，而 Go 标准库无法帮助任何人在 fmt 中使用魔术。

## 也许是救星：pre-1.13 xerrors

在进行 Go 1.13 的工作中，2017 年成立了一个工作组，研究采用“错误作为链接列表”的方法，并基本上接管了 Dave Cheney 在 pkg/errors 中的工作。

这就是由 Jonathan Amsterdam，Russ Cox，Marcel van Lohuizen 和 Damien Neil 组成的小组开始开发 [xerrors](https://github.com/golang/xerrors) 包，以作为新抽象的原型和研究依据。

这项工作指导作者提出了一些建议：

- [Marcel van Lohuizen: Error Printing — Draft Design](https://go.googlesource.com/proposal/+/master/design/go2draft-error-printing.md) (August 2018)
- [Jonathan Amsterdam, Russ Cox, Marcel van Lohuizen, Damien Neil: Proposal: Go 2 Error Inspection](https://go.googlesource.com/proposal/+/master/design/29934-error-values.md) (January 2019)

他们的工作主要集中在 Unwrap() 的语义以及新 API error.Is() 和 errors.As() 的创建上，以可靠地从错误对象中识别和提取信息。

Marcel van Lohuizen 更加关注错误处理的打印方面，并设计了以下提案：

- 除了 fmt.Formatter，error，fmt.Stringer 和 fmt.GoStringer 外，fmt 包支持一个新接口：errors.Formatter。

- 新接口将通过错误包装和叶类型实现。

- 提议的接口如下：

  ```go
  package errors
  
  type Formatter {
       error
  
       // FormatError can be implemented to customize the formatting
       // of errors, instead of fmt.Formatter's Format.
       //
       // It has access to an errors.Printer (see below)
       // to actually produce output.
       //
       // In the common case, the code in FormatError details
       // the current layer and returns the next error layer
       // to print, or `nil` to indicate the tail of the
       // linked list has been reached.
       //
       // Optionally, the code for a wrapper's FormatError
       // can take over formatting of both itself *and all
       // subsequent layers* by producing its custom
       // representation for all and then returning `nil`,
       // even though its Unwrap() method is still used
       // by errors.Is() to iterate through the tail.
       FormatError(p Printer) (next error)
  }
  
  type Printer interface {
      Print(...)  // can be used to output stuff
      Printf(...) // can be used to output stuff
  
      // Detail is a “magic” predicate which both indicates whether
      // verbose mode is requested via %+v, and also starts indenting
      // the output performed by subsequent Print()/Printf() calls in
      // the interface, so that the details are visually “pushed to
      // the right”.
      Detail() bool
  }
  ```

一个示例用法如下所示：

```go
// FormatError implements the errors.Formatter interface.
func (e *myWrapper) FormatError(p errors.Printer) {
    p.Print("always")
    if p.Detail() {
       p.Printf("hidden: ", e.code)
    }
    return e.cause
}
```

使用此代码，我们将得到以下行为：

```go
err := errors.New("hello")
err = &myWrapper{cause: err, code: 123}
err = &myWrapper{cause: err, code: 456}

fmt.Println(err) // simple mode: prints "always: always: hello"

fmt.Printf("%+v\n", err)
// prints:
//
//   always:
//      hidden: 456
//   always:
//      hidden: 123
//   hello
```

（请注意一些特性：错误是从最外层/头部到最内层/尾部打印的，并且在每个前缀之后，细节之前插入了冒号）。

因此，将 fmt 代码修改为使用新接口的方式是：

1. 检测 Format() 方法是否可用。如果是这样，它被调用，结束。
2. 否则，如果要打印的对象是错误，它将对其进行迭代：调用 FormatError()（如果存在）并使用其返回值作为下一次迭代的输入进行迭代。
3. 当错误对象上不存在 FormatError() 或返回 nil 时，迭代将停止。
4. 如果在迭代结束时仍有 Format() 或 Error() 方法可供调用，则将调用该方法以“完成”格式化。

xerror 原型能够集中精力仅格式化一层包装器，而又不知道如何正确地将 Format() 调用转发给其他层。

因此，这是解决上述第二个基本限制的尝试。

哎，它根本无法解决第一个基本限制：如果包装层未实现 FormatError()，则 fmt 代码将仅停止在该级别尝试，并且在错误中进一步进行任何 FormatError() 或 Format() 定制链会被丢弃。

此外，许多人不喜欢“从前到后”打印错误的方式：在对错误详细信息进行故障排除时，开发人员发现重要是首先显示链接列表的“最内层”（尾部），然后才是“最外层”（头）。 xerrors 实现不允许这样做。

最后，无论如何，所有讨论都是没有争议的：没有选择将 xerror 打印抽象（包括 errors.Formatter，errors.Printer 和相应的 fmt 更改）包含在 Go 1.13 中。从 Go 1.16 开始，[朝着这个方向进行的任何进一步工作都被推迟](https://github.com/golang/go/issues/29934#issuecomment-591488854)，具体另行通知。

## 战略失误：打破与pkg/errors 的兼容性

依赖于 Dave Cheney 的 pkg/errors 的社区项目超过 50,000 个，该软件包已成为事实上的扩展，能够提供错误包装程序的基本库，并作为错误打印自定义示例，尽管不完善。

甚至有一个扩展的生态系统，它依靠基本的链表抽象，使用一种名为 Cause() 的方法来接受链中的下一个层次。

Go 团队可能已经接受了这种方法，并且可以在“所有错误包装程序都必须以类似于 pkg/errors 的方式实现 Format”的方式进行区分。然后，errors.Is()/errors.As() 可能选择了 pkg/errors 的 Cause() 抽象。

遗憾的是，Go 团队选择了不同的方法名称：Unwrap()。因此，Go 1.13 发布后开发的新一代错误包已无法重用 pkg/errors。

因此，1.13 不仅引入了基本限制；这也阻止了 Go 社区继续可靠地使用 pkg/errors。

## 总结：Go error 打印灾难

在 2019 年，Go 1.13 采纳了 Dave Cheney 的 2015 年建议，将错误对象视为链表。因此，对 Unwrap() 方法进行了标准化，并使用 Is() 和 As() 函数增强了错误包，这些函数可以从以这种方式构造的错误中可靠地提取信息。

不幸的是，fmt 软件包没有学习如何打印这种错误的新形状，并且可靠地自定义错误对象的显示已变得不可能。

这是因为与以前的版本一样，fmt 仅了解 Format()，Error() 和 String()，并且仅在错误链的顶端或“头”考虑这些方法。

如果一个包定义了自定义包装错误类型，但忘记定义了自定义 Format() 方法，则 fmt 将忽略链接列表“尾部”中的任何其他 Format() 方法，并且自定义项将丢失。

此外，只有 Format() 方法可以为“详细”和“简单”格式（％v /％+v）提供不同的实现。在实践中，以递归方式在错误链尾部调用进一步的自定义方式，几乎不可能实现包装错误的 Format()。

简而言之，错误打印的自定义变得容易出错，并且在 Go 1.13 中基本上不可靠。Go 1.13 中放弃了的关键 Cause() 接口，导致与另一个具有某些人们可以达成共识的逻辑的程序包 Dave Cheney 的 pkg/errors 不兼容。 Go 团队通过 xerrors 包来尝试修复 Go 标准库中的这种情况，实际上并没有成功解决这些问题，存在重大的新缺陷，最终不令人满意。

这就是我们程序员无所适从的方式。

这是 Go error 打印灾难，它的悬念留在 Go 1.16 中。

## 接下来

CockroachDB error 库在错误打印方面花费了大量精力。尽管它不能填补所有空白，但确实可以减轻很多的痛苦。

本系列的下一篇文章进一步说明。

## 参考文献

- [Dave Cheney: Don’t just check errors, handle them gracefully](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully).
- [The Go Blog: Working with errors in Go 1.13](https://blog.golang.org/go1.13-errors).
- [Jonathan Amsterdam, et al: Go 2 error values](https://github.com/golang/go/issues/29934).
- [Marcel van Lohuizen: Error Printing — Draft Design](https://go.googlesource.com/proposal/+/master/design/go2draft-error-printing.md).
- [Jonathan Amsterdam, Russ Cox, Marcel van Lohuizen, Damien Neil: Proposal: Go 2 Error Inspection](https://go.googlesource.com/proposal/+/master/design/29934-error-values.md).

> 原文链接：https://dr-knz.net/go-error-printing-catastrophe.html
>
> 本文作者：Raphael ‘kena’ Poss
>
> 译者：polarisxu
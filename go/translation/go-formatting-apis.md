# Go 格式化 API —  CockroachDB errors 库（第2篇）

这篇文章是关于 [“CockroachDB errors 库”](https://github.com/cockroachdb/errors)的系列文章的第 2 篇，“CockroachDB errors 库”实际上是 Go 的标准 errors 包的通用、开放源码的替代品。

以下面的代码为例：

```go
import "fmt"

type T struct {
   x int
}

func main() {
   v := T{123}
   fmt.Println(v)
}
```

这个程序打印 {123}，尽管我们没有教 Go 如何打印我们的 T 类型。它是如何做到这一点的？

## printer 的等效性

fmt 包中的逻辑在所有 printer 之间共享，因此以下调用都保证等效：

- `fmt.Print(x)`
- `fmt.Printf("%v", x)`
- `os.Stdout.Write([]byte(fmt.Sprint(x)))`
- `os.Stdout.Write([]byte(fmt.Sprintf("%v", x)))`

换句话说，fmt.Print 的逻辑始终与将 Printf 与动词 %v 一起使用相同，前者实际使用后者作为实现。

同样，fmt.Println 使用 fmt.Print，外加 %v 动词，`fmt.Sprintln` 和 `fmt.Sprint` 是同样的道理。

## fmt.Stringer 和 fmt.Formatter

现在，在上面的代码底部添加以下内容：

```go
func (t T) String() string { return "boo" }
```

再次运行程序。会发生什么？它打印 `boo`。值 123 没有了。

这里发生的情况是，方法 String() 返回字符串实现了标准接口 fmt.Stringer，fmt 中的函数如果发现有它就会使用它。另外，尝试删除上面的 String() 函数定义，并将其替换为：

```go
func (t T) Format(s fmt.State, _ rune) {
  fmt.Fprint(s, "baa")
}
```

现在会发生什么？程序打印 `baa`。值 123 依然没有了。

如果这两个方法都可用怎么办？程序会打印 baa： fmt.Formatter 优先 fmt.Stringer。

当两个方法都不可用时，fmt 的逻辑会"回"在它自己的内部显示代码上，从而在表示值方面尽最大努力。

## fmt 对 error 知道多少？

Go 的标准 error 接口只提供返回字符串的 Error() 方法，而没有别的。

fmt 的逻辑知道 error，并知道如何使用其 Error() 方法，扩展上面解释的偏好规则：

- fmt.Formatter 优先级最高；
- 如果 fmt.Formatter 不存在，但是 error，则会使用 Error() 方法；
- 否则如果存在 fmt.Stringer，则使用它。

## %s、%v、%q 和 %x/%X 的关系

到目前为止，我们已经看到了，针对 %v 动词，fmt 的逻辑是如何可选地使用 fmt.Formatter、error 和 fmt.Stringer。

然而，在 Go 代码中使用的更常见的动词可能是 %s。%s 与 %v 的关系如何？

通常，%s 使用的逻辑与 %v 大致相同：如果 fmt.Stringer、error 或 fmt.Formatter 存在，将使用相同的偏好使用它。

当对象既不实现 String()，Error() 也不实现 Format() 时，就会出现区别。在这种情况下，％v 具有一些预定义的表示形式（例如，上例中的{123}），而 ％s 会提示“参数的类型错误”并且无法表示任何内容。

这就是为什么除非代码使用特定类型的字符串操作值，否则 Go 习惯用法通常是使用 ％v 而不是 ％s。

附加动词 ％q 和 ％x/％X 是 ％s 的变体（当 String()，Error() 和 Format() 都不可用时具有相同的限制）：

- %q 用引号引起来字符串，所以 fmt.Printf("%q", `he said "hi"`) 打印出 `he said "hi"`。
- ％x/％X 显示字符串中字节的十六进制表示形式。在实践中很少使用该方法（该方法更多用于整数）。

## 打印值，指针方法集

现在考虑上面的程序，以及以下实现的组合（注意接收器的类型）：

```go
func (t T) String() string { return "boo" }
func (t *T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
```

现在打印的是 boo。为什么是这样？上面的代码按值传递 T 实例。根据方法集的概念，只实现了 fmt.Stringer 接口，因此输出 boo。如果现在改为这样：

```go
func (t *T) String() string { return "boo" }
func (t *T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
```

输出什么？这次再次输出：{123}，因为 fmt 的逻辑“看不到”上面的方法。

因此有如下规则：如果对象按值打印，则只考虑其按值方法。（其实就是方法集问题）

## 打印引用，值方法集

现在，让我们用以下主程序：

```go
func main() {
   v := &T{123}
   fmt.Println(v)
}
```

现在考虑以下程序变体：

- 变体 A：

  ```go
  func (t T) String() string { return "boo" }
  func (t T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
  ```

- 变体 B：

  ```go
  func (t T) String() string { return "boo" }
  func (t *T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
  ```

- 变体 C：

  ```go
  func (t *T) String() string { return "boo" }
  func (t T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
  ```

- 变体 D：

  ```go
  func (t *T) String() string { return "boo" }
  func (t *T) Format(s fmt.State, _ rune) { fmt.Fprint(s, "baa") }
  ```

针对这些情况，上面的程序输出什么？都是 "baa"。

指针接收器 `*T` 的方法集包含 T 和 `*T` 的方法集。（原文作者写的不对，说变体 C 输出 "boo"）。

## 使用 %+v 动词打印

数字类型的 + 标志强制显示正值的加号，以便始终显示符号位。

然而，与 v 结合，它会触发"详细打印"。

根据 fmt 的默认逻辑，这会将字段的名称添加到结构中。

如果实现了 `fmt.Stringer` 接口，+ 不会对结果有任何改变， 如果实现了 fmt.Formatter 接口，根据约定，Format() 方法输出的信息比未指定 + 时的信息更详细。

Go 库没有规定应如何实现：不同的包往往以不同的方式实现。然而，缺乏规范不是问题；在这两种情况下，输出都供人眼使用，因此小显示不一致并不被视为问题。

## Go 语法表示和 %#v 动词

最后，将原来的主程序改为使用 %#v 动词：

```go
func main() {
   v := T{123}
   fmt.Printf("%#v\n", v)
}
```

这会打印什么？

- 如果 String() 方法可用，会忽略它；
- 如果 Format() 方法可用，则使用它；
- 如果 GoString() 方法可用（fmt.GoStringer 接口），则使用它；
- 否则，将使用 Go 语法结构的打印输出。

这里发生的情况是，%#v 说明符打算打印值的 “Go表示”，而不是它的“人类可读表示”。fmt 逻辑知道如何这样做，但是自定义类型可以用 fmt 自定义这种行为：即实现 fmt.Formatter 或 GoStringer 接口。

注意，出于完整性考虑，上面解释了 GoStringer，但在实践中，发现它很少被使用。

我个人推荐 <https://github.com/kr/pretty> 这个工具，它比 Go 的标准库更清晰地打印 Go 语法表示。例如：`fmt.Printf("%# v", pretty.Formatter(x))`。

## 格式化动词、标识和修改器

到目前为止，我们已经看到 %v 与 %s 在意图和目的上的不同，以及例 %v 与 %+v 的不同。

如果我们想用不同的结果来定义我们自己的定制呢？

对于上面三种情况，可靠的定制机制是 fmt.Formatter 接口：

```go
package fmt

// Formatter can be implemented by your custom types.
type Formatter interface {
     Format(s State, verb rune)
}

// An object of type State is provided by the fmt
// logic to your custom Format() method.
type State interface {
     io.Writer // inherits the Write() method

     Flag(int) bool

     Width() (int, bool)
     Precision() (int, bool)
}
```

最让我感兴趣的是：

- 参数 verb 直接传递给我们自定义的 Format() 方法。这表示主“格式化动词”：对于 %v，verb == ‘v’。对于 %#v，依然是 verb == ‘v’。对于 %s，verb 是 s，以此类推。
- 有 Flag() 方法的 fmt.State 作为参数传递给 Format() 方法。如果设置了相应的格式化标志，Flag() 返回 true。例如，对于 %v，`Flag('#') == false`，而对于 %#v，`Flag('#') == true`。
- 此外，fmt.State 也实现了 io.Writer 接口。这样就可以直接将状态变量作为第一个参数传递给另一个对 fmt.Fprint 的调用，进一步简化了自定义 Format() 方法的实现。

fmt.State 上的 Width() 和 Precision() 方法也很有趣，因为它们允许访问格式化字符串中的附加数值参数或修饰符。例如，在 %3.2f 中，我们有宽度 3 和精度 2。然而，这些在实践中很少被使用。

下面是一个符合 Go 习惯的例子：

```go
type Response struct {
     code int
     msg string
}

func (r *Response) Format(s fmt.State, verb rune) {
   switch verb {
   case 'v':
       if s.Flag('+') {
          // With %+v, we print both the message and the code.
          fmt.Fprintf(s, "%s (%d)", r.msg, r.code)
       }
       fallthrough
   case 's':
       // For %s, or %v without +, we just print the message.
       fmt.Fprint(s, r.msg)
   }
}

// String is provided for convenience.
func (r *Response) String() string { return fmt.Sprint(r) }
```

简单解释下：

- 以上实现中，对于 %+v，它将同时输出 msg 和 code。当只有 %v/%s，它只打印 msg。
- 为了让类型兼容 fmt.Stringer 接口，以便用于其他需要 String() 方法的地方，通过调用 fmt.Sprint 实现 String()。

下面会进一步讨论。

上面代码一个有趣的点是，它不处理 %q/%x/%x。对于这些动词，它不输出任何内容。

它也不支持除了 + 之外的其他标志，例如，它对待 %#v 和 %v 是相同的。

事实上，Go API 并没有使实现与自身内部逻辑一样通用和强大的自定义 Format() 变得容易，而且“野生的” Go 包常常包含像上面那样的不完整实现。

## 实践中自定义 Formatter

我在实践中发现，在整个生态系统的包经常按如下方式处理：

- 自定义 Format() 方法总是为 v 动词做一些有效和有用的事情，而不考虑提供的标志。
- 带有动词 v 但没有标志的 Format() 的行为（即一个简单的 %v），通常与 String() 的行为保持一致。
- 如果自定义格式化程序同时具有“简单”和“详细”模式，那么它通常将 + 识别为访问详细模式的标志。
- 如果 %s 和 %v（没有标志）都被识别，它们通常输出相同的内容。
- 在自定义 Format() 方法中正确处理 %q、%x 和 %X 的情况并不常见。
- 非数值类型的自定义格式化程序几乎从不处理宽度和精度修饰符。

最后一点特别说明了为什么关心固定宽度字符串格式的代码应该在以下两个步骤中拼写输出：

```go
s := fmt.Sprint(v)
fmt.Printf("%30s", s)  // instead of printing v directly
```

## 在 fmt.Stringer、fmt.Formatter 和 error 之间重用代码

上面的一个例子是通过调用 fmt.Sprint 实现 String()。它又在同一类型上使用 Format() 方法。简化为：

```go
type T struct { msg string }

func (r *T) Format(s fmt.State, _ rune) {
   fmt.Fprint(s, r.msg)
}

func (r *T) String() string {
   // This causes fmt to call Format() above and ultimately
   // print r.msg.
   return fmt.Sprint(r)
}
```

在这种情况下，为什么人们会选择通过返回 fmt.Sprint(r) 而不是返回 r.msg 来实现 String() 呢?

这是遵循 DRY 原则的实例：如果以后逻辑需要更改为"打印更多内容"，则只需修改 Format() 方法；String() 方法会自动从中受益。

这种模式比较常见。以下是另一种形式：

```go
type T struct { msg string }

func (r *T) String() string {
   return r.msg
}

func (r *T) Format(s fmt.State, _ rune) {
   fmt.Fprint(s, r.String()) // or: s.Write([]byte(r.String()))
}
```

同样，一个方法实现"使用另一个"，因此一个方法只需要更改其中任何一个，在两者中获得相同的行为。

同样，如果涉及 error 接口，我们会在实践中看到所有重用组合：

```go
type T struct { msg string }

func (r *T) Error() string { return r.msg }
func (r *T) String() string { return r.Error() }
func (r *T) Format(s fmt.State, _ rune) { fmt.Fprint(s, r.Error()) }

type U struct { msg string }

func (r *U) String() string { return r.msg }
func (r *U) Error() string { return r.String() }
func (r *U) Format(s fmt.State, _ rune) { fmt.Fprint(s, r.String()) }

type V struct { msg string }

func (r *V) String() string { return fmt.Sprint(r) }
func (r *V) Error() string { return fmt.Sprint(r) }
func (r *V) Format(s fmt.State, _ rune) { fmt.Fprint(s, r.msg) }
```

Q：为什么我们看到如此多样性？

A：我不太确定，但我责怪 Go 库文档中缺乏方案。另请参阅下面的两个答案。

Q：既然我们在每个情况下都得到相同的结果，这有关系吗？

A：从功能的角度来看，这些示例都是等效的。从性能角度来看，应考虑在程序中更经常使用哪些变体。如果常用 String() 方法，比打印出对象更是如此，那么让 String() 包含最简单的实现可能会产生更好的性能。这是因为 fmt 包中的逻辑有点重量级。然而请注意，在实践中，我并没有发现这种情况经常发生，所以我要说，这并不重要。

Q：我正在实现自己的自定义类型。我应该瞄准什么模式？

A：如果您的类型只有一个表示形式，直接使用 String() 即可；如果您实现错误类型，自然使用 Error() 更合适，一般都不需要实现 Format()。但如果需要区分"简单"和"详细"显示，则首先实现 Format() 然后从中派生 String() 或 Error()。

## 总结

Go 在其标准 fmt 包中提供了通用格式 API。

该 API 中的所有函数都由通用逻辑提供支持，这是 Print/Sprintf 在引擎下使用的逻辑：每个对象都显示在某种格式"动词"的上下文中。

最常见和可靠的动词是 v（提示：它是 "v"，如"value"），也被 Print() 和 Println() 使用。它可以打印几乎任何东西，并不挑剔的值是零或实现一个特定的接口。

同时，在实现自己的类型时，可以通过实现某些接口自定义 fmt 的行为：

- fmt.Stringer，一个简单的 String() string 方法；
- error，一个简单的 Error() string 方法；
- fmt.Formatter，一个 Format() 方法。当通过 %v 与 %+v 以及其他动词和标志组合使用时，这可用于显示不同的东西。

在实践中，我们看到同时提供 String() 和 Format() 方法或 Error() 和 Format() 方法的包。一个通常是通过调用另一个来实现的，以避免代码重复。Go 的标准库允许所有的组合重用，实际上我们可以在生态系统中找到所有变体。

> 原文链接：https://dr-knz.net/go-formatting-apis.html
>
> 本文作者：Raphael ‘kena’ Poss
>
> 译者：polarisxu


---
title: "注释竟然还有特殊用途？一文解惑 //go:linkname 指令"
date: 2021-04-15T20:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 指令
  - linkname
---

大家好，我是站长 polarisxu。

我之前写过一篇文章：[为什么 Go 标准库中有些函数只有签名，没有函数体？](https://mp.weixin.qq.com/s/XPRj87YT3U6hJvyY11y8jA)，其中有一点就是 `//go:linkname` 这个指令。

Go 中类似的指令挺多的，比如 Go1.16 中的 `//go:embed`。前些天有人问我，为什么它用 `//go:embed` 不起作用？我一看，它是这么写的：`// go:embed`，不知道你看到问题了没有？是的，指令是通过注释的方式，但有三点要求，要特别注意：

- `//` 后不能有空格。有些人可能习惯 `//` 后不加空格。但一般认为，`//` 后应该加一个空格。不过 go 指令却要求不能有空格，这是一个小“坑”，得注意。所以上面那位朋友就是加了空格，导致出问题。（程序并不会报错，只是没有得到自己想要的结果）
- 代码和指令之间不能有空行或其他注释。这一点应该还好，很多人不会用错吧；
- 一般来说，使用指令需要导入相应的包。比如 `//go:linkname` 指令要求导入 unsafe 包，一般会 `import _ "unsafe”`，`//go:embed` 指令，要求导入 embed 包。

有另外一位 Go 朋友「橘中秘士」微信私聊我：

> 大佬好，能不能写一篇 linkname 的文章。目前已经有了一些初步概念，但是尚有一些疑团不是特别清晰。
>
> //go:linkname localname remotename，其中 local 作为占位符 remote 作为实现者或者 local 作为实现者 remote 作为占位符都是可以的。目前理解的就是给 Symbol 添加了一个 Linkname，查找 Symbo l的时候用 remote。
>
> 譬如 //go:linkname runtimeNano runtime.nanotime，runtimeNano 作为占位符 runtime.nanotime 提供实现，任何调用 runtimeNano 的地方实际替换为对 runtime.nanotime 的调用，这种场景比较容易接受。
>
> 譬如 //go:linkname runtime_cmpstring runtime.cmpstring，runtime_cmpstring 提供实现 runtime.cmpstring作为占位符，是不是这时符号表里不存在 runtime_cmpstring 只有 runtime.cmpstring？

经过简单沟通，他写了一篇文章解决自己的困惑。希望对各位有帮助。以下是他写的关于 `//go:linkname` 的文章（我做了一些调整）。

---

## 01 格式

```go
//go:linkname local remote
```

remote 可以没有，此时 remote 使用 local 的值，效果就是 local 被导出。

## 02 local 和 remote 同时为函数

### local 作为占位符，remote 作为实现者

标准库中的例子：

```go
// 来自 time 包
//go:linkname runtimeNano runtime.nanotime
func runtimeNano() int64

// 来自 runtime 包
//go:nosplit
func nanotime() int64 {
	return nanotime1()
}
```

此时二进制文件中并没有`runtimeNano`，直接转化为对`runtime.nanotime`的调用。

### local 作为实现者，remote 作为占位符

同样来自标准库。这里存在函数没有函数体，但是被反向引用。

```go
// 在标准库的一个 internal 中
//go:linkname runtime_cmpstring runtime.cmpstring
func runtime_cmpstring(a, b string) int {
	l := len(a)
	if len(b) < l {
		l = len(b)
	}
	for i := 0; i < l; i++ {
		c1, c2 := a[i], b[i]
		if c1 < c2 {
			return -1
		}
		if c1 > c2 {
			return +1
		}
	}
	if len(a) < len(b) {
		return -1
	}
	if len(a) > len(b) {
		return +1
	}
	return 0
}

// 来自 runtime
func cmpstring(string, string) int
```

此时二进制文件中并没有`runtime_cmpstring`，对应的函数已经被命名为`runtime.cmpstring`。也就是说，实现在 internal 包，但最终通过 runtime.cmpstring 来引用。

### 一个占位符+一个汇编函数

```go
// 在标准库的一个 internal 中
//go:linkname abigen_runtime_memequal runtime.memequal
func abigen_runtime_memequal(a, b unsafe.Pointer, size uintptr) bool
```

注意`runtime.memequal`的实现并不在`runtime`包中，使用汇编实现的话并不要求必须在相应的包中。

```asm
# memequal(a, b unsafe.Pointer, size uintptr) bool
TEXT runtime·memequal(SB),NOSPLIT,$0-25
	MOVQ	a+0(FP), SI
	MOVQ	b+8(FP), DI
	CMPQ	SI, DI
	JEQ	eq
	MOVQ	size+16(FP), BX
	LEAQ	ret+24(FP), AX
	JMP	memeqbody<>(SB)
eq:
	MOVB	$1, ret+24(FP)
	RET
```

## 03 local 和 remote 同时为变量

### 两个常规变量

```go
//go:linkname overflowError runtime.overflowError
var overflowError error

//go:linkname divideError runtime.divideError
var divideError error

//go:linkname zeroVal runtime.zeroVal
var zeroVal [maxZero]byte

//go:linkname _iscgo runtime.iscgo
var _iscgo bool = true

//go:cgo_import_static x_cgo_setenv
//go:linkname x_cgo_setenv x_cgo_setenv
//go:linkname _cgo_setenv runtime._cgo_setenv
var x_cgo_setenv byte
var _cgo_setenv = &x_cgo_setenv

//go:cgo_import_static x_cgo_unsetenv
//go:linkname x_cgo_unsetenv x_cgo_unsetenv
//go:linkname _cgo_unsetenv runtime._cgo_unsetenv
var x_cgo_unsetenv byte
var _cgo_unsetenv = &x_cgo_unsetenv
```

### 一个占位符+一个伪符号

```go
//go:linkname runtime_inittask runtime..inittask
var runtime_inittask initTask

//go:linkname main_inittask main..inittask
var main_inittask initTask
```

注意是`..inittask`不是`.inittask`，而且`.inittask`只存在于编译阶段，任何包中都无法声明该变量。

> 这里额外解释下 ..inittask 为什么两个点。第一个点就是普通的 runtime. 这种调用方式，第二个点和 inittask 一起构成一个符号（变量）。注意，Go 中的变量是不允许以 . 开头的，所以，这个叫伪符号，只在不编译阶段存在。

## 04 一个例子

研究 `//go:linkname` 是因为如下的背景：

> Java 里有 InheritableThreadLocal，SpringWeb 在 ServletActionContext 里使用它，达到在任何地方都能方便的获取HttpServletRequest。
>
> Go 并没有提供类似的机制，即使通过 stack 找到 goroutine id（99% 的文章都是这么介绍的），再配合 sync.Map，也只是实现了一个比较粗糙的 ThreadLocal，在子协程里仍然获取不到父协程的内容。
>
> g.label 虽然不是给这种场景准备的，但它具备了 InheritableThreadLocal 的一切要求，只要我们能够访问到 label 私有字段，我们就有了完整版的 InheritableThreadLocal。

下面这个例子是作者真实项目中用的。

在 runtime 和 runtime/pprof 包中有两个函数：runtime_setProfLabel 和  runtime_getProfLabel。其中，runtime 包中的提供了实现，而 pprof 中的没有提供实现。如果基于它们创建另外的函数，如下：

```go
//go:linkname SetPointer runtime/pprof.runtime_setProfLabel
func SetPointer(ptr unsafe.Pointer)

//go:linkname GetPointer runtime/pprof.runtime_getProfLabel
func GetPointer() unsafe.Pointer
```

根据前面的分析，虽然`runtime.runtime_setProfLabel`/`runtime.runtime_getProfLabel`提供了函数实现，但是二进制文件中并不会出现（见下方代码），此时想要调用必须通过`runtime/pprof.runtime_setProfLabel`/`runtime/pprof.runtime_getProfLabel`，这也是上面`linkname`到`pprof`而不是`runtime`的根本原因。

```go
// 来自 runtime 包
//go:linkname runtime_setProfLabel runtime/pprof.runtime_setProfLabel
func runtime_setProfLabel(labels unsafe.Pointer) {
	if raceenabled {
		racereleasemerge(unsafe.Pointer(&labelSync))
	}
	getg().labels = labels
}

// 来自 runtime/pprof 包
func runtime_setProfLabel(labels unsafe.Pointer)

// 来自 runtime 包
//go:linkname runtime_getProfLabel runtime/pprof.runtime_getProfLabel
func runtime_getProfLabel() unsafe.Pointer {
	return getg().labels
}

// 来自 runtime/pprof 包
func runtime_getProfLabel() unsafe.Pointer
```

## 05 总结

Go 中有不少指令，有些指令你可能不太需要关心，也不会用到。然而有些指令了解它们的意思，对阅读相关代码很有帮助。

这篇文章全面介绍了 `//go:linkname` 指令，不知道是否彻底解除了你的疑惑？欢迎留言交流！


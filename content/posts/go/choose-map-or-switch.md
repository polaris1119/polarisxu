---
title: "map 和 switch 如何选？match 又是什么？"
date: 2021-03-17T23:00:00+08:00
toc: true
isCJKLanguage: true
tags:
  - Go
  - 基准测试
---

大家好，我是站长 polarisxu。

看到标题别惊讶，虽然 map 和 switch 似乎没啥关系，但有些场景它们俩都可以用。

场景一：根据不同的错误码显示对应错误消息，比如 200 -> 正常。

场景二：根据不同状态显示对应的文案。这个场景很常见，比如数据库保存状态，用的 tinyint 类型，显示给用户的是文本，所以需要进行转换。

具体怎么选？我们看一下代码，怎么选择应该一目了然。

```go
const (
	UnPay = iota
	HadPay
	Delivery
	Finish
)

var orderState = map[int]string{
	UnPay:    "未支付",
	HadPay:   "已支付",
	Delivery: "配送中",
	Finish:   "已完成",
}

// map 实现
func OrderStateMap(state int) string {
	return orderState[state]
}

// switch 实现
func OrderStateSwitch(state int) string {
	var stateDesc = ""

	switch state {
	case UnPay:
		stateDesc = "未支付"
	case HadPay:
		stateDesc = "已支付"
	case Delivery:
		stateDesc = "配送中"
	case Finish:
		stateDesc = "已完成"
	}

	return stateDesc
}
```

“大人，有结果了吗？”

从这个例子看，用 map 代码更少，可读性更好，而且用 map 管理这个映射关系语义上也更符合实际。

所以，我为什么写文章提这一点呢？

别急，我们先对以上两种实现做一下基准测试。

```go
func BenchmarkSwitch(b *testing.B) {
	for n := 0; n < b.N; n++ {
		OrderStateSwitch(0)
		OrderStateSwitch(1)
		OrderStateSwitch(2)
		OrderStateSwitch(3)
	}
}

func BenchmarkMap(b *testing.B) {
	for n := 0; n < b.N; n++ {
		OrderStateMap(0)
		OrderStateMap(1)
		OrderStateMap(2)
		OrderStateMap(3)
	}
}
```

结果如下：

```bash
$ go test -bench=.
goos: darwin
goarch: amd64
pkg: test/map
cpu: Intel(R) Core(TM) i5-8259U CPU @ 2.30GHz
BenchmarkSwitch-8   	1000000000	         0.2868 ns/op
BenchmarkMap-8      	70925238	        16.91 ns/op
PASS
ok  	test/map	2.153s
```

switch 版本比 map 版本快了近 60 倍。此外，要较真的话，map 版本还用了一个 map 数据结构，占用额外的空间。

性能差别这么大，其实通过汇编可以看到 map 版本调用了一个 runtime.mapaccess2 _ fast64(SB) 函数：

```bash
0x001d 00029 (main_test.go:22)	MOVQ	"".orderState(SB), AX
0x0024 00036 (main_test.go:22)	LEAQ	type.map[int]string(SB), CX
0x002b 00043 (main_test.go:22)	MOVQ	CX, (SP)
0x002f 00047 (main_test.go:22)	MOVQ	AX, 8(SP)
0x0034 00052 (main_test.go:22)	MOVQ	"".state+48(SP), AX
0x0039 00057 (main_test.go:22)	MOVQ	AX, 16(SP)
0x003e 00062 (main_test.go:22)	PCDATA	$1, $0
0x003e 00062 (main_test.go:22)	NOP
0x0040 00064 (main_test.go:22)	CALL	runtime.mapaccess1_fast64(SB)
0x0045 00069 (main_test.go:22)	MOVQ	24(SP), AX
0x004a 00074 (main_test.go:22)	MOVQ	(AX), CX
0x004d 00077 (main_test.go:22)	MOVQ	8(AX), AX
0x0051 00081 (main_test.go:22)	MOVQ	CX, "".~r1+56(SP)
0x0056 00086 (main_test.go:22)	MOVQ	AX, "".~r1+64(SP)
0x005b 00091 (main_test.go:22)	MOVQ	32(SP), BP
0x0060 00096 (main_test.go:22)	ADDQ	$40, SP
0x0064 00100 (main_test.go:22)	RE
```

而 switch 版本只是普通的指令：

```bash
0x0000 00000 (main_test.go:28)	MOVQ	"".state+8(SP), AX
0x0005 00005 (main_test.go:28)	CMPQ	AX, $1
0x0009 00009 (main_test.go:28)	JGT	66
0x000b 00011 (main_test.go:29)	TESTQ	AX, AX
0x000e 00014 (main_test.go:29)	JNE	39
0x0010 00016 (main_test.go:29)	MOVL	$9, AX
0x0015 00021 (main_test.go:29)	LEAQ	go.string."未支付"(SB), CX
0x001c 00028 (main_test.go:39)	MOVQ	CX, "".~r1+16(SP)
0x0021 00033 (main_test.go:39)	MOVQ	AX, "".~r1+24(SP)
0x0026 00038 (main_test.go:39)	RET
0x0027 00039 (main_test.go:28)	CMPQ	AX, $1
0x002b 00043 (main_test.go:31)	JNE	59
0x002d 00045 (main_test.go:31)	MOVL	$9, AX
0x0032 00050 (main_test.go:31)	LEAQ	go.string."已支付"(SB), CX
0x0039 00057 (main_test.go:32)	JMP	28
0x003b 00059 (main_test.go:32)	XORL	AX, AX
0x003d 00061 (main_test.go:32)	XORL	CX, CX
0x003f 00063 (main_test.go:32)	NOP
0x0040 00064 (main_test.go:28)	JMP	28
0x0042 00066 (main_test.go:33)	CMPQ	AX, $2
0x0046 00070 (main_test.go:33)	JNE	86
0x0048 00072 (main_test.go:33)	MOVL	$9, AX
0x004d 00077 (main_test.go:33)	LEAQ	go.string."配送中"(SB), CX
0x0054 00084 (main_test.go:34)	JMP	28
0x0056 00086 (main_test.go:35)	CMPQ	AX, $3
0x005a 00090 (main_test.go:35)	JNE	59
0x005c 00092 (main_test.go:35)	MOVL	$9, AX
0x0061 00097 (main_test.go:35)	LEAQ	go.string."已完成"(SB), CX
0x0068 00104 (main_test.go:36)	JMP	28
```

“大人，有结果了吗？”

似乎应该使用 switch，它性能好呀！这就需要在可读性和性能之间做一个权衡。看到一篇文章说，[优化 Go 程序的性能就是浪费时间](https://mp.weixin.qq.com/s/jJM0N5yk9kk4w92yI8jjoQ)，通常更应该优化的是可读性。不管这个观点如何，但程序的可读性确实很重要。如果性能没那么关键，或提升对整个程序性能作用不大，我们通常应该先考虑可读性。

很显然这种场景，map 会是更好的选择。

其实在 Go 标准库中有类似这样的使用场景，比如 net/http 包中的 [StatusText](https://docs.studygolang.com/src/net/http/status.go?s=7372:7404#L150) 函数，它根据状态码获得对应的说明；还有连接状态对应 [ConnState](https://docs.studygolang.com/src/net/http/server.go?s=90775:90809#L2859) 的说明：

```go
var stateName = map[ConnState]string{
	StateNew:      "new",
	StateActive:   "active",
	StateIdle:     "idle",
	StateHijacked: "hijacked",
	StateClosed:   "closed",
}

func (c ConnState) String() string {
	return stateName[c]
}
```

特别是当需要映射的内容很多时，更应该使用的 map 方式，毕竟看到一大堆 case 会疯掉。

题外话：可能正是因为类似的需求很常见，而 switch 似乎太繁琐，于是 Rust 中没有 switch，而是提供了 match 表达式，Rust 代码如下：

```rust
enum State {
	Unpay,
	HadPay,
	Delivery,
	Finish,
}

fn OrderState(state: State) -> &'static str {
    match state {
        State::Unpay => "未支付",
        State::HadPay => "已支付",
        State::Delivery => "配送中",
        State::Finish => "已完成",
    }
}

fn main() {
    println!("{}", OrderState(State::Unpay));
}
```

PHP 在 8.0 也提供了 match 表达式，比如：

```php
$orderState = match($state) {
  0 => '未支付',
  1 => '已支付',
  2 => '配送中',
  3 => '已完成',
}
```

match 表达式是不是很 map 的方式很像？！

总结一下：开发时，尽量优先考虑可读性，在必要时才进行性能优化，而且要保证优化确实是能带来较大收益的。


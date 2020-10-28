---
title: "Echo 系列教程——定制篇3：自定义 Logger，用你喜欢的日志库"
date: 2020-03-06T11:50:51+08:00
toc: true
isCJKLanguage: true
tags: 
  - echo
  - web框架
  - 日志库
---

在知识星球简书项目中，我们分析对比了目前的一些日志库。虽然 Go 标准库有一个 log，但功能有限，所以才出现了很多第三方的日志库。在 [用 Go 实现一个简书 8：日志记录和优秀库的学习](https://studygolang.com/topics/10625) 中，我们得出结论，推荐大家使用 [zerolog](https://github.com/rs/zerolog)。现在我们就将 zerolog 集成进 Echo 框架中。

## Echo 默认的 Logger

Echo 日志记录的默认格式是 JSON，可以通过修改标头来更改，即 `Echo#Logger.SetHeader(io.Writer)`。

### Log Header

标头默认值为：

```json
{"time":"${time_rfc3339_nano}","level":"${level}","prefix":"${prefix}","file":"${short_file}","line":"${line}"}
```

因为 Echo 默认使用的 Logger 是作者开发的 `github.com/labstack/gommon/log` 库，我们看看怎么自定义默认标头。

```go
import "github.com/labstack/gommon/log"

/* ... */

if l, ok := e.Logger.(*log.Logger); ok {
  l.SetHeader("${time_rfc3339} ${level}")
}
```

这样输出的标头成为：`2018-05-08T20:30:06-07:00 INFO info`。

目前，预定义的 tag 有：

- `time_rfc3339`：时间格式
- `time_rfc3339_nano`：带纳秒的时间格式
- `level`：级别
- `prefix`：前缀
- `long_file`：长文件名（带路径）
- `short_file`：短文件名（不带路径）
- `line`：文件行号

### Log 输出

`Echo#Logger.SetOutput(io.Writer)` 可以设置日志输出的目的地。默认输出到标准输出。如果想禁用日志，有两种方式：

- Echo#Logger.SetOutput(ioutil.Discard)
- Echo#Logger.SetLevel(log.OFF)

### Log 级别

默认情况下，日志的级别是 ERROR。可以通过 `Echo#Logger.SetLevel(log.Lvl)` 修改。一共有如下一些级别：

- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`
- `OFF`

以上就是 Echo 框架提供的可以定制 Log 的相关接口。

## 自定义 Logger

Echo 支持通过`Echo#Logger` 注册自定义的 Logger，前提是这个 Logger 必须实现 Echo 提供的接口：echo.Logger：

```go
type Logger interface {
    Output() io.Writer
    SetOutput(w io.Writer)
    Prefix() string
    SetPrefix(p string)
    Level() log.Lvl
    SetLevel(v log.Lvl)
    SetHeader(h string)
    Print(i ...interface{})
    Printf(format string, args ...interface{})
    Printj(j log.JSON)
    Debug(i ...interface{})
    Debugf(format string, args ...interface{})
    Debugj(j log.JSON)
    Info(i ...interface{})
    Infof(format string, args ...interface{})
    Infoj(j log.JSON)
    Warn(i ...interface{})
    Warnf(format string, args ...interface{})
    Warnj(j log.JSON)
    Error(i ...interface{})
    Errorf(format string, args ...interface{})
    Errorj(j log.JSON)
    Fatal(i ...interface{})
    Fatalj(j log.JSON)
    Fatalf(format string, args ...interface{})
    Panic(i ...interface{})
    Panicj(j log.JSON)
    Panicf(format string, args ...interface{})
}
```

这个接口看着很吓人，基本上是几个日志级别对应的方法。因此，如果我们要将 zerolog 集成进 Echo，让 zerolog 实现该接口（zerolog 本身肯定没有实现该接口）。

因为 zerolog 库的设计和 API 与 echo.Logger 接口差异极大，想要直接为 zerolog 实现一个 Adapter 以便实现 echo.Logger 接口不太现实。于是我们做如下处理来进行适配：

```go
type Logger struct {
	*log.Logger
	ZeroLog zerolog.Logger
}
```

我们定义一个自己的 Logger 结构体，内嵌一个 github.com/labstack/gommon/log 库的 Logger 指针，这样默认就实现了 echo.Logger 接口，然后再是 zerolog.Logger。看看构造函数如何实现？

```go
func New(writer io.Writer) *Logger {
	l := &Logger{
		Logger:  log.New("-"),
		ZeroLog: zerolog.New(writer).With().Caller().Timestamp().Logger(),
	}
  
	// log 默认是 ERROR，将 Level 默认都改为 INFO
	l.SetLevel(log.INFO)

	l.Logger.SetOutput(writer)

	return l
}
```

这么做有什么用？还不如干脆 echo 框架自己的日志由它处理，我们的日志使用 zerolog 处理。这样当然是可以的。但集成在一起有如下好处：

- 形式上变成了一个日志类，也就是我们自定义的 Logger；
- 方便统一控制，比如输出目标、日志级别；
- 通过一个日志库，既可以做到单独控制 echo 的行为，也可以单独控制 zerolog 的行为；

那统一控制行为如何实现呢？这里实现了两个，控制输出目的地和日志级别。

```go
func (l *Logger) SetOutput(writer io.Writer) {
	l.Logger.SetOutput(writer)
	l.ZeroLog.Output(writer)
}

func (l *Logger) SetLevel(level log.Lvl) {
	l.Logger.SetLevel(level)
	if level == log.OFF {
		l.ZeroLog = l.ZeroLog.Level(zerolog.Disabled)
	} else {
		zeroLevel := int8(level) - 1
		l.ZeroLog = l.ZeroLog.Level(zerolog.Level(zeroLevel))
	}
}
```

当然这种方式也有麻烦的地方，那就是通过 echo 的 Context 获得 zerolog 日志实例：

```go
zerolog := ctx.Logger().(*logger.Logger).ZeroLog
```

这样自定义日志库就完成了。该库完整代码见：<https://github.com/polaris1119/go-echo-example/blob/master/pkg/logger/logger.go>。

## 在 Echo 项目中使用自定义日志库

在 go-echo-example 项目的 cmd 下创建一个目录 gopher，将来我们的实战篇就用它作为入口。之后创建一个 main.go 文件，核心代码如下：

```go
func main() {
	e := echo.New()

	e.Logger = logger.New(os.Stdout)
  // e.Logger.SetLevel(log.DEBUG)

	e.Use(middleware.Recover())

	e.GET("/", func(ctx echo.Context) error {
    ctx.Logger().Debugf("This is echo logger debug msg!")

		zerolog := ctx.Logger().(*logger.Logger).ZeroLog
		zerolog.Debug().Str("path", ctx.Path()).Msg("This is Debug msg!")

		return ctx.HTML(http.StatusOK, "Hello World!")
	})

	e.Logger.Fatal(e.Start(":2020"))
}
```

我们得到 echo 的实例后，将其日志设置为我们自定义的 logger：`e.Logger = logger.New(os.Stdout)`。注意注释掉的代码。运行程序：go run main.go，打开浏览器访问 http://localhost:2020 ，看看日志是否有两条 Debug 记录。接着将注释去掉再次测试，看日志是否有输出。

不出意外，一切都符合预期。恭喜你大功告成！

[完整代码点这里](https://github.com/polaris1119/go-echo-example/tree/091967f4bea4a3f9ee7c20411f15287d2c950e02)。


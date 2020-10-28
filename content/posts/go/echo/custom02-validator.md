---
title: "Echo 系列教程——定制篇2：自定义 Validator，进行输入校验"
date: 2020-02-28T18:53:51+08:00
toc: true
isCJKLanguage: true
tags: 
  - echo
  - web框架
  - validator
---

上一篇讲 Binder 时提到，参数自动绑定和校验是 Web 框架很重要的两个功能，可以极大的提升开发速度，并更好的保证数据的可靠性（服务端数据校验很重要）。本节，我们就一起看看如何自定义 Echo 的表单校验功能。

不同于 Binder，Echo 并没有内置数据校验的能力，也就是没有默认的 Validator 实现。然而，你可以很方便的集成第三方的数据校验库。跟 Binder 类似，Echo 提供了一个 Validator 接口，方便将第三方数据校验库集成进来。

```go
Validator interface {
  Validate(i interface{}) error
}
```

通过这个实现这个接口，可以很方便的将任何第三方数据校验库集成到 Echo 中。在 Awesome-Go 上可以找到第三方数据校验库：<https://github.com/avelino/awesome-go#validation>。本文我们使用最流行的 <https://github.com/go-playground/validator> 库来讲解。

## go-playground/validator

这是一个 Go 结构体及字段校验器，包括：跨字段和跨结构体校验，Map，切片和数组，是目前校验器相关库中 Star 数最高的一个，对国际化支持也很好，建议大家使用它。

它具有以下独特功能：

- 通过使用验证标签（tag）或自定义验证程序进行跨字段和跨结构体验证；
- 切片，数组和 map，可以验证任何的多维字段或多层级；
- 能够深入（多维）了解 map 键和值以进行验证；
- 通过在验证之前确定其基础类型来处理接口类型；
- 处理自定义字段类型，例如 sql driver Valuer；
- 别名验证标签，允许将多个验证映射到单个标签，以便更轻松地定义结构上的验证；
- 提取自定义定义的字段名称，例如可以指定在验证时提取 JSON 名称，并将其用于结果 FieldError 中；
- 可自定义的 i18n 错误消息；
- gin Web 框架的默认验证器；

### 一个简单的例子

通过一个简单例子来看看如何使用该库。

```go
package main

import (
	"fmt"
	"flag"

	"github.com/go-playground/validator/v10"
)

type User struct {
	Name  string `validate:"required"`
	Age   uint   `validate:"gte=1,lte=130"`
	Email string `validate:"required,email"`
}

var (
	name  string
	age   uint
	email string
)

func init() {
	flag.StringVar(&name, "name", "", "输入名字")
	flag.UintVar(&age, "age", 0, "输入年龄")
	flag.StringVar(&email, "email", "", "输入邮箱")
}

func main() {
	flag.Parse()

	user := &User{
		Name:  name,
		Age:   age,
		Email: email,
	}

	validate := validator.New()
	err := validate.Struct(user)
	if err != nil {
		fmt.Println(err)
	}
}
```

执行如下命令，运行代码：

```
go run main.go -name studygolang -age 7 -email polaris@studygolang.com
```

什么都没有输出，表示一切正常。如果我们提供一个非法的邮箱地址：

```
go run main.go -name studygolang -age 7 -email polaris@studygolang
```

输出如下错误：

```
Key: 'User.Email' Error:Field validation for 'Email' failed on the 'email' tag
```

错误显示不友好。怎么能够更友好，并进行国际化呢？

### 国际化（i18n）

在介绍校验库错误消息国际化之前，有一个概念需要了解下，那就是 CLDR。

#### 什么是 CLDR？

它是 i18n 的一套核心规范（ Common Locale Data Respository），即通用的本地化数据存储库，什么意思呢？比如我们的手机，电脑都可以选择语言模式为 英语、汉语、日语、法语等等，这套操作背后的规范，就是 CLDR；CLDR 是以 Unicode 的编码标准作为前提，将多国的语言文字进行编码的。

看看官方对于 CLDR 的说明，官方网址：<http://cldr.unicode.org/>

> Unicode CLDR 提供了支持世界语言的软件的关键构建块，并且具有最大和最广泛的本地设置数据标准存储库。大量的公司使用此数据进行软件的国际化和本地化，使它们的软件适应此类通用软件任务的不同语言的约定。

需要进行国际化和本地化的主要包括：

- 用于格式化和解析的特定于语言环境的模式：日期，时间，时区，数字和货币值，度量单位，…
- 名称的翻译：语言，脚本，国家和地区，货币，时代，月份，工作日，白天，时区，城市和时间单位，表情符号字符和序列（和搜索关键字），…
- 语言和文字信息：使用的字符；复数情况；性别；大写；分类和搜索规则；写作方向；音译规则；拼写数字的规则；将文本分割成字符，单词和句子的规则；键盘布局…
- 国家/地区信息：语言使用情况，货币信息，日历首选项，星期惯例等…
- 有效性：Unicode 语言环境，语言，脚本，区域和扩展名的定义，别名和有效性信息，…

#### CLDR 的 Go 语言实现

本文讲解的校验库是 go-playground 这个组织创建的，它们还提供了其他的一些有用库，其中就包括了 CLDR 的 Go 语言实现，这就是 [locales](https://github.com/go-playground/locales)。

> 该库是从 CLDR 项目生成的一组语言环境，可以单独使用或在 i18n 软件包中使用；这些是专为 <https://github.com/go-playground/universal-translator> 构建的，但也可以单独他用。

这引出了该组织的另外一个库：[universal-translator](https://github.com/go-playground/universal-translator)。

[universal-translator](https://github.com/go-playground/universal-translator)：一个使用 CLDR 数据+复数规则（比如英语很多复数规则是加 s）的 Go i18n 转换器（翻译器）。该库是  [locales](https://github.com/go-playground/locales) 的薄包装，以便存储和翻译文本，供你在应用程序中使用。

#### universal-translator 简明教程

这个通用的翻译器包主要包含了两个核心数据结构：Translator 接口和 UniversalTranslator 结构体，其他的是错误类型。我们先看 Translator 接口。（注意，该包的包名是 ut）

**Translator 接口**

```go
type Translator interface {
    locales.Translator

    // adds a normal translation for a particular language/locale
    // {#} is the only replacement type accepted and are ad infinitum
    // eg. one: '{0} day left' other: '{0} days left'
    Add(key interface{}, text string, override bool) error

    // adds a cardinal plural translation for a particular language/locale
    // {0} is the only replacement type accepted and only one variable is accepted as
    // multiple cannot be used for a plural rule determination, unless it is a range;
    // see AddRange below.
    // eg. in locale 'en' one: '{0} day left' other: '{0} days left'
    AddCardinal(key interface{}, text string, rule locales.PluralRule, override bool) error

    // adds an ordinal plural translation for a particular language/locale
    // {0} is the only replacement type accepted and only one variable is accepted as
    // multiple cannot be used for a plural rule determination, unless it is a range;
    // see AddRange below.
    // eg. in locale 'en' one: '{0}st day of spring' other: '{0}nd day of spring'
    // - 1st, 2nd, 3rd...
    AddOrdinal(key interface{}, text string, rule locales.PluralRule, override bool) error

    // adds a range plural translation for a particular language/locale
    // {0} and {1} are the only replacement types accepted and only these are accepted.
    // eg. in locale 'nl' one: '{0}-{1} day left' other: '{0}-{1} days left'
    AddRange(key interface{}, text string, rule locales.PluralRule, override bool) error

    // creates the translation for the locale given the 'key' and params passed in
    T(key interface{}, params ...string) (string, error)

    // creates the cardinal translation for the locale given the 'key', 'num' and 'digit' arguments
    //  and param passed in
    C(key interface{}, num float64, digits uint64, param string) (string, error)

    // creates the ordinal translation for the locale given the 'key', 'num' and 'digit' arguments
    // and param passed in
    O(key interface{}, num float64, digits uint64, param string) (string, error)

    //  creates the range translation for the locale given the 'key', 'num1', 'digit1', 'num2' and
    //  'digit2' arguments and 'param1' and 'param2' passed in
    R(key interface{}, num1 float64, digits1 uint64, num2 float64, digits2 uint64, param1, param2 string) (string, error)

    // VerifyTranslations checks to ensures that no plural rules have been
    // missed within the translations.
    VerifyTranslations() error
}
```

关于该接口需要需要如下几点说明

- 内嵌了 locales.Translator 接口；
- 几类复数规则：cardinal plural（基数复数规则，即单数和复数两种）；ordinal plural（序数复数规则，如 1st, 2nd, 3rd…）；ordinal plural （范围复数规则，如 0-1）。对中文来说，这里大部分不需要。
- 几个 Add 方法，和上面几类规则对应；一个 key 和 一个带站位符的 text；
- 单字符的几个方法和 Add 几个方法的对应关系：T -> Add；C -> AddCardinal；O -> AddOrdinal；R -> AddRange ；表示用具体的值替换 key 表示的文本 text 中的占位符。
- 以上方法参数中，num 表示占位符处的值，但对于有复数形式的语言，这个值必须符合复数语言的规范，否则会报错；digits 表示 num 值的有效数字（或者说小数位数）；
- VerifyTranslations 确保翻译库中没有缺少对应的语言规则；

**UniversalTranslator 结构体**

它用于保存所有语言环境和翻译数据。该结构体方法不多，我们关注几个核心的。

```go
func New(fallback locales.Translator, supportedLocales ...locales.Translator) *UniversalTranslator
```

New 返回一个 UniversalTranslator 实例，该实例具有后备语言环境（fallback）和应支持的语言环境（supportedLocales）。可以看到，New 函数接收的参数是 locales.Translator 类型，因此我们肯定需要用到 locales 包。

得到 UniversalTranslator 实例后，需要获得 universal-translator 包中的 Translator 接口实例，这就用到了下面几个方法。

1）GetTranslator

```go
func (t *UniversalTranslator) GetTranslator(locale string) (trans Translator, found bool)
```

返回给定语言环境的指定翻译器，如果未找到，则返回后备语言环境的翻译器（即 New 中的 fallback）。

2）GetFallback

```go
func (t *UniversalTranslator) GetFallback() Translator
```

直接返回后备语言环境的翻译器。

3）FindTranslator

```go
func (t *UniversalTranslator) FindTranslator(locales ...string) (trans Translator, found bool)
```

尝试根据语言环境数组查找翻译器，并返回它可以找到的第一个翻译器，否则返回后备翻译器。

总结来说，New 函数加上这三个方法，相当于是 locales.Translator 到 ut.Translator 的转换。

**示例**

通过一个实际的例子来学习下这两个包的使用。

```go
package main

import (
	"flag"
	"fmt"

	"github.com/go-playground/locales"
	"github.com/go-playground/locales/en"
	"github.com/go-playground/locales/zh"
	"github.com/go-playground/locales/zh_Hant_TW"
	ut "github.com/go-playground/universal-translator"
)

var universalTraslator *ut.UniversalTranslator

func main() {
	acceptLanguage := flag.String("language", "zh", "语言")
	flag.Parse()

	e := en.New()
	universalTraslator = ut.New(e, e, zh.New(), zh_Hant_TW.New())

	translator, _ := universalTraslator.GetTranslator(*acceptLanguage)

	switch *acceptLanguage {
	case "zh":
		translator.Add("welcome", "欢迎 {0} 来到 studygolang.com！", false)
		translator.AddCardinal("days", "你只剩 {0} 天时间可以注册", locales.PluralRuleOther, false)
		translator.AddOrdinal("day-of-month", "第{0}天", locales.PluralRuleOther, false)
		translator.AddRange("between", "距离 {0}-{1} 天", locales.PluralRuleOther, false)
	case "en":
		translator.Add("welcome", "Welcome {0} to studygolang.com.", false)
		translator.AddCardinal("days", "You have {0} day left to register", locales.PluralRuleOne, false)
		translator.AddOrdinal("day-of-month", "{0}st", locales.PluralRuleOne, false)
		translator.AddRange("between", "It's {0}-{1} days away", locales.PluralRuleOther, false)
	}

	fmt.Println(translator.T("welcome", "polaris"))
	fmt.Println(translator.C("days", 1, 0, translator.FmtNumber(1, 0)))
	fmt.Println(translator.O("day-of-month", 1, 0, translator.FmtNumber(1, 0)))
	fmt.Println(translator.R("between", 1, 0, 2, 0, translator.FmtNumber(1, 0), translator.FmtNumber(2, 0)))
}
```

主要通过这个例子说明相关函数的使用。

- 根据 acceptLanguage 的不同值，设置不同的语言文案；
- 对于中文来说，没有复数，因此 AddXX 三个方法的第二个参数都是 locales.PluralRuleOther，表示该语言环境没有复数形式；
- 英文环境下，PluralRule 规则不能乱填，根据实际情况来；
- 最后在实际填充值时，num 表示占位符要填入的值，digits 表示 num 这个值最终要保留几位小数；
- FmtNumber 方法的参数需要和前面的 num 和 digits 对应上，第一个参数是 num 的值，第二个是 digits 的值；

### Validator 怎么和以上两个库集成提供 i18n

Validator 库提供了相应的子库，对以上两个库进行了封装。比如中文的库：github.com/go-playground/validator/translations/zh ，这些子库提供了一个 RegisterDefaultTranslations ，为所有内置标签的验证器注册一组默认翻译。

```go
func RegisterDefaultTranslations(v *validator.Validate, trans ut.Translator) (err error)
```

具体怎么做？还是看最开始的例子，其他不变，main 函数改为如下：

```go
func main() {
	flag.Parse()

	user := &User{
		Name:  name,
		Age:   age,
		Email: email,
	}

	validate := validator.New()

	e := en.New()
	uniTrans := ut.New(e, e, zh.New(), zh_Hant_TW.New())
	translator, _ := uniTrans.GetTranslator("zh")
	zh_translate.RegisterDefaultTranslations(validate, translator)

	err := validate.Struct(user)
	if err != nil {
		errs := err.(validator.ValidationErrors)
		for _, err := range errs {
			fmt.Println(err.Translate(translator))
		}
	}
}
```

注册一个默认的中文翻译器，在校验出错后，对错误进行翻译。不输入任何参数运行程序，输出：

> Name为必填字段
> Age必须大于或等于1
> Email为必填字段

大功告成。

## 将 Validator 集成到 Echo 中

首先，需要定义一个类型，实现 Echo 的接口 Validator ：

```go
type CustomValidator struct {
	once     sync.Once
	validate *validator.Validate
}

func (c *CustomValidator) Validate(i interface{}) error {
	c.lazyInit()
	return c.validate.Struct(i)
}

func (c *CustomValidator) lazyInit() {
	c.once.Do(func() {
		c.validate = validator.New()
	})
}
```

因为 validator.Validate 实例化做了不少事情，这里将实例化推迟到使用时。简单几行代码就实现了一个自定义的 Validator。

接下来和 Echo 集成起来就很容易了。

```go
e := echo.New()
e.Validator = &CustomValidator{}
```

之后就可以在需要进行表单校验的地方通过 `ctx.Validate()` 进行校验。

自此我们完成了 Validator 集成到 Echo 的功能。

还剩最后一块内容，那就是校验错误信息的国际化显示。国际化相关的内容，上面有了较详细的介绍，Validator 集成到 Echo 后如何国际化我们在后面实战篇再讲。

完整代码见：<https://github.com/polaris1119/go-echo-example/blob/master/pkg/validator/validator.go>。

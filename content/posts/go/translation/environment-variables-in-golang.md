---
title: "Golang 中的环境变量"
date: 2020-11-05T18:12:00+08:00
toc: true
isCJKLanguage: true
draft: true
tags: 
  - cheatsheet
  - tool
---

了解环境变量以及在 Golang 应用程序中使用它们的不同方法。

## 开始之前

本教程假定您具有：

- 对 Go 语言的基本了解
- 系统上安装了最新 Golang 版本
- 几分钟的时间

在本文中，我们将了解环境变量以及为什么要使用它们。并且将使用内置和第三方程序包在 Go 应用程序中访问它们。

## 什么是环境变量？

环境变量是系统级的键-值对，正在运行的进程可以访问它。这些通常用于使同一程序在不同的部署环境（例如 PROD， DEV 或 TEST）中表现不同。在环境中存储配置是 twelve-factor 应用程序的原理之一。它使应用程序具有可移植性。

## 为什么要使用环境变量

- 如果您在代码中使用敏感信息，那么所有有权访问该代码的未授权用户都将拥有敏感数据，您可能不希望如此。
- 如果您使用的代码版本控制工具如：`git`，那么可以将DB凭据与代码一起推送，它将公开。
- 如果要在一处管理变量，则可以进行任何更改，而不必在应用程序代码中的所有位置都进行更改。
- 您可以管理多个部署环境，例如PROD，DEV或TEST。在部署之间可以轻松更改环境变量，而无需更改任何应用程序代码。

> 永远不要忘记在.gitignore中包含环境变量文件

## 内置操作系统包

您不需要任何外部程序包即可访问Golang中的环境变量，并且可以使用标准`os`程序包来实现。以下是与环境变量有关的功能及其用途的列表。

- `os.Setenv()` 设置环境值的值。
- `os.Getenv()` 获取由键命名的值环境变量。
- `os.Unsetenv()`删除由键命名的单个环境值，如果我们尝试使用`os.Getenv()`它来获取该环境值，则将返回一个空值。
- `os.ExpandEnv`根据环境变量的值替换字符串中的$ {var}或$ var。如果不存在任何环境变量，则将使用空字符串替换它。
- `os.LookupEnv()`获取由键命名的值环境变量。如果系统中不存在该变量，则返回值将为空，并且布尔值将为false。否则，它将返回值（可以为空），并且布尔值为true。

> 如果不存在环境变量，则os.Getenv（）将返回一个空字符串，使用LookupEnv来区分空值和未设置值。

现在，让我们在代码中使用上述所有功能。在一个空文件夹中创建一个main.go文件。

```
package main

import (
  "fmt"
  "os"
)

func main() {
  // Set Environment Variables
  os.Setenv("SITE_TITLE", "Test Site")
  os.Setenv("DB_HOST", "localhost")
  os.Setenv("DB_PORT", "27017")
  os.Setenv("DB_USERNAME", "admin")
  os.Setenv("DB_PASSWORD", "password")
  os.Setenv("DB_NAME", "testdb")

  // Get the value of an Environment Variable
  host := os.Getenv("SITE_TITLE")
  port := os.Getenv("DB_HOST")
  fmt.Printf("Site Title: %s, Host: %s\n", host, port)

  // Unset an Environment Variable
  os.Unsetenv("SITE_TITLE")
  fmt.Printf("After unset, Site Title: %s\n", os.Getenv("SITE_TITLE"))

  //Checking that an environment variable is present or not.
  redisHost, ok := os.LookupEnv("REDIS_HOST")
  if !ok {
    fmt.Println("REDIS_HOST is not present")
  } else {
    fmt.Printf("Redis Host: %s\n", redisHost)
  }

  // Expand a string containing environment variables in the form of $var or ${var}
  dbURL := os.ExpandEnv("mongodb://${DB_USERNAME}:${DB_PASSWORD}@$DB_HOST:$DB_PORT/$DB_NAME")
  fmt.Println("DB URL: ", dbURL)
}
```

下面是我们`go run main.go`在终端中运行时的输出

```
go run main.go

//output
Site Title: Test Site, Host: localhost
After unset, Site Title: 27017
REDIS_HOST is not present
DB URL:  mongodb://admin:password@localhost:27017/testdb
```

还有两个功能`os.Clearenv`，`os.Environ()`让我们在单独的程序中使用它们。

- `os.Clearenv` 删除所有环境变量，清理测试环境可能很有用
- `os.Environ()` 以key = value的形式返回包含所有环境变量的字符串的一部分。

```
package main

import (
  "fmt"
  "os"
  "strings"
)

func main() {

  // Environ returns a slice of string containing all the environment variables in the form of key=value.
  for _, env := range os.Environ() {
    // env is
    envPair := strings.SplitN(env, "=", 2)
    key := envPair[0]
    value := envPair[1]

    fmt.Printf("%s : %s\n", key, value)
  }

  // Delete all environment variables
  os.Clearenv()

  fmt.Println("Number of environment variables: ", len(os.Environ()))
}
```

上面的函数将列出系统中所有可用的环境变量，包括`NAME`和`DB_HOST`。一旦运行`os.Clearenv()`，它将清除正在运行的进程的所有环境变量。

## GoDotEnv程序包

Ruby dotenv项目启发了[GoDotEnv](https://github.com/joho/godotenv)包，它从.env文件加载环境变量

让我们创建一个.env文件，其中将具有所有配置。

```
# .env file
# This is a sample config file

SITE_TITLE=Test Site 

DB_HOST=localhost
DB_PORT=27017
DB_USERNAME=admin
DB_PASSWORD=password
DB_NAME=testdb
```

然后在main.go文件中，我们将使用godotenv加载环境变量。

> 我们也可以一次加载多个env文件。godotenv还支持YAML。

```
// main.go
package main

import (
  "fmt"
  "log"
  "os"

  "github.com/joho/godotenv"
)

func main() {

  // load .env file from given path
  // we keep it empty it will load .env from current directory
  err := godotenv.Load(".env")

  if err != nil {
    log.Fatalf("Error loading .env file")
  }

  // getting env variables SITE_TITLE and DB_HOST
  siteTitle := os.Getenv("SITE_TITLE")
  dbHost := os.Getenv("DB_HOST")

  fmt.Printf("godotenv : %s = %s \n", "Site Title", siteTitle)
  fmt.Printf("godotenv : %s = %s \n", "DB Host", dbHost)
}
```

打开终端并运行 `main.go`

```
go run main.go

// output
godotenv : Site Title = Test Site
godotenv : DB Host = localhost
```

## Viper包装

> Viper是包括12要素应用程序在内的Go应用程序的完整配置解决方案。它旨在在应用程序中工作，并且可以处理所有类型的配置需求和格式。

[Viper](https://github.com/spf13/viper)支持多种文件格式来加载环境变量，例如，从JSON，TOML，YAML，HCL，envfile和Java属性配置文件中读取。因此，在此示例中，我们将研究如何从YAML文件中加载环境变量。

> YAML是一种人类可读的数据序列化语言。它通常用于配置文件和用于存储或传输数据的应用程序。

让我们在一个空文件夹中创建config.yaml和main.go。

```
# config.yaml
SITE:
  TITLE: Test Site

DB:
  HOST: "localhost"
  PORT: "27017"
  USERNAME: "admin"
  PASWORD: "password"
  NAME: "testdb"
```

在下面的代码中，我们使用Viper从config.yaml中加载环境变量。我们可以从所需的任何路径加载配置文件。如果配置文件中没有任何环境变量，我们还可以为任何环境变量设置默认值。

```
// main.go
package main

import (
  "fmt"
  "log"
  "os"

  "github.com/spf13/viper"
)

func main() {

  // Set the file name of the configurations file
  viper.SetConfigName("config")

  // Set the path to look for the configurations file
  viper.AddConfigPath(".")

  // Enable VIPER to read Environment Variables
  viper.AutomaticEnv()

  viper.SetConfigType("yml")

  if err := viper.ReadInConfig(); err != nil {
    fmt.Printf("Error reading config file, %s", err)
  }

  // Set undefined variables
  viper.SetDefault("DB.HOST", "127.0.0.1")

  // getting env variables DB.PORT
  // viper.Get() returns an empty interface{}
  // so we have to do the type assertion, to get the value
  DBPort, ok := viper.Get("DB.PORT").(string)

  // if type assert is not valid it will throw an error
  if !ok {
    log.Fatalf("Invalid type assertion")
  }

  fmt.Printf("viper : %s = %s \n", "Database Port", DBPort)
}
```

打开终端并运行 `main.go`

```
go run main.go

// output
viper : Database Port = 27017
```

## 结论

使用环境变量是在我们的应用程序中处理配置的绝佳方法。总体而言，它为您提供了轻松的配置，更好的安全性，多个部署环境以及更少的生产错误。

现在您可以在go应用程序中管理环境变量，并且可以在我们的[Github Repo](https://github.com/LoginRadius/engineering-blog-samples/tree/master/GoLang/EnvironmentVariables)上找到本教程中使用的完整代码

### 相关文章

#### [Mongo Go驱动程序中的自定义编码器](https://www.loginradius.com/engineering/blog/custom-encoders-in-the-mongo-go-driver/)

[走](https://www.loginradius.com/engineering/blog/tags/go/)[高朗](https://www.loginradius.com/engineering/blog/tags/golang/)[MongoDriver](https://www.loginradius.com/engineering/blog/tags/mongo-driver/)

#### [Golang中的Google OAuth2身份验证](https://www.loginradius.com/engineering/blog/google-authentication-with-golang-and-goth/)

[走](https://www.loginradius.com/engineering/blog/tags/go/)[社交登录](https://www.loginradius.com/engineering/blog/tags/social-login/)[OAuth](https://www.loginradius.com/engineering/blog/tags/o-auth/)

#### [在GoLang中将MongoDB用作数据源](https://www.loginradius.com/engineering/blog/mongodb-as-datasource-in-golang/)

[走](https://www.loginradius.com/engineering/blog/tags/go/)[MongoDB](https://www.loginradius.com/engineering/blog/tags/mongo-db/)



## 关于LoginRadius

LoginRadius提供了一组全面的API，以支持身份验证，身份验证，单点登录，用户管理以及帐户保护功能，例如在任何Web或移动应用程序上的多因素身份验证。该公司提供开源SDK，与150多个第三方应用程序的集成，预先设计和可自定义的登录界面以及一流的数据安全产品。该平台已经受到3,000多家企业的喜爱，每月在全球范围内拥有11.7亿用户。

有关更多信息，请访问[LoginRadius](https://loginradius.com/)

> 原文链接：<https://www.loginradius.com/engineering/blog/environment-variables-in-golang/>
>
> 作者：Puneet Singh
>
> 编译：polarisxu
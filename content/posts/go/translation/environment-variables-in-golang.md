---
title: "详解 Go 中的环境变量"
date: 2020-12-26T10:12:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - 环境变量
  - Go
  - Viper
---

了解环境变量以及在 Golang 应用程序中使用它们的不同方法。

## 开始之前

本教程假定你具有：

- 对 Go 语言的基本了解
- 系统上安装了最新 Golang 版本
- 几分钟的时间

在本文中，我们将了解环境变量以及为什么要使用它们。并且将使用内置和第三方包在 Go 应用程序中访问它们。

## 什么是环境变量？

环境变量是系统级的键-值对，正在运行的进程可以访问它。这些通常用于使同一程序在不同的部署环境（例如 PROD， DEV 或 TEST）中表现不同。在环境中存储配置是 twelve-factor 应用程序的原理之一。它使应用程序具有可移植性。

## 为什么要使用环境变量

- 如果您在代码中使用敏感信息，那么所有有权访问该代码的未授权用户都将拥有敏感数据，您可能不希望如此。
- 如果您使用的代码版本控制工具如：`git`，那么可能将 DB 凭据与代码一起推送，它将公开。
- 如果要在一处管理变量，则可以进行任何更改，而不必在应用程序代码中的所有位置都进行更改。
- 您可以管理多个部署环境，例如 PROD，DEV 或 TEST。在部署之间可以轻松更改环境变量，而无需更改任何应用程序代码。

> 永远不要忘记在 .gitignore 中包含环境变量文件

## 内置操作系统包

您不需要任何外部程序包即可访问 Golang 中的环境变量，并且可以使用标准库 `os` 包来实现。以下是与环境变量有关的函数及其用途的列表。

- `os.Setenv()` 设置环境值的值。
- `os.Getenv()` 获取指定键对应的环境变量值。
- `os.Unsetenv()` 删除指定键命名对应的单个环境值，如果我们再尝试使用 `os.Getenv()` 来获取该环境值，将返回一个空值。
- `os.ExpandEnv` 根据环境变量的值替换字符串中的 `${var}` 或 `$var`。如果不存在任何环境变量，则将使用空字符串替换它。
- `os.LookupEnv()` 获取指定键对应的环境变量值。如果系统中不存在该变量，则返回值将为空，并且布尔值将为 false。否则，它将返回值（可以为空），并且布尔值为 true。

> 如果不存在环境变量，则 os.Getenv() 将返回一个空字符串，使用 LookupEnv 来区分空值和未设置值。

现在，让我们在代码中使用上述所有函数。在一个空文件夹中创建一个 main.go 文件。

```go
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

下面是我们在终端中执行  `go run main.go`  的输出：

```bash
go run main.go

// output
Site Title: Test Site, Host: localhost
After unset, Site Title: 27017
REDIS_HOST is not present
DB URL:  mongodb://admin:password@localhost:27017/testdb
```

还有两个函数 `os.Clearenv` 和 `os.Environ()`，让我们在单独的程序中使用它们。

- `os.Clearenv`  删除所有环境变量，清理测试环境可能很有用
- `os.Environ()` 以 key = value 的形式返回包含所有环境变量的字符串的一部分。

```go
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

上面的函数将列出系统中所有可用的环境变量，包括 `NAME` 和 `DB_HOST`。一旦运行`os.Clearenv()`，它将清除正在运行的进程的所有环境变量。

## GoDotEnv 包

Ruby dotenv 项目启发了 [GoDotEnv](https://github.com/joho/godotenv) 包，它从 `.env` 文件加载环境变量。

让我们创建一个 `.env` 文件，其中包含所有配置。

```ini
# .env file
# This is a sample config file

SITE_TITLE=Test Site 

DB_HOST=localhost
DB_PORT=27017
DB_USERNAME=admin
DB_PASSWORD=password
DB_NAME=testdb
```

然后在 main.go 文件中，我们将使用 godotenv 加载环境变量。

> 我们也可以一次加载多个 env 文件。godotenv 还支持 YAML。

```go
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

打开终端并运行  `main.go`：

```bash
go run main.go

// output
godotenv : Site Title = Test Site
godotenv : DB Host = localhost
```

## Viper 包

> Viper 是 Go 应用程序的配置的完整解决方案。它旨在在应用程序中工作，并且可以处理所有类型的配置需求和格式。

[Viper](https://github.com/spf13/viper) 支持多种文件格式来加载环境变量，例如，从 JSON，TOML，YAML，HCL，envfile 和 Java 属性配置文件（properties）中读取。因此，在此示例中，我们将研究如何从 YAML 文件中加载环境变量。

> YAML 是一种人类可读的数据序列化语言。它通常用于配置文件和用于存储或传输数据的应用程序。

让我们在一个空文件夹中创建 config.yaml 和 main.go。

```yaml
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

在下面的代码中，我们使用 Viper 从 config.yaml 中加载环境变量。我们可以从所需的任何路径加载配置文件。如果配置文件中没有任何环境变量，我们还可以为任何环境变量设置默认值。

```go
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

打开终端并运行 `main.go`：

```bash
go run main.go

// output
viper : Database Port = 27017
```

## 结论

使用环境变量是在我们的应用程序中处理配置的绝佳方法。总体而言，它为您提供了轻松的配置，更好的安全性，多个部署环境以及更少的生产错误。

现在您可以在 go 应用程序中管理环境变量，并且可以在我们的 [Github Repo](https://github.com/LoginRadius/engineering-blog-samples/tree/master/GoLang/EnvironmentVariables) 上找到本教程中使用的完整代码。

> 原文链接：<https://www.loginradius.com/engineering/blog/environment-variables-in-golang/>
>
> 作者：Puneet Singh
>
> 编译：polarisxu
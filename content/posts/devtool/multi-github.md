---
title: "本地如何配置多个 GitHub/Gitee 账号？"
date: 2022-01-16T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - GitHub
  - Git
---

大家好，我是 polarisxu。

现在的开发，无论是日常工作还是参与开源，都离不开 Git。开源项目，大家通常使用 GitHub 或 Gitee，而工作中通常会自建 Git 服务，比如通过 GitLab、Gogs 等搭建。

为了方便使用，一般大家会配置 SSH keys，通过 ssh 协议 pull/push 仓库。

## 1、生成 ssh 密钥

首先，我们需要生成 ssh 密钥：（基于 mac，linux 类似，Windows 下找对应工具）

```bash
ssh-keygen -C "polaris@studygolang.com"
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/xuxinhua/.ssh/id_rsa):
```

出现的提示，使用默认值即可。命令执行完后，会生成 id_rsa 和 id_rsa.pub 文件，其中 id_rsa.pub 是公钥，拷贝其中的内容配置到 GitHub 或 GitLab 之类的网站。比如 GitHub 是这里：<https://github.com/settings/ssh/new>。

## 2、一个电脑两个不同网站账号

这是最常见的场景：一个业余号（github），一个工作号（比如自建 gitlab）。因为是不同网站，因此可以使用同一个邮箱。当然也可以是一个 github 账号，一个 gitee 账号，为了方便，以下使用 github 和 gitee。

在 `~/.ssh` 目录下创建一个 config 文件，在其中添加如下内容：

```config
host github
  hostname github.com
  Port 22
host gitee
  hostname gitee.com
  Port 22
```

这里没有指定 id_rsa，因为默认读取的就是它。

这样，本地使用 GitHub 还是 Gitee 完全没区别。

> 注意，需要使用 id_rsa.pub 分别在 GitHub 和 Gitee 添加 SSH Keys

当然，你也完全可以使用两个不同的账号，具体见下文。

## 3、一个电脑两个 GitHub 账号

因为两个 GitHub 账号，自然不能使用同一个 ssh 密钥，因此生成另外一个：

```bash
$ ssh-keygen -t rsa -f ~/.ssh/id_rsa_gmail -C "polaris@gmail.com"
```

这会在 `~/.ssh` 目录生成 id_rsa_gmail 和 id_rsa_gmail.pub 两个文件。

将 id_rsa.pub 和 id_rsa_gmail.pub 配置到对应的 GitHub 账号。然后跟上文一样，编辑 config 文件：

```bash
# github 账号：polaris@studygolang.com
host github
    hostname github.com
    Port 22
    User git
    IdentityFile ~/.ssh/id_rsa
# github 账号：polaris@gmail.com
host gmail-github
    hostname github.com
    Port 22
    User git
    IdentityFile ~/.ssh/id_rsa_gmail
```

config 是 ssh 的配置，详细信息可以参考：<https://daemon369.github.io/ssh/2015/03/21/using-ssh-config-file>。

针对以上场景，在具体使用时，我们需要注意以下几点：

- 默认会使用第一个账号，要使用第二个账号，需要设置该项目自己的 user.email 和 user.name
- git clone 时，第二个账号，地址得是类似这样的：`git@gmail-github.com:studygolang/studygolang.git `

如果有问题，可以执行以下两个命令验证：（记得替换为你自己的配置）

```bash
$ ssh-add ~/.ssh/id_rsa_gmail
ssh -T git@gmail-github.com
```

## 4、总结

生活一个号，工作一个号。如果你没有很好的区分，可以试试本文的方法，更愉快的 Coding！
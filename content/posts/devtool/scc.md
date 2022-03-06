---
title: "2021 年你写了多少代码？这个 Go 工具帮你统计"
date: 2021-12-28T22:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - scc
---

大家好，我是 polarisxu。

2021 年马上要过完了，一年下来，你写了多少代码？其中 Go 代码又有多少呢？虽然大家一般讨厌将代码行数作为考核业绩指标，但我们自己对一年的代码量有一个基本掌握还是挺有必要的。

如果你搜索，会发现代码统计工具有很多。比如 [sloccount](https://dwheeler.com/sloccount/)、github.com/AlDanial/cloc 等，似乎大家很喜欢统计代码行数。当然，也有人直接使用 grep、awk 之类的工具。

本文简单对比两个工具：cloc 和 scc。

这两个工具的原理类似。在 Mac 下，通过 brew 安装：

```bash
$ brew install cloc scc
```

其中 cloc 使用 Perl 实现，有 13.1k+ Star；而 scc 是 Go 实现的，项目地址：<https://github.com/boyter/scc>，有 3k+ Star。

使用这两个工具统计 github.com/studygolang/studygolang 项目。

```bash
$ cloc .
    4287 text files.
    4028 unique files.
Complex regular subexpression recursion limit (32766) exceeded at /usr/local/Cellar/cloc/1.82/libexec/bin/cloc line 9334.
     580 files ignored.

github.com/AlDanial/cloc v 1.82  T=5.68 s (658.0 files/s, 85679.8 lines/s)
--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
JavaScript                     2458          32504          90981         174284
JSON                            415            127              0          86826
Markdown                        359          13566              0          31219
Go                              200           4962           2238          20772
HTML                            153           1019             79          14358
CSS                              42           1219            292           6952
YAML                             45             56             12           1209
SQL                               2             74              0            847
XML                              10            137            489            790
TypeScript                       15             33            228            293
SVG                              15              0              0            279
INI                               2             41             46            144
XSLT                              1              8              1            101
make                              6             44              4             95
Bourne Shell                      3              9             11             50
DOS Batch                         4             26              0             44
diff                              1              6             20             25
Nix                               1              1              0             19
zsh                               1              4             14              7
Bourne Again Shell                1              4             16              7
Dockerfile                        1              4              1              5
CoffeeScript                      2              1              0              1
--------------------------------------------------------------------------------
SUM:                           3737          53845          94432         338327
--------------------------------------------------------------------------------
```

统计花了近 6 秒。

```bash
$ scc
───────────────────────────────────────────────────────────────────────────────
Language                 Files     Lines     Code  Comments   Blanks Complexity
───────────────────────────────────────────────────────────────────────────────
JavaScript                2523    298987   207834     63356    27797      33769
JSON                       419     31849    31660         0      189          0
Markdown                   375     46820    32663         0    14157          0
License                    275      6279     5081         0     1198          0
Go                         200     27972    20776      2243     4953       4447
HTML                       154     15617    14525        79     1013          0
YAML                        51      1303     1247         0       56          0
CSS                         44      8463     6952       297     1214          0
Plain Text                  34    594575   594394         0      181          0
TypeScript Typings          17       741      367       340       34         27
SVG                         15       279      279         0        0          0
XML                         10      1416      790       516      110          0
Makefile                     6       143       95         4       44          6
gitignore                    5        64       45         3       16          0
Batch                        4        70       42         2       26          5
Shell                        3        70       47        14        9         13
CoffeeScript                 3         2        1         0        1          0
Patch                        2      1527     1430         0       97          0
SQL                          2       921      847         0       74          0
Nix                          1        20       19         0        1          0
Zsh                          1        25        6        15        4          0
Fish                         1        10        1         7        2          0
Dockerfile                   1        10        5         1        4          0
BASH                         1        27        6        17        4          0
───────────────────────────────────────────────────────────────────────────────
Total                     4147   1037190   919112     66894    51184      38267
───────────────────────────────────────────────────────────────────────────────
Estimated Cost to Develop $34,924,659
Estimated Schedule Effort 59.194452 months
Estimated People Required 69.888518
───────────────────────────────────────────────────────────────────────────────
```

scc 速度很快，几乎瞬间完成。

这两个工具的功能类似，但也会有差别。不过 scc 速度快很多，无疑，大家应该会更喜欢 Go 语言实现的 scc。

scc，又叫做  Sloc、Cloc 和 Code，即取这三个单词的首字母：SCC。scc 是一个非常快速准确的代码计数器，具有复杂度计算和 COCOMO 估计，用纯 Go 编写。

scc 允许查看代码使用的每种编程语言、行数、注释、文件等。这是一个非常快速且有用的工具。大部分语言 scc 都支持，通过 `scc --languages` 查看支持的语言，目前有 201 种。

在第一届 GopherCon AU 上 scc 作者 boyter 作了关于 scc 设计和实现的演讲，这里有 PPT：<https://boyter.org/static/gophercon-syd-presentation/>，也有视频：<https://www.youtube.com/watch?v=jd-sjoy3GZo>。

关于 scc 的更多信息，可以访问项目首页查看：<https://github.com/boyter/scc>。

---

如果要统计 2021 年你写了多少代码，可能不是简单地运行 scc 就能搞定，因为多半代码不是你一个人写的，可能需要借助 git 辅助。有兴趣的小伙伴可以研究研究。
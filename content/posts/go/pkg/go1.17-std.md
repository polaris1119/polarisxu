---
title: "Go1.17 快报之标准库越来越注重易用性"
date: 2021-06-22T12:30:00+08:00
toc: true
isCJKLanguage: true
tags: 
  - Go
  - 标准库
---

大家好，我是 polarisxu。

说起 Go 的优点，很多人会提到 Go 拥有强大的标准库，比如开发一个 HTTP 服务，几行代码就搞定。不过，如果是一个 PHPer 转到 Go，又会觉得 Go 标准库不够便利，很多东西都需要自己二次封装。这其实是一个取舍的问题。

Go 官方也在不断完善、优化标准库，在坚持一定原则的基础上，尽可能让标准库好用、易用。今天就看看 Go1.17 中，官方在这方面做了哪些改进。

## 01 time 包

Unix 时间戳，大家知道单位是什么吗？Java 或 JavaScript 的同学大概率会回答是毫秒，因为这两门语言提供获取“时间戳”的方法，单位是毫秒。但实际上，标准的 Unix 时间戳，单位是秒，标准定义是：

> Unix 时间戳是从 1970 年 1 月 1 日（UTC/GMT 的午夜）开始所经过的秒数，不考虑闰秒。

正因为如此，Go 标准库 time 包提供获取时间戳的方法是 `Unix()`，单位是秒：

```go
// Unix returns t as a Unix time, the number of seconds elapsed
// since January 1, 1970 UTC. The result does not depend on the
// location associated with t.
// Unix-like operating systems often record time as a 32-bit
// count of seconds, but since the method here returns a 64-bit
// value it is valid for billions of years into the past or future.
func (t Time) Unix() int64
```

在和客户端/前端协商 API 时，一定要注意时间戳单位的问题。

为了方便，Go1.17 增加加了 Time.UnixMilli 方法，返回 Unix 时间戳的毫秒数，同时也提供了 UnixNano 和 UnixMicro。

此外，如果前端传递一个毫秒的时间戳，可以通过 Go1.17 新的函数 UnixMilli 转为 Time 类型：

```go
func UnixMilli(msec int64) Time
```

注意 UnixMilli 函数和 Time.UnixMilli 方法的区别，互逆的关系。

## 02 net/url 包

在这个包中有一个类型 Values，定义如下：

```go
type Values map[string][]string
```

它通常用于查询参数和表单值。它提供了 Set、Get、Del 等方法，但没有提供判断某个 key 是否设置了的方法（虽然自己实现不难，但形式不一致），而且这种需求还挺多的。Go1.17 就增加了一个方法：Has，用来判断某个 key 是否设置了。

```go
// Has checks whether a given key is set.
func (v Values) Has(key string) bool
```

## 03 net 包

如何判断一个 IP 地址是否是内网地址？你查找标准库会发现没有这样的方法，这时只能自己实现，需要查找 IPv4 标准，看哪些是内网地址，还得处理 IPv6 的情况。

Go1.17 中增加了一个方法：IsPrivate，用来判断一个 IP 地址是否是内网地址：

```go
// IsPrivate reports whether ip is a private address, according to
// RFC 1918 (IPv4 addresses) and RFC 4193 (IPv6 addresses).
func (ip IP) IsPrivate() bool
```

是不是方便很多。看它的实现，自己实现可能不那么容易：

```go
func (ip IP) IsPrivate() bool {
	if ip4 := ip.To4(); ip4 != nil {
		// Following RFC 1918, Section 3. Private Address Space which says:
		//   The Internet Assigned Numbers Authority (IANA) has reserved the
		//   following three blocks of the IP address space for private internets:
		//     10.0.0.0        -   10.255.255.255  (10/8 prefix)
		//     172.16.0.0      -   172.31.255.255  (172.16/12 prefix)
		//     192.168.0.0     -   192.168.255.255 (192.168/16 prefix)
		return ip4[0] == 10 ||
			(ip4[0] == 172 && ip4[1]&0xf0 == 16) ||
			(ip4[0] == 192 && ip4[1] == 168)
	}
	// Following RFC 4193, Section 8. IANA Considerations which says:
	//   The IANA has assigned the FC00::/7 prefix to "Unique Local Unicast".
	return len(ip) == IPv6len && ip[0]&0xfe == 0xfc
}
```

## 04 其他包

math 包新提供了 MaxInt、MinInt、MaxUint 三个常量，分别对应 int 的最大、最小值和 uint 的最大值，这样我们不需要自己判断当前 CPU 架构确定最大最小值。

io/fs 包新增加 FileInfoToDirEntry 函数，它用于获取一个 FileInfo 的 DirEntry 信息，在操作文件系统时可能会用到。

```go
func FileInfoToDirEntry(info FileInfo) DirEntry
```

database/sql 包新增加了 NullByte 和 NullInt16，用于表示可能为 null 的 int16 和 byte 类型（我个人不建议创建数据表时支持 null，这样处理起来比较麻烦，建议全部 NOT NULL）。

## 05 总结

简单、易用，一直是 Go 的哲学。标准库方面，Go 也会尽可能的做到易用，但不会封装到像 PHP 那样的程度，有些功能，还是需要自己进行二次封装。

你觉得 Go1.17 上面的改进如何？还有哪些功能是你希望标准库提供的？欢迎留言交流。

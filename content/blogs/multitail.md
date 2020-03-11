---
title: "Linux在单个终端中同时监视多个文件"
date: 2020-03-10T20:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Linux在单个Linux终端中同时监视多个文件"
tags: ["linux","tail","MultiTail"]
keywords: ["linux","tail","MultiTail"]
image: "/img/linux.jpg"
link: "https://centos.org/"
fact: "Linux在单个Linux终端中同时监视多个文件"
weight: 400
sitemap:
  priority : 0.8
---

> 本文为转载：DevOps小站  原文网站，原文地址：https://www.howtoing.com/view-multiple-files-in-linux/

# Linux在单个终端中同时监视多个文件

MultiTail是一个开源的ncurses实用程序，可用于在单个窗口或单个shell中将多个日志文件显示到标准输出。

无论是服务器管理员还是程序员，我们需要参考多个日志文件来有效地排除故障任务。 为了实现这一点，我们必须打开，拖尾或更少的不同shell中的每个日志文件。 但是，我们可以使用传统的tail命令状尾-f在/ var / log / messages文件或尾-f /无功/在单行日志/安全 。 但是，如果我们希望看到在实时多个文件，我们需要安装一个名为MultiTail特定的工具。

什么是MultiTail？
MultiTail是一个开源的ncurses的实用工具，可用于在一个窗口或单一外壳，显示实时一样的尾巴命令，该命令拆分控制台为更多子窗口的日志文件的最后几行（很像显示多个日志文件到标准输出屏幕命令 ）。 它还支持颜色突出显示，过滤，添加和删除窗口等。

特征
#1.多个输入源。
#2.在重要信息的情况下使用正则表达式的彩色显示。
#3.线路滤波。
#4.用于删除和添加贝壳的交互式菜单。
这里是一个示例屏幕抓取MultiTail在行动。
![多尾视图](/images/blog/MultiTail-001.jpeg)


 在Linux中安装MultiTail
为了让MultiTail基于Red Hat分发，你必须打开EPEL资源库 ，然后在终端上运行下面的命令来安装它。

在RHEL / CentOS / Fedora上
```
# yum install -y multitail
```
在Debian / Ubuntu / Linux Mint
```
$ sudo apt-get update
$ sudo apt-get install multitail
```
**MultiTail的使用**
默认情况下MultiTail做同样的事情为“ 尾-f”，在真实时间，即查看文件。 要在一个窗口中查看/监视两个不同的文件，基本语法是：

**1.如何在单窗口中查看2个文件**
```
multitail /var/log/apache2/error.log /var/log/apache2/error.log.1
```
![在Linux中查看两个文件](/images/blog/MultiTail-002.jpeg)


要滚动文件，点击“B”，并选择从列表中所需的文件。
![文件选择](/images/blog/MultiTail-003.jpeg)

一旦你选择文件，它会告诉你最近的100行选定的文件，通过使用光标键滚动。 你也可以使用'GG'/'G'移动到滚动窗口的顶部/底部。 如果你想查看更多行，按'Q'退出并点击“M”为线，查看数输入一个新值。
![查看文件](/images/blog/MultiTail-004.jpeg)

**2.如何查看2列中的2个文件**
下面的命令将在第2列中显示两个不同的文件。
```
multitail -s 2 /var/log/mysqld.log /var/log/xferlog
```
![查看2列中的文件](/images/blog/MultiTail-005.jpeg)

**3.如何在多个列中查看多个文件**
显示分三路3个文件。
```
multitail -s 3 /var/log/mysqld.log /var/log/xferlog /var/log/yum.log
```
![查看3列中的文件](/images/blog/MultiTail-006.jpeg)
**4.合并/查看多个列中的多个文件**
显示器5日志文件而合并在一列2个文件，并在左侧列中保持2个文件中的两列只有一个 。

```
multitail -s 2 -sn 1,3  /var/log/mysqld.log -I /var/log/xferlog /var/log/monitorix /var/log/ajenti.log /var/log/yum.log
```
![多个视图文件](/images/blog/MultiTail-007.jpeg)

**5.如何查看文件和执行命令**
显示1文件，而“-L”选项允许命令在一个窗口中执行。

``` 
multitail /var/log/iptables.log -l "ping server.nixcraft.in"
```
![运行命令和查看文件](/images/blog/MultiTail-008.jpeg)
**6.如何合并/查看两个不同颜色的文件**
合并2日志文件在一个窗口，但给不同的颜色给每个日志文件，这样你可以很容易地了解什么线是什么日志文件。
``` 
multitail -ci green /var/log/yum.log -ci yellow -I /var/log/mysqld.log
``` 
![查看颜色文件](/images/blog/MultiTail-009.jpeg)

**结论**
我们只介绍了multitail命令的几个基本用法。 有关选项和密钥的完整列表，你可以看看multitail的手册页或在程序运行时可按下求助“H”键。
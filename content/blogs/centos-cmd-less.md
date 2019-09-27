---
title: "命令less、tail的使用"
date: 2019-09-27T20:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "命令less、tail的使用"
tags: ["centos","linux","less","tail"]
keywords: ["centos","linux","less","tail"]
image: "/img/mysql.jpg"
link: "https://mysql.com/"
fact: "命令less、tail的使用"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/centos-cmd-less

# 命令less、tail的使用

1、less命令
less的语法格式：less [参数] 文件

常用参数：
-c 从顶部（从上到下）刷新屏幕，并显示文件内容。而不是通过底部滚动完成刷新；
-f 强制打开文件，二进制文件显示时，不提示警告；
-i 搜索时忽略大小写；除非搜索串中包含大写字母；
-I 搜索时忽略大小写，除非搜索串中包含小写字母；
-m 显示读取文件的百分比；
-M 显法读取文件的百分比、行号及总行数；
-N 在每行前输出行号；
-p pattern 搜索pattern；比如在/etc/profile搜索单词MAIL，就用 less -p MAIL /etc/profile
-s 把连续多个空白行作为一个空白行显示；
-Q 在终端下不响铃；

比如：在catalina.2018-07-16.out的内容中搜索updateStaff字符串，并让其显示行号；
less -N -i -p updateStaff catalina.2018-07-16.out

less的动作命令：

进入less后，我们得学几个动作，这样更方便 我们查阅文件内容；最应该记住的命令就是q，这个能让less终止查看文件退出；

动作：
回车键 向下移动一行；
y 向上移动一行；
空格键 向下滚动一屏；
b 向上滚动一屏；
d 向下滚动半屏；
h less的帮助；
u 向上洋动半屏；
w 可以指定显示哪行开始显示，是从指定数字的下一行显示；比如指定的是6，那就从第7行显示；
g 跳到第一行；
G 跳到最后一行；
p n% 跳到n%，比如 10%，也就是说比整个文件内容的10%处开始显示；
/pattern 搜索pattern ，比如 /MAIL表示在文件中搜索MAIL单词；
v 调用vi编辑器；
q 退出less
!command 调用SHELL，可以运行命令；比如!ls 显示当前列当前目录下的所有文件；

2、tail 命令
tail 是显示一个文件的内容的最后多少行；

用法比较简单；
tail   -n 行数值 文件名；

比如我们显示/etc/profile的最后5行内容，应该是：
[root@localhost ~]# tail -n 5 /etc/profile

tail -f /var/log/syslog 显示文件 syslog 的后十行内容并在文件内容增加后，且自动显示新增的文件内容。

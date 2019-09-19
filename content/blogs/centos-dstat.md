---
title: "CentOS下性能监测工具 dstat"
date: 2019-09-18T20:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "CentOS下性能监测工具 dstat"
tags: ["centos","性能测试","dstat"]
keywords: ["centos","性能测试","dstat"]
image: "/img/mysql.jpg"
link: "https://mysql.com/"
fact: "CentOS下性能监测工具 dstat"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/centos-dstat

# CentOS下性能监测工具 dstat

dstat 是一个可以取代vmstat，iostat，netstat和ifstat这些命令的多功能产品。dstat克服了这些命令的局限并增加了一些另外的功能，增加了监控项，也变得更灵活了。dstat可以很方便监控系统运行状况并用于基准测试和排除故障。

dstat可以让你实时地看到所有系统资源，例如，你能够通过统计IDE控制器当前状态来比较磁盘利用率，或者直接通过网络带宽数值来比较磁盘的吞吐率（在相同的时间间隔内）。

dstat将以列表的形式为你提供选项信息并清晰地告诉你是在何种幅度和单位显示输出。这样更好地避免了信息混乱和误报。更重要的是，它可以让你更容易编写插件来收集你想要的数据信息，以从未有过的方式进行扩展。

Dstat的默认输出是专门为人们实时查看而设计的，不过你也可以将详细信息通过CSV输出到一个文件，并导入到Gnumeric或者Excel生成表格中。

### 特性

- 结合了vmstat，iostat，ifstat，netstat以及更多的信息
- 实时显示统计情况
- 在分析和排障时可以通过启用监控项并排序
- 模块化设计
- 使用python编写的，更方便扩展现有的工作任务
- 容易扩展和添加你的计数器（请为此做出贡献）
- 包含的许多扩展插件充分说明了增加新的监控项目是很方便的
- 可以分组统计块设备/网络设备，并给出总数
- 可以显示每台设备的当前状态
- 极准确的时间精度，即便是系统负荷较高也不会延迟显示
- 显示准确地单位和和限制转换误差范围
- 用不同的颜色显示不同的单位
- 显示中间结果延时小于1秒
- 支持输出CSV格式报表，并能导入到Gnumeric和Excel以生成图形

### 安装方法

\1. 在centos下 可以 yum -y instatll dstat

\2. 下载rpm包进行安装

 wget http://packages.sw.be/dstat/dstat-0.7.2-1.el5.rfx.noarch.rpm

 rpm -ivh dstat-0.7.2-1.el5.rfx.noarch.rpm

### 使用方法

dstat的基本用法就是输入dstat命令，输出如下：

```
You did not select any stats, using -cdngy by default.
----total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw 
  8   2  88   2   0   0| 241k   51M|   0     0 |   0     0 |  17k   20k
  0   0 100   0   0   0|   0  8192B|  10k   17k|   0     0 |2090  4012 
  0   0 100   0   0   0|   0     0 |  10k   17k|   0     0 |2081  4001
```

这是默认输出显示的信息：

默认情况下分五个区域：

------

1、 --total-cpu-usage---- CPU使用率

usr：用户空间的程序所占百分比；

sys：系统空间程序所占百分比；

idel：空闲百分比；

wai：等待磁盘I/O所消耗的百分比；

hiq：硬中断次数；

siq：软中断次数；

------

2、-dsk/total-磁盘统计

read：读总数

writ：写总数

------

3、-net/total- 网络统计

recv：网络收包总数

send：网络发包总数

------

4、---paging-- 内存分页统计

in： pagein（换入）

out：page out（换出）

注：系统的分页活动。分页指的是一种内存管理技术用于查找系统场景，一个较大的分页表明系统正在使用大量的交换空间，通常情况下当系统已经开始用交换空间的时候，就说明你的内存已经不够用了，或者说内存非常分散，理想情况下page in（换入）和page out（换出）的值是0 0。

------

5、--system--系统信息

int：中断次数

csw：上下文切换

注：中断（int）和上下文切换（csw）。这项统计仅在有比较基线时才有意义。这一栏中较高的统计值通常表示大量的进程造成拥塞，需要对CPU进行关注。你的服务器一般情况下都会运行运行一些程序，所以这项总是显示一些数值。 

------

 默认情况下，dstat 会每隔一秒刷新一次数据，一直刷新并一直输出，按 Ctrl+C 退出 "dstat"；

 dstat 还有许多具体的参数，可通过man dstat命令查看，

### 常用参数如下：

通过dstat --list可以查看dstat能使用的所有参数

- -l ：显示负载统计量
- -m ：显示内存使用率（包括used，buffer，cache，free值）
- -r ：显示I/O统计
- -s ：显示交换分区使用情况
- -t ：将当前时间显示在第一行
- –fs ：显示文件系统统计数据（包括文件总数量和inodes值）
- –nocolor ：不显示颜色（有时候有用）
- –socket ：显示网络统计数据
- –tcp ：显示常用的TCP统计
- –udp ：显示监听的UDP接口及其当前用量的一些动态数据

当然不止这些用法，dstat附带了一些**插件**很大程度地扩展了它的功能。你可以通过查看/usr/share/dstat目录来查看它们的一些使用方法，常用的有这些：

- -–disk-util ：显示某一时间磁盘的忙碌状况
- -–freespace ：显示当前磁盘空间使用率
- -–proc-count ：显示正在运行的程序数量
- -–top-bio ：指出块I/O最大的进程
- -–top-cpu ：图形化显示CPU占用最大的进程
- -–top-io ：显示正常I/O最大的进程
- -–top-mem ：显示占用最多内存的进程

### 应用举例：

dstat输出默认监控、报表输出的时间间隔为3秒钟,并且报表中输出10个结果

```
dstat 3 10
```

查看全部内存都有谁在占用：

```
dstat -g -l -m -s --top-mem
```

显示一些关于CPU资源损耗的数据：

```
dstat -c -y -l --proc-count --top-cpu
```

### 如何输出一个csv文件

```
# dstat –output /tmp/sampleoutput.csv -cdn
```

备注：输出的的 scv 文件，可以在 windows 下用 excel 打开，并生成图表；
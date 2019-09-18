---
title: "YCSB-性能测试工具的安装和使用"
date: 2019-09-16T20:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "YCSB-性能测试工具的安装和使用"
tags: ["ycsb","性能测试"]
keywords: ["ycsb","性能测试"]
image: "/img/mysql.jpg"
link: "https://mysql.com/"
fact: "YCSB-性能测试工具的安装和使用"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/ycsb-install-used

# YCSB-性能测试工具的安装和使用

 一、背景概念
英文全称：Yahoo！CloudServing Benchmark（YCSB）。是Yahoo公司的一个用来对云服务进行基础测试的工具。目标是促进新一代云数据服务系统的性能比较。
 二、资源获取

首先在官网上下载源码编译或者直接下载软件包

https://github.com/brianfrankcooper/YCSB/releases/tag/0.15.0



编译的话需要maven工程和其他资源包的依赖比较麻烦，建议直接下载软件包。



补充一点编译的内容：

下载好最新源码



解压到本地并进入源码根目录YCSB-0.15.0

 

如果想编译出完整版的话直接输入

mvn clean package

编译成功的话，在YCSB-0.15.0/distribution目录下会有对应的ycsb的压缩包，拷贝解压即可使用

这种方法编译出的完整版ycsb适用于多种数据库所以依赖的库太多，目标文件太大，耗费时间太长，不建议用这种方式编译。

 

建议单独编一个只用于测试某个数据库

例如:

1.hbase的ycsb可输入:

mvn -pl com.yahoo.ycsb:hbase10-binding -am clean package   

2.jdbc的ycsb可输入: 

mvn -pl com.yahoo.ycsb:jdbc-binding -am clean package

3.s3的ycsb可输入

mvn -pl com.yahoo.ycsb:s3-binding -am clean package



这种方法编译成功的话，在对应的目录下的/target 目录下会有

ycsb-*-binding-0.15.0.tar.gz 压缩包即我们的目标文件，解压之后即可使用

  

三、配置与使用
 以jdbc测试mysql为例

解压上面生成的jdbc/target/ycsb-jdbc-binding-0.8.0-SNAPSHOT.tar.gz

tar xvfz jdbc/target/ycsb-jdbc-binding-0.8.0-SNAPSHOT.tar.gz -C opt/

ln -s  opt/ycsb-jdbc-binding-0.8.0-SNAPSHOT opt/ycsb 

1.下载mysql的jdbc驱动放入ycsb的lib目录。



2.用以下脚本文件创建ycsb用的数据库及表的schema

cat mysql-create-schema.sh 

```
#! /bin/bash

if [ ! ~/opt/ycsb/bin/ycsb ] ; then
    echo 'ycsb is not found'
    exit -1
fi

echo 'CREATE DATABASE IF NOT EXISTS ycsb' | mysql "$@"

SQL="
CREATE TABLE IF NOT EXISTS ycsb.usertable (
    YCSB_KEY VARCHAR(255) PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT
) engine=innodb;
"

echo "$SQL" | mysql "$@"
```

运行：

```
sh mysql-create-schema.sh  -h 127.0.0.1
```

2.定义ycsb参数

cat profile.properties

```
# mysql
db.driver=com.mysql.jdbc.Driver
db.url=jdbc:mysql://127.0.0.1:3306/ycsb?useServerPrepStmts=true
db.user=test
db.passwd=testtest

recordcount=1000
operationcount=0
maxexecutiontime=30
threadcount=1

```

3.加载数据：

cat mysql-load.sh

```
#! /bin/bash
echo 'TRUNCATE TABLE ycsb.usertable' | mysql 
~/opt/ycsb/bin/ycsb load jdbc -s -P ~/opt/ycsb//workloads/workloada -P profile.properties -p maxexecutiontime=0 -s $@

```

运行：

```
sh  mysql-load.sh > mysql-load.log &
```

Ycsb运行完之后的结果打印和分析：

cat mysql-load.log

部分内容

```
[OVERALL], RunTime(ms), 2787.0         数据加载所用时间：2.787秒
[OVERALL], Throughput(ops/sec), 35.88087549336204       加载操作的吞吐量，平均并发量每秒35.88条
[TOTAL_GC_TIME_PS_Scavenge], Time(ms), 20.0
[TOTAL_GC_TIME_%_PS_Scavenge], Time(%), 0.7176175098672408
[TOTAL_GCS_PS_MarkSweep], Count, 0.0
[TOTAL_GC_TIME_PS_MarkSweep], Time(ms), 0.0
[TOTAL_GC_TIME_%_PS_MarkSweep], Time(%), 0.0
[TOTAL_GCs], Count, 1.0
[TOTAL_GC_TIME], Time(ms), 20.0
[TOTAL_GC_TIME_%], Time(%), 0.7176175098672408
[CLEANUP], Operations, 2.0                    执行cleanup的操作总数，2
[CLEANUP], AverageLatency(us), 63575.0             平均响应时间63.575ms
[CLEANUP], MinLatency(us), 14.0                                     最小响应时间0.014ms
[CLEANUP], MaxLatency(us), 127167.0                  最大响应时间127.167ms
[CLEANUP], 95thPercentileLatency(us), 127167.0        95%的cleanup操作延时在127.167ms以内
[CLEANUP], 99thPercentileLatency(us), 127167.0        99%的cleanup操作延时在127.167ms以内
[INSERT], Operations, 100.0          执行insert操作的总数，100
[INSERT], AverageLatency(us), 13681.54     每次insert操作的平均时延，13.68154ms
[INSERT], MinLatency(us), 5556.0         所有insert操作最小延时，5.556ms
[INSERT], MaxLatency(us), 201343.0   所有insert操作最大延时，201.343ms
[INSERT], 95thPercentileLatency(us), 30063.0     95%的insert操作延时在30.063ms以内
[INSERT], 99thPercentileLatency(us), 53183.0     99%的insert操作延时在53.183ms以内
[INSERT], Return=OK, 1000  成功返回数，1000
```



## 四、参考资料

具体详细信息可参考网络资料和官网https://github.com/brianfrankcooper/YCSB
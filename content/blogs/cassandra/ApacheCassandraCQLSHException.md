---
title: "Apache Cassandra 异常记录"
date: 2022-02-22T22:30:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate rest api"
tags: ["Apache Cassandra","CQLSH"]
keywords: ["Apache Cassandra","CQLSH"]
image: "https://pulsar.apache.org/img/pulsar.svg"
link: "https://cassandra.apache.org"
fact: "Connecting Pulsar With Apache Cassandra"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/cassandra/apachecassandracqlshexception/

作者：Frank Li  *2022-02-26 22:30*

测试机信息：Centos 8 , ip:192.168.139.8  绑定域名：nosql.easyolap.cn

 

本文档记录在学习cassandra过程中遇到的一些异常及处理方法，仅供参考，持续更新中。。。



感谢Apache Cassandra专家阙老师的指导。



提示

1.这些说明假设您在单节点模式下运行Cassandra。

2.假设所有指令都在Cassandra二进制发部的根目录下运行。

软件版本：

| Name                 | Version |
| -------------------- | ------- |
| Apache Cassandra | `4.0.1` |




# 安装Apache Cassandra

## **一、简介**

要开始运行Cassandra，请下载二进制tarball版本：

​       

##### 1. 安装和启动Cassandra集群

   下载
```
wget https://dlcdn.apache.org/cassandra/4.0.1/apache-cassandra-4.0.1-bin.tar.gz

```
启动cassandra服务
```bash
bin/cassandra
```

##### 2. 验证cassandra cql协议9042端口。

```bash
netstat -nap |grep 9042
```

Example output:
```bash
tcp        0      0 127.0.0.1:9042          0.0.0.0:*               LISTEN      24183/java 
...

```
##### 3. 检查cassandra集群状态。

```bash
bin/nodetool status
```

Example output:
```bash
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address    Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  127.0.0.1  130.58 KiB  16      100.0%            8560b4f3-49ae-4825-9ce2-c589d3b3a431  rack1

```

##### 4. cqlsh连接验证

```bash
./cqlsh localhost
```
Example output:
```bash
Connected to Test Cluster at localhost:9042
[cqlsh 6.0.0 | Cassandra 4.0.1 | CQL spec 3.4.5 | Native protocol v5]
Use HELP for help.
cqlsh>
```
已成功进入到cqlsh命令行模式下。

## **二、异常及处理记录**

以下异常验证环境：单节点

##### 1.CQLSH中执行查询统计出错：

```bash
OperationTimedOut: errors={'127.0.0.1:9042': 'Client request timeout. See Session.execute[_async](timeout)'}, last_host=127.0.0.1:9042
```

解决办法：

```
修改cqlsh.py中的DEFAULT_REQUEST_TIMEOUT_SECONDS = 10  为  DEFAULT_REQUEST_TIMEOUT_SECONDS = 1000
```

##### 2.CQLSH中执行查询统计出错：

```bash
ReadTimeout: Error from server: code=1200 [Coordinator node timed out waiting for replica nodes' responses] message="Operation timed out - received only 0 responses." info={'consistency': 'ONE', 'required_responses': 1, 'received_responses': 0}
```

解决办法：

```
修改conf/cassandra.yaml中的：
range_request_timeout_in_ms: 10000
为
range_request_timeout_in_ms: 1000000

read_request_timeout_in_ms: 5000
为
read_request_timeout_in_ms: 500000


```

本次测试是把默认的时间扩大了100倍，具体参数请根据环境自行验证。




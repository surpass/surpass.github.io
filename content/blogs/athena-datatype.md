---
title: "Athena 支持的数据类型"
date: 2019-08-22T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Athena 支持的数据类型"
tags: ["Athena","ec2","aws"]
keywords: ["ansible","ec2","publickey"]
image: "/img/ansible.jpg"
link: "https://java.oracle.com"
fact: "自动化运维工具"
summary: "Athena 支持的数据类型"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/athena-datatype 

# Athena 支持的数据类型

 

Athena 支持以下数据类型：
BOOLEAN。值包括 true 和 false。

整数类型

TINYINT。一个 8 位有符号的 INTEGER，采用二进制补码格式，最小值为 -2^7，最大值为 2^7-1。

SMALLINT。一个 16 位有符号的 INTEGER，采用二进制补码格式，最小值为 -2^15，最大值为 2^15-1。

INT。Athena 结合了两个不同的 INTEGER 数据类型实施。在数据定义语言 (DDL) 查询中，Athena 使用 INT 数据类型。在所有其他查询中，Athena 使用 INTEGER 数据类型，其中 INTEGER 以二进制补码格式表示为 32 位有符号值，最小值为 -2^31，最大值为 2^31-1。在 JDBC 驱动程序中，将返回 INTEGER 以确保与业务分析应用程序兼容。

BIGINT。一个 64 位有符号的 INTEGER，采用二进制补码格式，最小值为 -2^63，最大值为 2^63-1。

浮点类型

DOUBLE

FLOAT

固定精度类型

DECIMAL [ (precision, scale) ]，其中 precision 是总位数，而 scale（可选）是小数部分的位数，默认值为 0。例如，使用以下类型定义：DECIMAL(11,5)、DECIMAL(15)。

要将十进制值指定为文字（例如在查询 DDL 表达式中选择具有特定十进制值的行时），请指定 DECIMAL 类型定义，并在查询中将十进制值列为文字（带单引号），如下例所示：decimal_value = DECIMAL '0.12'。

字符串类型

CHAR。固定长度字符数据，具有介于 1 和 255 之间的指定长度，例如 char(10)。有关更多信息，请参阅 CHAR Hive 数据类型。

VARCHAR。可变长度字符数据，具有介于 1 和 65535 之间的指定长度，例如 varchar(10)。有关更多信息，请参阅 VARCHAR Hive 数据类型。

BINARY（适用于 Parquet 中的数据）

日期和时间类型

DATE，采用 UNIX 格式，例如 YYYY-MM-DD。

TIMESTAMP。采用 UNiX 格式的瞬间时间和日期，例如 yyyy-mm-dd hh:mm:ss[.f...]。例如：TIMESTAMP '2008-09-15 03:04:05.324'。此格式使用会话时区。

结构类型

ARRAY < data_type >

MAP < primitive_type, data_type >

STRUCT < col_name : data_type [COMMENT col_comment] [, ...] >
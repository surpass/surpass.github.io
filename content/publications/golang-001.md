---
title: "golang学习笔记-关于数组，切片，映射"
date: 2018-08-25T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/about/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "关于数组，切片，映射小结"
tags: ["golang","数组","切片","映射"]
keywords: ["golang","数组","切片","映射"]
image: "/img/go.jpg"
link: "https://golang.org/"
fact: "golang学习笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/publications/golang-001

数组、切片和映射小结



 * 数组是构造切片和映射的基石。

 * Go语言里切片经常用来处理数据的集合，映射用来处理具有键值对结构的数据。

 * 内置函数make 可以创片和映射，并指定原始的长度和容量。也可以直接使切片和映射字央量，或者使用字面量作为变量作为变量的初始值。

 * 切片有容量限制，不过可以使用内置的append函数扩展容量。

 * 映射的增长设有容量或者任何限制。

 * 内置函数len可以用来获取切片或映射的长度。

 * 内置函数cap只能用于切片。

 * 通过组合，可以创建多维数组和多维切片。也可以使用切片或者其他映射作为映射 的值。但是切片不能用作映射的键。

 * 将切片或者映射传递给函数成本很小，并且不会复制底层的数据结构。

		
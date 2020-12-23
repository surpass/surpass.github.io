---
title: "suse 12安装flink集群_CDp中自定义flink的parcel包和csd文件"
date: 2020-12-21T15:30:26+08:00
pubtype: "Talk"
featured: true
description: "suse 12安装flink集群_CDp中自定义flink的parcel包和csd文件."
tags: ["CDP","CM7","flink"]
image: "/img/flink.png"
link: "https://https://flink.apache.org//"
fact: "suse 12安装flink集群_CDp中自定义flink的parcel包和csd文件"
weight: 400
sitemap:
  priority : 0.8
---
suse 12安装flink集群_CDp中自定义flink的parcel包和csd文件

本文目标
当前大数据领域中用于实时流计算的计算引擎flink可谓是如日中天，当然了自从CDH和HDP合并变成CDP后flink也可以以parcel包的方式添加到CDP服务里面。本文就是指导大家如何自定义打包flink的parcel包，并发布到CDH上，并且由CM控制服务的运行、监控服务的基本运行状态。

环境准备
内容概述：
1.环境准备
2.实操步骤
3.自定义flink parcel包
4.总结

实验环境：
1.操作系统：suse 12
2.CM和CDH版本为7.1.4
3.openjdk version "1.8.0_271"
4.Apache Maven 3.6.3
5.git version 1.8.3.1

实操步骤
一.JDK安装
1.具体下载方式以及安装方式可以参考我的csdn博客 https://blog.csdn.net/duketyson2009/article/details/97259771
2.解压安装包
3.修改配置文件vim /etc/profile

export JAVA_HOME=/usr/local/share/jdk1.8.0_271
export PATH=$PATH:$JAVA_HOME/bin
4.source /etc/profile
5.验证：java -version

2.Maven安装
1.下载maven安装包
wget https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
2.解压 tar -zxvf apache-maven-3.6.3-bin.tar.gz -C /usr/local/maven
3.修改配置文件vim /etc/profile

export MAVEN_HOME=/usr/local/maven/apache-maven-3.6.3
export PATH=$PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin
4.source /etc/profile
5.验证：mvn -V

3.Git安装
1.由于git是用C语言编写，所以如果采用tarball方式安装需要自己编译make后才可以
本文采用yum install方式简单快捷

yum install -y git
2.验证：git --version

自定义flink parcel包
以CDH5.16.2、FLINK1.9.2为例
1.下载制作包

cd /app/soft/flink
git clone https://github.com/surpass/flink-parcel.git
2.修改配置文件　flink-parcel.properties

#FLINK 下载地址
FLINK_URL=https://archive.apache.org/dist/flink/flink-1.10.2/flink-1.10.2-bin-scala_2.12.tgz
#flink版本号
FLINK_VERSION=1.10.2
#扩展版本号
EXTENS_VERSION=BIN-SCALA_2.11
#操作系统版本，以centos为例
OS_VERSION=7
#CDH 小版本
CDH_MIN_FULL=7.1
CDH_MAX_FULL=7.2
#CDH大版本
CDH_MIN=7
CDH_MAX=7
3.生成parcel文件

./build.sh  parcel
4.生成csd文件
on yarn 版本

./build.sh  csd_on_yarn
standalone版本

./build.sh  csd_standalone
总结
名词介绍
(1)parcel: 以".parcel"结尾的压缩文件。parcel包内共两个目录，其中lib包含了服务组件，meta包含一个重要的描述性文件parcel.json，这个文件记录了服务的信息，如版本、所属用户、适用的CDH平台版本等。
命名规则必须如下：
文件名称格式为三段，第一段是包名，第二段是版本号，第三段是运行平台。
例如：FLINK-1.9.2-bin-scala_2.11-el7.parcel
包名：FLINK
版本号：1.9.2-bin-scala_2.11
运行环境：el7
el6是代表centos6系统，centos7则用el7表示
parcel必须包置于/var/www/html目录下才可以被CDH发布程序时识别到。
(2)csd：csd文件是一个jar包，它记录了服务在CDH上的管理规则里面包含三个文件目录，images、descriptor、scripts,分别对应。如服务在CDH页面上显示的图标、依赖的服务、暴露的端口、启动规则等。
csd的jar包必须置于/opt/cloudera/csd/目录才可以在添加集群服务时被识别到。
相关参考：
Cloudera Manager Extensions:https://github.com/cloudera/cm_csds
FLINK官方下载地址:https://archive.apache.org/dist/flink/
CDH添加第三方服务的方法:https://blog.csdn.net/tony_328427685/article/details/86514385
---
title: "OpenShift Origin  3.9.0手动单机安装"
date: 2018-06-15T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "OpenShift Origin  3.9.0手动单机安装."
tags: ["DevOps","Continuous Integration","Continuous Delivery","CI/CD pipelines","docker","agile","Culture"]
image: "/img/openshift.jpg"
link: "https://www.openshift.com"
fact: "OpenShift是红帽的云开发平台即服务（PaaS）。自由和开放源码的云计算平台使开发人员能够创建、测试和运行他们的应用程序，并且可以把它们部署到云中。"
weight: 400
sitemap:
  priority : 0.8
---


OpenShift Origin  3.9.0手动单机安装

1.配置主机
	修改主机名为openshift.demo.com
	hostnamectl set-hostname openshift.demo.com
	
	开启SELINUX
	修改/etc/selinux/config
					SELINUX=enforcing
          SELINUXTYPE=targeted
	激活网络
	
	\# nmcli con show
docker0  1a211fa6-1001-4fa9-b5c8-e3b2dcf73e5a  bridge    docker0 
ens192   f16e6b7a-e593-4722-9ae4-1bdfa1fa4b4a  ethernet  ens192
 
\# nmcli con up ens192
\# nmcli con mod ens192 connection.autoconnect yes
\# systemctl restart NetworkManager



2.安装docker
安装依赖
yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion
安装docker
 yum install -y docker 
配置Docker镜像服务器

中国科技大学的镜像服务器进行加速。修改/etc/sysconfig/docker文件，在OPTIONS变量中追加--registry-mirror=https://docker.mirrors.ustc.edu.cn --insecure-registry=172.30.0.0/16。 


3.下载openshift-origin-server-v3.9.0-191fece-linux-64bit.tar.gz

4.解压openshift-origin-server-v3.9.0-191fece-linux-64bit.tar.gz到 /opt/openshift

5.添加到PATH

6.测试docker是否能正常下载镜像
	docker pull busybox
	
7.执行启动命令,开始下载指定版本v3.9.0所需的镜像文件
		oc cluster up --version=v3.9.0 --public-hostname=openshift.demo.com
		
		会有类似以下信息：
		Pulling image openshift/origin:v3.9.0
    Pulled 1/4 layers, 26% complete   
。。。

Pulled 4/4 layers, 100% complete



表示下载完成了并启动服务
 
		
8.启动完成后访问系统 https://openshift.demo.com:8443

9.
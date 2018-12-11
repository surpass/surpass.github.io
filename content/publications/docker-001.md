---
title: "linux如何成功地离线安装docker "
date: 2018-12-11T09:00:26+08:00
pubtype: "Talk"
featured: true
description: "linux如何成功地离线安装docker ."
tags: ["Docker"]
image: "/img/docker/docker.jpg"
link: "https://docker.com"
fact: " linux如何成功地离线安装docker 。"
weight: 400
sitemap:
  priority : 0.8
---
# linux如何成功地离线安装docker



系统环境：

Redhat 7.2 和Centos 7.4实测成功



 近期因项目需要用docker，所以记录一些相关知识，由于生产环境是不能直接连接互联网，尝试在linux中离线安装docker。

# 步骤

1.下载https://download.docker.com/linux/static/stable/x86_64/docker-18.09.0.tgz



2.解压将docker-18.09.0.tgz放置到linux用户目录下面，使用命令：tar xzvf docker-18.09.0.tgz进行解压缩，得到一个文件夹docker，然后使用命令：sudo cp docker/* /usr/bin/将docker文件夹中的内容全部移动到/usr/bin/目录下。

![解压](/img/docker/docker001-000.png)

![复制](/img/docker/docker001-001.png)

3.启动守护进程

	使用命令：sudo dockerd &来开启docker守护进程，以此来开启docker的使用

![启动服务](/img/docker/docker001-002.png)

4.验证

使用命令：docker images、docker ps -a、docker --version等

![测试](/img/docker/docker001-001.png)

5.停止守护进程

		ps -ef |grep docker  查到进程并kill掉

6.编写系统服务：

`
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
#TasksMax=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
[Install]
WantedBy=multi-user.target
`



7.启动服务

	添加权限
	
	chmod +x /etc/systemd/system/docker.service 
	
	重载unit配置文件
	
	systemctl daemon-reload 
	
	#启动Docker
	
	systemctl start docker  

 	 #设置开机自启

	systemctl enable docker.service          

8.验证

systemctl status docker                                                         #查看Docker状态

docker -v                                                                                     #查看Docker版本                               




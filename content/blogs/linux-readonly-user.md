---
title: "CentOS下性能监测工具 dstat"
date: 2020-01-28T20:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Linux只读账号配置"
tags: ["linux","account","readonly"]
keywords: ["linux","account","readonly"]
image: "/img/linux.jpg"
link: "https://centos.org/"
fact: "Linux只读账号配置"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/centos-dstat

# Linux只读账号配置

步骤
#1.创建只读shell
```
#sudo  ln -s /bin/bash  /bin/rbash
```

#2.创建用户并指定用户启动执行的shell
```
#sudo  useradd -s /bin/rbash readonly
```

#3.修改用户密码
```
sudo  passwd readonly
```

#4.创建用户shell执行命令目录
```
sudo mkdir /home/readonly/.bin
```

#5.root修改用户的shell配置文件
```
#sudo  chown root. /home/readonly/.bash_profile 
#sudo  chmod 755 /home/readonly/.bash_profile
```


#6.修改bash配置文件，主要是指定PATH的读取
```
# vi /home/readonly/.bash_profile 
# .bash_profile
 
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi
 
# User specific environment and startup programs
PATH=$HOME/bin:$HOME/.bin
export PATH
```


#7.将允许执行的命令链接到$HOME/bin目录
```
sudo ln -s /usr/bin/wc  /home/readonly/.bin/wc
sudo ln -s /usr/bin/tail  /home/readonly/.bin/tail
sudo ln -s /bin/more  /home/readonly/.bin/more
sudo ln -s /bin/cat  /home/readonly/.bin/cat
sudo ln -s /bin/grep  /home/readonly/.bin/grep
sudo ln -s /bin/find  /home/readonly/.bin/find
sudo ln -s /bin/pwd  /home/readonly/.bin/pwd
sudo ln -s /bin/ls  /home/readonly/.bin/ls
sudo ln -s /bin/ll  /home/readonly/.bin/ll


sudo chown readonly /home/readonly/.bin/*
```


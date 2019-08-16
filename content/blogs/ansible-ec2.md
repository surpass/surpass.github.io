---
title: "使用Ansible连接AWS EC2"
date: 2019-08-08T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "java finalize gc 垃圾回收 安全删除文件"
tags: ["java","finalize","GC"]
keywords: ["java","finalize","GC"]
image: "/img/ansible.jpg"
link: "https://java.oracle.com"
fact: "自动化运维工具"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/ansible-ec2

# 使用Ansible连接AWS EC2

 
 
\1. 使用Ansible ad-hoc的方式连接AWS EC2

需求：使用ansible连接上EC2执行ping等命令

前置条件：申请AWS账号，根据相关帮助文档创建免费的EC2实例(linux)

1) 第一种配置方式

hosts文件中内容：

```
[local]
localhost

[aws]
centos@52.82.*.*    //请用自己的ip
```

执行

```
ansible aws -i hosts --private-key centos.pem -m ping
```

2) 第二种配置方式：

hosts文件中内容：

```
[local]
localhost



 



[aws]
52.82.*.*
```

执行

```
ansible aws -i hosts --private-key centos.pem -m ping -u centos
```

3)第三种配置方式

hosts文件内容：

```
[local]
localhost

[aws]
52.82.*.*    ansible_ssh_private_key_file=centos.pem
52.82.*.*    ansible_ssh_user=centos
```

执行
```
ansible aws -i hosts -m ping
```

三种配置都能够执行成功。

这里也可以使用sudo来使用root用户执行ping命令

ansible aws -i hosts --private-key centos.pem -m ping -u centos -s -U root -K



-u为ssh连接时使用的用户。

-s表示用sudo，也可以使用--sudo

-U表示ssh连接后sudo的用户，也可以使用--sudo-user=SUDO_USER

-K表示可以交互的输入密码，也可以使用--ask-sudo-pass

如果sudo时只需要是默认超级用户root且不用输入密码，则只需要在ec2-user后加-s即可



还可以使用su来使用root用户执行ping命令



```
ansible aws -i hosts --private-key centos.pem -m ping -u centos -S -R root --ask-su-pass
```

-S表示为su,也可以使用--su



-R表示su用户，也可以使用--su-user=SU_USER

--ask-su-pass表示交互输入密码



上面使用的是ping模块。也可以使用如下方式来执行shell命令

ansible aws -i hosts --private-key centos.pem -a "/bin/echo hello" -u ec2-user

这里默认使用模块为command模块



\2. 使用Ansible Playbook的方式

需求：使用Ansible Playbook在EC2上创建用户

Hosts文件内容：



```
[local]
127.0.0.1



 



[aws]
52.82.*.*    ansible_ssh_private_key_file=centos.pem
52.82.*.*    ansible_ssh_user=centos
```



devel.yml文件内容
```
---
- hosts: all
  become: true
  tasks:

    - name: install jdk 1.8
      yum: name=java-1.8.0-openjdk-devel state=present
    - name: install maven
      yum: name=maven state=present

```

执行



```
ansible-playbook -i hosts -s devel.yml
```

需求：将本地文件拷贝至EC2中

devel.yml文件的tasks中增加：



```
  - name: Copy ansible inventory file to client
    copy: src=HelloWorld.java dest=/home/centos
            owner=centos group=centos mode=0644
```

执行

```
ansible-playbook -i hosts -s devel.yml
```

yml文件task中的user,copy都为ansible提供的模块名。常用的还有command, template,notify,service模块。
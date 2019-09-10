---
title: "Linux上的Systemctl命令"
date: 2019-09-10T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "Linux上的Systemctl命令."
tags: ["Linux","cenots7","Systemctl"]
image: "/img/centos.jpg"
link: "https://www.centos.org"
fact: "Linux上的Systemctl命令"
summary: "Linux上的Systemctl命令."
weight: 400
sitemap:
  priority : 0.8
---


# Linux上的Systemctl命令
转自(https://www.cnblogs.com/z0909y/p/10032168.html)

LinuxSystemctl是一个系统管理守护进程、工具和库的集合，用于取代System V、service和chkconfig命令，初始进程主要负责控制systemd系统和服务管理器。通过Systemctl –help可以看到该命令主要分为：查询或发送控制命令给systemd服务，管理单元服务的命令，服务文件的相关命令，任务、环境、快照相关命令，systemd服务的配置重载，系统开机关机相关的命令。 

### 1. 列出所有可用单元 

```
#systemctl list-unit-files
```

### 2. 列出所有运行中单元 
```
# systemctl list-units
```
### 3. 列出所有失败单元 
```
# systemctl –failed
```
### 4. 检查某个单元（如 crond.service）是否启用 
```
# systemctl is-enabledcrond.service 
```
### 5. 列出所有服务 
```
# systemctl list-unit-files –type=service
```
### 6. Linux中如何启动、重启、停止、重载服务以及检查服务（如 httpd.service）状态 

```
# systemctl start httpd.service


# systemctl restart httpd.service


# systemctl stop httpd.service


# systemctl reload httpd.service


# systemctl status httpd.service
```
注意：当我们使用systemctl的start，restart，stop和reload命令时，终端不会输出任何内容，只有status命令可以打印输出。

### 7. 如何激活服务并在开机时启用或禁用服务（即系统启动时自动启动mysql.service服务） 

```
# systemctl is-active mysql.service


# systemctl enable mysql.service


# systemctl disable mysql.service
```
### 8. 如何屏蔽（让它不能启动）或显示服务（如ntpdate.service） 

```
# systemctl mask ntpdate.service

ln -s ‘/dev/null”/etc/systemd/system/ntpdate.service’


# systemctl unmask ntpdate.service

rm ‘/etc/systemd/system/ntpdate.service’
```
### 9. 使用systemctl命令杀死服务 

```
# systemctl killcrond 
```
### 10. 列出所有系统挂载点 

```
# systemctl list-unit-files –type=mount
```
### 11. 挂载、卸载、重新挂载、重载系统挂载点并检查系统中挂载点状态 

```
# systemctl start tmp.mount


# systemctl stop tmp.mount


# systemctl restart tmp.mount


# systemctl reload tmp.mount


# systemctl status tmp.mount
```
### 12. 在启动时激活、启用或禁用挂载点（系统启动时自动挂载） 

```
# systemctl is-active tmp.mount

# systemctl enable tmp.mount

# systemctl disable tmp.mount
```
### 13. 在Linux中屏蔽（让它不能启用）或可见挂载点 

```
# systemctl mask tmp.mount

ln -s ‘/dev/null”/etc/systemd/system/tmp.mount’

# systemctl unmask tmp.mount

rm ‘/etc/systemd/system/tmp.mount’
```
### 14. 列出所有可用系统套接口 

```
# systemctl list-unit-files –type=socket
```
### 15. 检查某个服务的所有配置细节 

```
# systemctl showmysql 
```
### 16. 获取某个服务（httpd）的依赖性列表 

```
# systemctl list-dependencies httpd.service
```
### 17. 启动救援模式 

```
# systemctl rescue
```
### 18. 进入紧急模式 

```
# systemctl emergency
```
### 19. 列出当前使用的运行等级 

```
# systemctl get-default
```
### 20. 启动运行等级5，即图形模式 

```
# systemctl isolate runlevel5.target

或

# systemctl isolate graphical.target
```
### 21. 启动运行等级3，即多用户模式（命令行） 

```
# systemctl isolate runlevel3.target

或

# systemctl isolate multiuser.target
```
### 22. 设置多用户模式或图形模式为默认运行等级 

```
# systemctl set-default runlevel3.target


# systemctl set-default runlevel5.target
```
### 23. 重启、停止、挂起、休眠系统或使系统进入混合睡眠 

```
# systemctl reboot

# systemctl halt

# systemctl suspend

# systemctl hibernate

# systemctl hybrid-sleep
```
对于不知运行等级为何物的人，说明如下。

Runlevel 0 : 关闭系统

Runlevel 1 : 救援，维护模式

Runlevel 3 : 多用户，无图形系统

Runlevel 4 : 多用户，无图形系统

Runlevel 5 : 多用户，图形化系统

Runlevel 6 : 关闭并重启机器
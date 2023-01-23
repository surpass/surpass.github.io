---
title: "Keycloak学习笔记-入门之安装篇"
date: 2023-01-23T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Keycloak学习笔记-入门之安装篇"
tags: ["keycloak","IAM","oauth"]
keywords: ["keycloak","IAM","oauth"]
image: "/img/keycloak.jpg"
link: "https://www.keycloak.org/"
fact: "Keycloak学习笔记"
summary: "Keycloak学习笔记-入门之安装篇"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/keycloak-001

一、简介

keycloak是一个开源的进行身份认证和访问控制的软件。是由Red Hat基金会开发的，我们可以使用keycloak方便的向应用程序和安全服务添加身份认证，非常的方便。基于 Java 开发，支持多种数据库。



二、启动keycloak

开始之前，确保已经安装Docker。

从终端开启 keycloak，命令如下：

```
docker run -p 8080:8080 -p 8443:8443 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin123(#) quay.io/keycloak/keycloak:18.0.0 keycloak
```

以上命令将启动 Keycloak ，并暴露在本地端口8080和8443上。 该命令还将创建一个带有初始用户名为 admin 和密码为 admin123(#) 的用户。

*注：安全起见密码要重新设置*

```
location /auth {
        proxy_pass  https://X.X.X.X:8443;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
        proxy_headers_hash_max_size 51200;
        proxy_headers_hash_bucket_size 6400;
        client_max_body_size 1024m;
     }
```

三、应用示例

（1）登录管理控制台

去Keycloak管理控制台并使用之前创建的用户名和密码登录。登录后界面如下：

![img](/img/keycloak/1002.png)



图中 1 为地址，2 为 keycloak 管理控制台入口。

用启动服务的用户名和密码登录。

![img](/img/keycloak/1002-1.png)



（2）创建一个realm

在 keycloak 中，一个 realm 相当于一个租户。它允许创建独立的应用程序和用户组。master 是keycloak 中默认的 realm，master 是专用于管理 keycloak的，不建议用于自己的业务应用中。要应用于自己的应用程序时，一般建立一个指定名称的 realm。创建 realm 的步骤如下：

1、打开Keycloak管理控制台。

2、将鼠标移到左上角标有 Master 的下拉框处，在下拉处可以看到 Add realm 按钮，点击该按钮，可以看到如下界面：

![img](/img/keycloak/1004.png)



3、在右侧 Add realm 界面的 Name 处填写自己相应建立的 realm 的名称，例如： golang。

![img](/img/keycloak/1005.png)


4、点击 Create 按钮创建。

![img](/img/keycloak/1005.png)



（3）创建一个user

在新创建的 realm 中没有用户，需要先创建一个，创建步骤如下：

1、打开Keycloak管理控制台。

2、点击左侧菜单中的 Users，在弹出的右侧面板中点击 Add user，如下图：

![img](/img/keycloak/1006.png)



3、在 Add user 面板中，填写类似如下的示例信息：

用户名：demo

4、点击 Save 按钮。



5、保存成功后，设置初始密码，操作如下：

1、在出现界面点击 凭据（Credentials），出现如下界面。

![img](/img/keycloak/1007.png)


2、设置密码，设置完后，Temporary 处点击为 OFF。

3、点击 Set Password 按钮完成密码设置。

（4）配置第一个示例应用程序

现在尝试配置第一个应用程序。 第一步是用你的 Keycloak 实例注册一个应用程序，如下：

1、打开Keycloak管理控制台。

2、点击左侧的 Clients，在右侧的弹出界面点击 Create 按钮，得到 Add Client 界面。

![img](/img/keycloak/1008.png)



3、在 Add Client 界面填写相关信息，示例如下：

客户端 ID：beego

客户端协议: openid-connect

4、点击 Save 按钮。



（5）登录验证

1、打开
https://www.easyolap.cn/auth/realms/golang/account/

![img](/img/keycloak/1009.png)



2、点击 Signing In对刚才创建的demo用户进行身份验证。

如下图：

![img](/img/keycloak/1009-1.png)





a、点击 Signing In。

b、输入用户名、命名，点击登录。

![img](/img/keycloak/1010.png)

c、登录界面查看，可以看到类似 Log in by entering your password. 字样。
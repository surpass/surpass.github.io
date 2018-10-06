---
title: "Jenkins集成sonar使项目分析可视化 ！"
date: 2018-08-16T21:44:58+08:00
author: "Frank Li"
authorlink: "https://surpass.github.io/public/about"
translator: "李在超"
pubtype: "Nexus"
featured: true
description: "Jenkins集成sonar使项目分析可视化."
tags: ["Nexus","Maven","Docker","Agile","DevOps"]
keywords: ["sonar","sonar scanner","jenkins","CI/CD","DevOps","Agile"]
image: "/img/sonar/logo.svg"
link: "http://www.sonarsource.com/"
fact: ""
weight: 300
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/creations/JenkinsIntergrationSonar/

Jenkins 集成sonar 可以提供一个dashboard给项目成员和管理者，提供一个一目了然的项目分析情况，Sonar在代码分析是非常有用的工具。下面就具体说说如何进行集成。

实践目标
 * 安装和配置jenkins中sonar插件
 * 配置sonar scanner
 * 修改scanner参数
 * 执行构建


一、环境准备
---------
	本文主要说明的是 Jenkins集成sonar的过程和配置以及使用，所以相关准备工作请参照相关文档。
	以下是需要准备的环境
 * 安装和配置sonar
 * 安装和配置Jenkins
 * 安装 sonar-scanner


​						
二、Jenkins中Sonar插件的安装
---------
插件方式安装。
 * 在Jenkins中SonarQube可能通过“jenkins -》插件管理”安装;

 ![sonar_1](/img/sonar/sonar_1.png)


采用phi 文件安装方式：
 * 首先去这个url下载phi文件： http://updates.jenkins-ci.org/latest/sonar.hpi    这个是sonar最新插件，需要jenkins 2.6以上版本，可怜只好升级了一把jenkins。

        准备好hpi文件，并升级jenkins，重启后，进入jenkins：

        jenkins -》插件管理-》高级


 ![sonar_2](/img/sonar/sonar_2.png)

二、在Jenkins中配置 sonarqube server
---------

进入jenkins-》系统管理-》系统配置 后，就可以看到配置sonarqube server相关内容：

![sonar_2](/img/sonar/sonar_5.png)

“Add SonarQube”后现如下界面内容：
![sonar_2](/img/sonar/sonar_6.png)


sonar的token如果忘记了可以sonerqube server的帐户-》安全-》用户中重新生成


三、配置 SonarQube Scanner
---------
进入jenkins-》系统管理-》全局工具配置 就可以看到SonarQube Scanner如下图：

![sonar_2](/img/sonar/sonar_7.png)

填写名称后去掉"自动安装选项"（此处可以用自动按装，由于网络问题我选择手动下载，解压后，在此配置"SONAR_RUNNER_HOME"）

![sonar_2](/img/sonar/sonar_8.png)

四、配置工程的scanner参数
---------
 * 进入工程的配置页面
 * 构建配置组中选择“增加构建后步骤”
 ![sonar_2](/img/sonar/sonar_9.png)
 
 ![sonar_2](/img/sonar/sonar_10.png)

在Analysis properties中填入以下内容：
```
sonar.host.url=http://10.10.171.220:9000/sonar
sonar.projectKey=${projectName}
sonar.projectName=${projectName}
sonar.projectVersion=1.0.0
sonar.sourceEncoding=UTF-8
sonar.language=java
sonar.sources=src
sonar.java.binaries=target/classes
```

四、执行项目构建。
如果构建成功，可以到sonarqube server中能看到相关报告。
进入方式，因为jenkins已经与sonar集成了，所以在工程中有连接进入到sonarqube server,如下图：

 ![sonar_2](/img/sonar/sonar_11.png)
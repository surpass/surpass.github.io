---
title: "Nexus install by docker！"
date: 2018-08-16T21:44:58+08:00
author: "Frank Li"
authorlink: "https://surpass.github.io/public/about"
translator: "李在超"
pubtype: "Nexus"
featured: true
description: "Nexus3不仅集成了 maven 、npm 等仓库功能，而且支持 Docker了,通过实验，发现 Nexus 3 能够基本满足需求."
tags: ["Nexus","docker","maven"]
keywords: ["Nexus","docker"]
image: "/img/nexus/nexus.png"
link: "https://www.sonatype.com/"
fact: ""
weight: 500
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/publications/nexus-001-install-by-docker/


一、环境准备
---------
	安装docker,本文使用的版本为docker Server Version: 17.11.0-ce
	定义域名和购买域名，制作私有证书或购买，本文采用已有域名，申请免费证书实现。


​						
二、下载镜像并启协服务
---------
ATLASSIAN_HOME=/data/nexus/
docker run -d \
--name nexus \
--hostname nexus \
--user root:root \
--restart always \
-v $ATLASSIAN_HOME/work:/nexus-data \
-p 8081:8081 \
-p 8082:8082 \
-p 6000-6010:6001-6010 \
-e NEXUS_CONTEXT=nexus \
sonatype/nexus3:3.13.0

三、修改容器内的配置文件
---------
/opt/sonatype/nexus/etc/nexus-default.properties添加“application-port-ssl=8082” 和 修改nexus-args的值增加“${jetty.etc}/jetty-https.xml,”

修改前

```
 
\# Jetty section
application-port=8081
application-host=0.0.0.0
nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-requestlog.xml
nexus-context-path=/${NEXUS_CONTEXT}

\# Nexus section
nexus-edition=nexus-pro-edition
nexus-features=\
 nexus-pro-feature
nexus.clustered=false
 
```

修改后


```
\# Jetty section
application-port=8081
application-port-ssl=8082
application-host=0.0.0.0
nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-requestlog.xml
nexus-context-path=/${NEXUS_CONTEXT}

\# Nexus section
nexus-edition=nexus-pro-edition
nexus-features=\
 nexus-pro-feature
nexus.clustered=false
 
```



四、启用https服务
---------
修改容器内的${jetty.etc}/jetty-https.xml配置文件，并上传证书到/opt/sonatype/nexus/etc/ssl目录下

修改内容为：

```
<New id="sslContextFactory" class="org.eclipse.jetty.util.ssl.SslContextFactory">
    <Set name="KeyStorePath"><Property name="ssl.etc"/>/keystore.jks</Set>
    <Set name="KeyStorePassword">fsdf!QAZ</Set>
    <Set name="KeyManagerPassword">fsdf!QAZ</Set>
    <Set name="TrustStorePath"><Property name="ssl.etc"/>/keystore.jks</Set>
    <Set name="TrustStorePassword">1qaz!QAZ</Set>
    ...
```


上传证书到/opt/sonatype/nexus/etc/ssl并重命名为keystore.jks，（证书可以申请免费的证书一般一年的有效期，学习用足够了）

五、重起服务			
---------
$$
docker restart  containerId		\#\# containerId 通过docker ps 可以查到
$$

六、访问测试
---------
地址(domain.com根据自己的实际进行替换)
	https://domain.com:8082/nexus/		

七、登录测试
---------
   以默认用户名admin和密码admin123，及时修改密码，根据业务添加相关用户

到此nexus安装完成，关地nexus做为maven私服和docker私服，后续会有相关笔记分享，敬请关注！
```

```
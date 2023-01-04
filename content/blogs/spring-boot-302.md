---
title: "spring boot - Host头攻击技术解析及防御"
date: 2023-01-04T20:00:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "spring boot - host header poisoning 安全隐患修复"
tags: ["spring boot","host header poisoning","安全","漏洞"]
keywords: ["spring boot","host header poisoning","安全","漏洞"]
image: "/img/spring-boot.jpg"
link: "https://spring.io/"
fact: "spring boot学习笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/spring-boot-302

关于spring boot应用中host header poisoning, Host头攻击技术解析及防御


一、问题复现
```
curl -v -k https://xxx.xxx.xxx.xxx/test/login/oauth2/code/iam  -H "X-Forwarded-Host: test.domain.com"
* About to connect() to xxx.xxx.xxx.xxx port 443 (#0)
*   Trying 192.168.139.110
* Connected to xxx.xxx.xxx.xxx (192.168.139.110) port 443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
* skipping SSL peer certificate verification
* Server certificate:
*       subject: 略
*       start date: Aug 04 02:25:13 2021 GMT
*       expire date: Aug 03 02:25:13 2026 GMT
*       common name: xxx.xxx.xxx.xxx
*       issuer: 略
> GET /test/login/oauth2/code/iam HTTP/1.1
> User-Agent: curl/7.29.0
> Host: xxx.xxx.xxx.xxx
> Accept: */*
> X-Forwarded-Host: test.domain.com
>
< HTTP/1.1 302 Found
< Cache-Control: no-cache, no-store, max-age=0, must-revalidate
< Pragma: no-cache
< Expires: 0
< Location: http://test.domain.com/test/login?error
< Vary: Origin,Access-Control-Request-Method,Access-Control-Request-Headers
< Server: istio-envoy
< Set-Cookie: SESSION=NjBjODdjOdYtMThmsS00NDZjLTlkYjAtZdYyZjQ1MTY4MjA5; Path=/; Secure; HttpOnly; SameSite=Lax
< server-timing: intid;desc=1cacefe0f2600bf9
< x-content-type-options: nosniff
< x-xss-protection: 1; mode=block
< x-frame-options: DENY
< x-envoy-upstream-service-time: 24
< Date: Wed, 04 Jan 2023 05:19:41 GMT
< Content-Length: 0
<
* Connection #0 to host xxx.xxx.xxx.xxx left intact 
```

由于安全问题，xxx.xxx.xxx.xxx 代替原域名信息



二、问题分析

1.搜索“要”

根据文章添加Interceptor或filter进行拦截或过滤，以HandlerInterceptor为例

部分代码如下

```
 @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse resp, Object handler) throws Exception {
    	//打印日志...
        String host = req.getHeader("host");
        String forwardHost = req.getHeader("X-Forwarded-Host");
        ...
		然后验证是否在白名单中，如果不在则返回

         resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);// 401
         return false;
```

重新测试,请求没有到达Interceptor.

2.继续分析,由于反回的code为302. 应答的Location中有error字样,分析脚手架的SpringBoot Security配置有关,由于SecurityConfigurer没有配置failureHandler处理方法.添加自定义处理方法,如下:

```
class	SecurityConfig extends WebSecurityConfigurerAdapter{
...
 @Override
    protected void configure(HttpSecurity http) throws Exception {
		http...
		//增加
		.failureHandler((httpServletRequest, 
                                           httpServletResponse, 
                                           authentication) -> {
                                httpServletResponse.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                 })
...
}
```





三、验证修复结果

```
curl -v -k https://xxx.xxx.xxx.xxx/test/login/oauth2/code/iam  -H "X-Forwarded-Host: test.domain.com:443"
*   Trying 192.168.139.110...
* TCP_NODELAY set
* Connected to xxx.xxx.xxx.xxx (192.168.139.110) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
...
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server did not agree to a protocol
* Server certificate:
*  subject: 略
*  start date: Aug  4 02:25:13 2021 GMT
*  expire date: Aug  3 02:25:13 2026 GMT
*  issuer: DC=cn; DC=bmwbrill; CN=BBA Issuing CA01
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
> GET /test/login/oauth2/code/iam HTTP/1.1
> Host: xxx.xxx.xxx.xxx
> User-Agent: curl/7.60.0
> Accept: */*
> X-Forwarded-Host: test.domain.com:443
>
< HTTP/1.1 401 Unauthorized 
< Cache-Control: no-cache, no-store, max-age=0, must-revalidate
< Pragma: no-cache
< Expires: 0
< Vary: Origin,Access-Control-Request-Method,Access-Control-Request-Headers
< Server: ...
< server-timing: intid;desc=1993ed695aa0a25d
< x-content-type-options: nosniff
< x-xss-protection: 1; mode=block
< x-frame-options: DENY
< x-envoy-upstream-service-time: 30
< Date: Wed, 04 Jan 2023 08:10:00 GMT
< Content-Length: 0
<
* Connection #0 to host xxx.xxx.xxx.xxx left intact
```

到此Host头攻击防御完成.
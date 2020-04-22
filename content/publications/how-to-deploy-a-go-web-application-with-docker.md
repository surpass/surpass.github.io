---
title: "如何用Docker部署一个Go开发的web应用"
date: 2020-04-21T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/about/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "如何用Docker部署一个Go开发的web应用"
tags: ["golang","Docker","go","web","DevOps"]
keywords: ["golang","Docker","go","web","DevOps"]
image: "/img/go.jpg"
link: "https://golang.org/"
fact: "golang学习笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/publications/how-to-deploy-a-go-web-application-with-docker

#如保用Docker部署一个Go开发的web应用(学习记录)
参照 ：https://semaphoreci.com/community/tutorials/how-to-deploy-a-go-web-application-with-docker

### 简介：
大多数Go应用程序都是经过编译为二进制文件进行发布，但web应用程序也附带模板、图片资源和配置文件等；
这些文件可能不能编译到二进制文件中，导制程序出错。

Docker允许我们创建一个包含应用程序所有依赖的内容和资源为独立图像。
在本学习示例中，将学习如何使用Docker部署Go web应用程序，以及Docker如何帮助改进开发工作流和部署过程。

### 目标：

- 了解Docker如何帮助您开发围棋应用程序

- 了解如何创建Docker容器

- 了解如何使用持续集成和交付（CI/CD）自动构建Docker映像。



### 前置条件：

1.您需要拥有一台安装有Docker的机器。

2.Docker Hub帐户

3.GitHub帐户

4.Docker  Version:      19.03.8


### Docker：

Docker帮助我们的应用程序创建一个可部署的单元。这个单元，也称为容器，拥有应用程序工作所需的一切。这包括代码（或二进制文件）、运行时、系统工具和库以及相关配置文件。

容器消除了由于文件不同步或生产环境中的细微差异而导致的一些问题。

在开发中使用Docker的一些好处包括：

- 所有团队成员使用的标准开发环境，

- 集中更新依赖项并在任何地方使用相同的容器，

- 开发环境与生产环境相同

- 屏蔽可能只在生产中出现的潜在问题

创建github库过程略。

### 创建个Demo示例
创建一个简单的web 应用。命名为demo-math-app

- 实现数字运算的rest路径，

- 对视图使用HTML模板，

- 使用配置文件自定义应用程序，

- 包括对选定功能的测试。

例如 访问 /sum/3/6将显示一个页面，结果是3和6求和的结果页面。同样，访问/product/3/6将显示一个包含3和6的乘积的页面。

完成后，demo-math-app的目录结构将如下所示：
```
    ├── Dockerfile
    ├── Dockerfile.deploy
    └── src
        ├── conf
        │   └── app.conf
        ├── go.mod
        ├── go.sum
        ├── main.go
        ├── main_test.go
        ├── pkg
        │   └── mod
        │       └── cache
        │           └── lock
        └── vendor

```

应用程序主文件是位于src目录下的main.go。此文件包含应用程序的所有功能。main.go中的一些功能是使用main_test.go完成测试的。

views文件夹包含视图文件invalid-route.html和result.html。

配置文件app.conf位于conf文件夹中。

Beego使用此文件自定义应用程序。

初使化项目:
```
$ export GOFLAGS=-mod=vendor
$ export GO111MODULE=on
$ go mod init github.com/YOUR_GITHUB_USER/YOUR_REPOSITORY_NAME 
# (example: go mod init github.com/surpass/go-web-docker)
```

让我们创建文件结构：

```
$ mkdir src
$ mkdir src/conf 
$ mkdir src/views
$ cd src
```

主程序文件demo-math.go,内容如下：
```
package main

import (
    "strconv"
    
    "github.com/astaxie/beego"
)


func main() {
    /* This would match routes like the following:
       /sum/3/5
       /product/6/23
       ...
    */
    beego.Router("/:operation/:num1:int/:num2:int", &mainController{})
    beego.Run()
}

type mainController struct {
    beego.Controller
}


func (c *mainController) Get() {

    //Obtain the values of the route parameters defined in the route above    
    operation := c.Ctx.Input.Param(":operation")
    num1, _ := strconv.Atoi(c.Ctx.Input.Param(":num1"))
    num2, _ := strconv.Atoi(c.Ctx.Input.Param(":num2"))

    //Set the values for use in the template
    c.Data["operation"] = operation
    c.Data["num1"] = num1
    c.Data["num2"] = num2
    c.TplName = "result.html"

    // Perform the calculation depending on the 'operation' route parameter
    switch operation {
    case "sum":
        c.Data["result"] = add(num1, num2)
    case "product":
        c.Data["result"] = multiply(num1, num2)
    default:
        c.TplName = "invalid-route.html"
    }
}

func add(n1, n2 int) int {
    return n1 + n2
}

func multiply(n1, n2 int) int {
    return n1 * n2
}
```

测试程序文件demo-math_test.go：
```
package main

import "testing"

func TestSum(t *testing.T) {
    if add(2, 5) != 7 {
        t.Fail()
    }
    if add(2, 100) != 102 {
        t.Fail()
    }
    if add(222, 100) != 322 {
        t.Fail()
    }
}

func TestProduct(t *testing.T) {
    if multiply(2, 5) != 10 {
        t.Fail()
    }
    if multiply(2, 100) != 200 {
        t.Fail()
    }
    if multiply(222, 3) != 666 {
        t.Fail()
    }
}
```

视图文件内容：
views/result.html
```
<!doctype html>
<html>
    <head>
        <title>MathApp - {{.operation}}</title>
    </head>
    <body>
        The {{.operation}} of {{.num1}} and {{.num2}} is {{.result}}
    </body>
</html>
```
views/invalid-route.html
```
<!doctype html>
<html>
    <head>
        <title>MathApp</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta charset="UTF-8">
    </head>

    <body>
        Invalid operation
    </body>
</html>
```

配置文件conf/app.conf：
```
appname = demo-math-app
runmode = "dev"
httpport = 8080
```
配置项说明:

- appname: web应用名,
- httpport: web服务端口
- runmode: 指定应用程序应在哪种模式下运行。有效值包括:dev用于开发的和prod用于生产的。


使用以下命令下载moudle:

```bash
$ go mod download
$ go mod vendor
$ go mod verify
```
由于某些原因下载慢，可以使用以下配置，效果不错：
```
export GOPROXY=https://goproxy.io
```


### 在开发过程中使用Docker

以下步骤将在开地过程中命名用 Docker进行介绍

#### 配置Docker进行开发

步骤1.创建Dockerfile文件
在项目的根目录创建Dockerfile文件，内容如下：
```
FROM golang:1.14

RUN go get -u github.com/beego/bee

ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor
ENV APP_USER app
ENV APP_HOME /go/src/demo-math-app

ARG GROUP_ID
ARG USER_ID

RUN groupadd --gid $GROUP_ID app && useradd -m -l --uid $USER_ID --gid $GROUP_ID $APP_USER
RUN mkdir -p $APP_HOME && chown -R $APP_USER:$APP_USER $APP_HOME

USER $APP_USER
WORKDIR $APP_HOME
EXPOSE 8010
CMD ["bee", "run"]
```
关于Dockerfiler不在此介绍，相关配置说明可以查看Dockerfile使用说明进行学习。

步骤2：构建镜像(普通用户操作)
```
sudo docker build \
         --build-arg USER_ID=$(id -u) \
         --build-arg GROUP_ID=$(id -g) \
         -t demo-math-app .
```

如果第一次使用，会先下载基础镜像，时间可能会长一些。

查看生成的镜像：
```
docker images
```

```
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
demo-math-app       latest              4bf11a9bd1be        About a minute ago   848 MB
docker.io/golang    1.14                a1c86c07867e        4 days ago           809 MB

```

demo-math-app为生成的镜像

步骤3：

```
sudo docker run -it --rm -p 8080:8080 -v $PWD/src:/go/src/demo-math-app  demo-math-app
```
控制台上显示类似以下内容：
```
______
| ___ \
| |_/ /  ___   ___
| ___ \ / _ \ / _ \
| |_/ /|  __/|  __/
\____/  \___| \___| v1.10.0
2020/04/21 06:58:35 INFO     ▶ 0001 Using 'demo-math-app' as 'appname'
2020/04/21 06:58:35 INFO     ▶ 0002 Initializing watcher...
github.com/shiena/ansicolor
golang.org/x/text/transform
github.com/astaxie/beego/config
gopkg.in/yaml.v2
github.com/astaxie/beego/utils
github.com/astaxie/beego/logs
github.com/astaxie/beego/grace
github.com/astaxie/beego/session
github.com/astaxie/beego/toolbox
golang.org/x/crypto/acme
golang.org/x/text/unicode/norm
golang.org/x/text/unicode/bidi
github.com/astaxie/beego/context
golang.org/x/text/secure/bidirule
golang.org/x/net/idna
github.com/astaxie/beego/context/param
golang.org/x/crypto/acme/autocert
github.com/astaxie/beego
github.com/surpass/go-web-docker
2020/04/21 07:04:20 SUCCESS  ▶ 0003 Built Successfully!
2020/04/21 07:04:20 INFO     ▶ 0004 Restarting 'demo-math-app'...
2020/04/21 07:04:20 SUCCESS  ▶ 0005 './demo-math-app' is running...
2020/04/21 07:04:20.400 [I] [asm_amd64.s:1373]  http server Running on http://:8080
2020/04/21 07:04:37.385 [D] [server.go:2807]  |   172.35.5.236| 404 |   7.153878ms| nomatch| GET      /  
2020/04/21 07:04:37.503 [D] [server.go:2807]  |   172.35.5.236| 404 |   51.73699ms| nomatch| GET      /favicon.ico
2020/04/21 07:04:39.970 [D] [server.go:2807]  |   172.35.5.236| 404 |    200.756µs| nomatch| GET      /  
2020/04/21 07:04:51.702 [D] [server.go:2807]  |   172.35.5.236| 200 | 147.117151ms|   match| GET      /sum/4/5   r:/:operation/:num1:int/:num2:int
2020/04/21 07:04:59.511 [D] [server.go:2807]  |   172.35.5.236| 200 |  10.267659ms|   match| GET      /sum/5/6   r:/:operation/:num1:int/:num2:int
2020/04/21 07:05:12.560 [D] [server.go:2807]  |  192.168.9.149| 404 |    633.162µs| nomatch| GET      /  
2020/04/21 07:05:12.879 [D] [server.go:2807]  |  192.168.9.149| 404 |  15.559908ms| nomatch| GET      /HNAP1/

```

验证结果，在浏览器地址中输入 `http://localhost:8080/sum/4/5`

应该能看到以下内容：
```
The sum of 5 and 6 is 11
```

### 在生产环境使用Docker

以下步骤将在生产环境中命名用 Docker进行介绍

#### 配置Docker
在根目录下创建Dockerfile.deploy，内容如下:
```
# Dockerfile.deploy

FROM golang:1.14 as builder

ENV APP_USER app
ENV APP_HOME /go/src/demo-math-app
ENV GOPROXY=https://goproxy.io

RUN groupadd $APP_USER && useradd -m -g $APP_USER -l $APP_USER
RUN mkdir -p $APP_HOME && chown -R $APP_USER:$APP_USER $APP_HOME

WORKDIR $APP_HOME
USER $APP_USER
COPY src/ .

RUN go mod download
RUN go mod verify
RUN go build -o demo-math-app

FROM debian:buster

ENV APP_USER app
ENV APP_HOME /go/src/demo-math-app

RUN groupadd $APP_USER && useradd -m -g $APP_USER -l $APP_USER
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY src/conf/ conf/
COPY src/views/ views/
COPY --chown=0:0 --from=builder $APP_HOME/demo-math-app $APP_HOME

EXPOSE 8080
USER $APP_USER
CMD ["./demo-math-app"]
```

构建发布的镜像：
```
$ sudo docker build -t demo-math-app-deploy -f Dockerfile.deploy .
```

发布测试：
```
$ sudo docker run -it -p 8010:8010 demo-math-app-deploy
```

### 把程序推送到Github
```
git init
git add.
git commit -m "initial commit"

git remote add origin https://github.com/surpass/go-web-docker.git
git push origin master
```
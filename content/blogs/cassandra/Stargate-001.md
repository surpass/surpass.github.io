---
title: "Stargate-星门初识"
date: 2021-08-07T22:30:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate-一个为数据打造的开源API框架"
tags: ["分布式数据平台","Data Mesh","Stargate	"]
keywords: ["centos","screen","远程执行"]
image: "/img/stargate.jpg"
link: "https://stargate.io/"
fact: "Stargate-数据API框架"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://stargate.io/docs/stargate/1.0/quickstart/quick_start-document.html

测试机信息：Centos 7 , ip:192.168.139.6  绑定域名：api.easyolap.cn

# Stargate-星门初识-笔记

## **一、背景**
	在不断的做项目过程中多多少少会都涉到的数据存储，从文本到关系数据库，再到大数据及NoSql等会在众多的数据库产品中进行不断的切换升级，大云原生的浪潮下工作之余思考一个问题能否构建初一个相对通用的数据平台或接口，对应用及业务屏蔽数据存储层的变化，由于一直以业关注Cassandra，所以偶然的一个机会看到了Stargate项目,阅读过相关文章，发现这个项目非常有意思，就首手研究起来，先把功能运行起来体验一下其本功能。

## **二、简介**
**什么是Stargate**
    Stargate是一个为数据打造的开源API框架,Stargate的目标就是让你的数据在任何你能想到的API中间自由存取，且不受限于提供支持的数据存储方式。目前为止，从Apache Cassandra开始，将其作为第一个后台，并实现了用Cassandra查询语言(CQL)和Document API、REST API、GraphQL API来实现对数据的增删改查。随着时间和开发者的加入，Stargate也将支持使用更多其它的API。开放源码：[Github](https://github.com/stargate/stargate)

![img](/images/blog/cassandra/stargate-001-002.png)

**Stargate的工作原理**
    Stargate是一种数据网关组件，它被部署于客户端应用程序和数据库之间。选择Cassandra作为第一个数据库，是因为Cassandra解决了世界上最难的伸缩和可用性挑战，先开发用于Cassandra的各种API是比较容易实现的。可以根据扩展其它存储形式。选择这样的设计，是因为Cassandra的协调节点已经在处理大多数高可用的存储代理(storage proxy)所需的请求处理和请求路由。继续使用这种经过时间验证的逻辑是合理的。这种使用云基础设施时常见的架构使得计算能力的伸缩可以独立于存储。 

下面这张精简的架构图解释了Stargate在整个应用程序栈中所处的位置，以及未来可以期待看到的更多的API和集成。
![img](/images/blog/cassandra/stargate-001-002.png)
如图所示，请求会由API Service来处理，将其翻译成数据库请求并传送至Persistence Service（持久化服务）。接着，Persistence Service会用Cassandra内部的QueryHandler（请求处理器）将这个请求发送至多个存储副本。

## **三、迅速上手**

下面是一个Document API的例子，您将使用 Document API 插件在本地计算机上启动并运行，该插件公开对存储在 Cassandra 表中的数据的 CRUD 访问。想要动手试试这个例子？你可以下载Docker 已安装并正在运行（如果使用 Docker），curl或Postman 运行 Api调用,本文以curl为例。

此映像包含 Cassandra 查询语言 (CQL)、REST、Document、GraphQL API 和 GraphQL Playground，以及 Apache Cassandra ™ 4.0 后端。

```
docker pull stargateio/stargate-4_0:v1.0.29
```
以开发者模式启动 Stargate 容器。开发人员模式无需设置单独的 Cassandra 实例，用于开发和测试很方便。
```
docker run --name stargate \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 127.0.0.1:9042:9042 \
  -d \
  -e CLUSTER_NAME=stargate \
  -e CLUSTER_VERSION=4.0 \
  -e DEVELOPER_MODE=true \
  stargateio/stargate-4_0:v1.0.29
  
```
Docker安装 、配置、排错等请参照Docker相关文章



The default ports assignments align to the following services and interfaces:

| Port | Service/Interface                                            |
| ---- | ------------------------------------------------------------ |
| 8080 | GraphQL interface for CRUD                                   |
| 8081 | REST authorization service for generating tokens             |
| 8082 | REST interface for CRUD and Document API                     |
| 8084 | Health check (/healthcheck, /checker/liveness, /checker/readiness) and metrics (/metrics) |
| 9042 | CQL service                                                  |



## Document API 的 Swagger UI

启动 Docker 容器后，您可以在浏览器中访问 Document API `http://api.easyolap.cn:8082/swagger-ui`。添加参数信息，可以生成`curl`命令执行并显示将返回的结果。
![img](/images/blog/cassandra/stargate-001-003.png)


## 使用身份验证 API 生成身份验证令牌
为了使用 Stargate Document API，必须生成授权令牌才能访问该接口。
下面的步骤`curl`用于访问 REST 接口以生成所需的令牌。

### 生成授权令牌
首先在`X-Cassandra-Token`标头中的每个后续请求中生成一个身份验证令牌。请注意，身份验证服务的端口是 8081。

```bash
curl -L -X POST 'http://api.easyolap.cn:8081/v1/auth' \
  -H 'Content-Type: application/json' \
  --data '{
    "username": "cassandra",
    "password": "cassandra"
}'
```
您应该在响应中收到一个令牌。

```json
{"authToken":"e363d539-2b49-4fa3-9474-7bcb828977a2"}
```
执行结果以实际为准，每次或不同人执行的返回结果会不一样。
如果不生成访问令牌，会有类似以下提示：
```
{"description":"Role unauthorized for operation: Missing token","code":401}
```

### 使用身份验证令牌

将身份验证令牌存储在环境变量中以使其易于与`curl`.

```bash
export AUTH_TOKEN=e363d539-2b49-4fa3-9474-7bcb828977a2
```


## 创建模式(schema)

为了使用文档 API，您必须创建模式来定义将存储数据的命名空间和集合。命名空间是一个容器，它 `replication factor`定义了数据库将存储的数据副本的数量。集合由非结构化的 JSON 文档组成。文档本身可以包含多个文档。一个命名空间中包含多个集合，但一个集合不能包含在多个命名空间中。

## 命名空间

使用 Document API，您必须创建命名空间作为存储集合的容器，而集合又存储文档。文档本身可以包含多个文档。一个命名空间中包含多个集合，但一个集合不能包含在多个命名空间中。

只需要专门创建命名空间。插入文档时指定集合。可选设置`replicas`定义了数据库将为命名空间存储的数据副本数。如果未定义副本，则对于单个数据中心集群中的命名空间，默认值为 1，对于多数据中心集群，每个数据中心的默认值为 3。

### 创建命名空间(namespace)

#### 命名空间
向 发送`POST`请求`/v2/schemas/namespaces`。在这个例子中，我们使用`easyolapdemo`了`name`，也没有`replicas`设置，默认为1。

```shell
curl --location --request POST 'http://api.easyolap.cn:8082/v2/schemas/namespaces' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "name": "easyolapdemo"
}'
```
AUTH_TOKEN在令牌环节进行了设置。

结果：
```json
{"name":"easyolapdemo"}
```
### 检查命名空间是否存在

要检查namespace是否存在，请执行 Document API 查询`curl`以查找所有命名空间：
```shell
curl -L -X GET 'http://api.easyolap.cn:8082/v2/schemas/namespaces' \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H 'Content-Type: application/json'
```
结果：
```json
{"data":[{"name":"system_schema"},{"name":"system"},{"name":"system_auth"},{"name":"system_distributed"},{"name":"system_traces"},{"name":"stargate_system"},{"name":"data_endpoint_auth"},{"name":"easyolapdemo"}]}

```

要获取特定命名空间，请在 URL 中指定命名空间：

命令
```shell
curl -X GET 'api.easyolap.cn:8082/v2/schemas/namespaces/easyolapdemo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
结果：
```
{"data":{"name":"easyolapdemo"}}

```

### 删除命名空间
发送`DELETE`请求以`/v2/schemas/namespaces/{namespace_name}`删除命名空间。所有集合和文档都将与命名空间一起被删除。(文档操作完再执行：）)

```bash
curl -L -X DELETE 'api.easyolap.cn:8082/v2/schemas/namespaces/easyolapdemo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'

curl -X GET 'api.easyolap.cn:8082/v2/schemas/namespaces/easyolapdemo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
查询确认删除结果:
```
{"description":"unable to describe namespace","code":404}
```

## 数据存储测试

### 创建(写)文件（writing_documents)

使用 Document API 编写的所有数据都存储为存储在集合中的 JSON 文档。

#### 添加指定集合名称的文档
首先，让我们将文档添加到指定的集合中。发送`POST`请求以`/v2/namespaces/{namespace_name}/collections/{collections_name}` 将数据添加到集合中`demodata`。数据在 JSON 正文中传递。
```shell
curl --location \
--request POST 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
  "id": "demo",
  "other": "This is demo."
}'
```

```json
{"documentId":"c69cb2b3-60ed-484d-bdfb-b6eeb53143de"}
```


请注意，`document-id`如果未指定，则返回的是 UUID。

#### 添加指定集合名称和文档 ID 的文档

接下来，让我们将文档添加到指定的集合中，但指定`document-id`. 发送`PUT`请求以 `/v2/namespaces/{namespace_name}/collections/{collections_name}/{document-id}` 将数据添加到集合中`Janet`。该`document-id`可以是任何字符串。数据在 JSON 正文中传递。

```shell
curl -L -X PUT 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/demo2' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
  "firstname": "Li",
  "lastname": "Fank",
  "email": "surpass_li@aliyun.com",
  "favorite color": "blue"
}'
```

```
{"documentId":"demo2"}
```
注意使用`POST`和之间的区别`PUT`。`POST`当您希望系统自动生成 documentId 时，该请求用于插入新文档。该`PUT`请求用于在您要指定 documentId 时插入新文档。`PUT`请求也可用于更新现有文档。接下来让我们看看这些例子。

### 读文件(reading_documents)

#### 查询所有文件(retrieving_all_documents)

让我们检查文档是否已插入。发送`GET`请求以 `/v2/namespaces/{namespace_name}/collections/{collections_name}`检索所有文档：
```shell
curl --location \
--request GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata?page-size=3' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
结果：
```
{"data":{"demo2":{"email":"surpass_li@aliyun.com","favorite color":"blue","firstname":"Li","lastname":"Fank"},"c69cb2b3-60ed-484d-bdfb-b6eeb53143de":{"id":"demo","other":"This is demo."}}}
```
共查得两条记录

#### 查询指定文档(retrieving_a_specified_document)

让我们检查是否为特定文档插入了数据。发送`GET`请求以`/v2/namespaces/{namespace_name}/collections/{collections_name}/{document-id}` 检索文档：

```shell
curl -L \
-X GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/c69cb2b3-60ed-484d-bdfb-b6eeb53143de' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
以document-id：c69cb2b3-60ed-484d-bdfb-b6eeb53143de为例
结果:
```
{"documentId":"c69cb2b3-60ed-484d-bdfb-b6eeb53143de","data":{"id":"demo","other":"This is demo."}}
```
可以使用以下两种方法之一获取文档中特定字段的值，`where`子句或`document-path`。这些方法可以从文档或子文档中检索信息。

#### 使用 where 子句过滤文档
现在让我们使用`where`子句搜索特定文档。发送`GET`请求以 `/v2/namespaces/{namespace_name}/collections/{collections_name}?{where-clause}` 获取相同的信息：

```shell
curl -L -X  GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata?where=\{"firstname":\{"$eq":"Li"\}\}' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
请注意，该`where`子句必须是 url 编码的，因此大括号转义为`\`，空格必须替换为`%20`。此外，将返回完整文档，而不是`{document-path}`像下一个命令中指定的字段值 。

```
{"data":{"demo2":{"email":"surpass_li@aliyun.com","favorite color":"blue","firstname":"Li","lastname":"Fank"}}}
```

### 更新文件(update documents)

数据更改，因此经常需要更新整个文档。

#### 替换文档(replace document)

发送`PATCH`请求以 `/v2/namespaces/{namespace_name}/collections/{collections_name}/{document-id}` 将数据替换到现有集合。包含的所有字段都将更改。
```shell
curl -L \
-X PATCH 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/demo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "firstname": "Demo",
    "lastname": "Data"
}'
```
结果:
```
{"documentId":"demo"}
```
一个`GET`请求，将显示该数据已在文件中被替换：

```shell
curl -L -X GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/demo' \
 --header "X-Cassandra-Token: $AUTH_TOKEN" \
 --header 'Content-Type: application/json'
```
结果:
```
{"documentId":"demo","data":{"firstname":"Demo","lastname":"Data"}}
```
### 删除文档

要删除文档，请向 发送`DELETE`请求 `/v2/namespaces/{namespace_name}/collections/{collections_name}/{document-id}`。

```bash
curl -L \
-X DELETE 'http://api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/demo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
查询验证是否已删除

```shell
curl -L \
-X GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata/demo' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
以document-id：demo为例
结果:
```
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
<title>Error 404 Not Found</title>
</head>
<body><h2>HTTP ERROR 404 Not Found</h2>
<table>
<tr><th>URI:</th><td>/v2/namespaces/easyolapdemo/collections/demodata/demo</td></tr>
<tr><th>STATUS:</th><td>404</td></tr>
<tr><th>MESSAGE:</th><td>Not Found</td></tr>
<tr><th>SERVLET:</th><td>jersey</td></tr>
</table>

</body>
</html>
```
查询多个测试：
```
curl --location \
--request GET 'api.easyolap.cn:8082/v2/namespaces/easyolapdemo/collections/demodata?page-size=3' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json'
```
结果：
```
{"data":{"demo2":{"email":"surpass_li@aliyun.com","favorite color":"blue","firstname":"Li","lastname":"Fank"},"c69cb2b3-60ed-484d-bdfb-b6eeb53143de":{"id":"demo","other":"This is demo."}}}
```
证明documentid为demo的已被删除。


瞧！有关文档 API 的更多信息，请参阅API 参考部分中的 [使用文档 API](https://stargate.io/docs/stargate/1.0/developers-guide/document-using.html) 或[文档 API](https://stargate.io/docs/stargate/1.0/attachments/docv2.html)。

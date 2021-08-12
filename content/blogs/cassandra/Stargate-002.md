---
title: "Stargate-rest api"
date: 2021-08-12T21:30:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate rest api"
tags: ["rest api","Data Mesh","Stargate"]
keywords: ["rest api","Data Mesh","Stargate"]
image: "/img/stargate.jpg"
link: "https://stargate.io/"
fact: "Stargate rest api"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://stargate.io/docs/stargate/1.0/quickstart/quick_start-rest.html

测试机信息：Centos 7 , ip:192.168.139.6  绑定域名：api.easyolap.cn

 本次使用上次实验的镜像。

[Stargate-简介及Document ApiI](stargate-001) 

[Stargate-REST ApiI](stargate-002) 
# Stargate REST API

## **一、简介**
​       Stargate 是部署在客户端应用程序和数据库之间的数据网关。在本快速入门中，您将使用 REST API 插件在本地计算机上启动并运行，该插件公开对存储在 Cassandra 表中的数据的 CRUD 访问。开放源码：[Github](https://github.com/stargate/stargate)

![img](/images/blog/cassandra/stargate-001-004.png)

## **二、快速上手**

下面是一个Stargate REST API的例子，您将使用 REST API 插件在本地计算机上启动并运行，该插件公开对存储在 Cassandra 表中的数据的 CRUD 访问。想要动手试试这个例子？你可以下载Docker 已安装并正在运行（如果使用 Docker），curl或Postman 运行 Api调用,本文以curl为例。

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




## 使用身份验证 API 生成身份验证令牌
为了使用 Stargate Document API，必须生成授权令牌才能访问该接口。

下面的步骤`cURL`用于访问 REST 接口以生成所需的令牌。

###   生成授权令牌

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
{"authToken":"844112a9-ddd5-479d-93ee-7229f1ffb4c3"}
```
执行结果以实际为准，每次或不同人执行的返回结果会不一样。
如果不生成访问令牌，会有类似以下提示：
```
{"description":"Role unauthorized for operation: Missing token","code":401}
```

### 使用身份验证令牌

将身份验证令牌存储在环境变量中以使其易于与`curl`.

```bash
export AUTH_TOKEN=844112a9-ddd5-479d-93ee-7229f1ffb4c3
```


## 创建Schema

为了使用 REST API，您必须创建模式来定义将存储数据的keyspace和table。keyspace是一个容器，replication factor`(副本数)定义了数据库将存储的数据副本的数量。table定义数据类型的列组成。一个keyspace中可以包含多个table，但一个table不能包含在多个keyspace中。

 创建keyspace

#### 命名空间
向 发送`POST`请求`/v2/schemas/keyspaces`。在这个例子中，我们使用`demo_keyspace`了`name`，也没有`replicas`设置，默认为1。

```shell
curl -s --location --request POST 'http://api.easyolap.cn:8082/v2/schemas/keyspaces' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "name": "demo_keyspace"
}'
```
AUTH_TOKEN在令牌环节进行了设置。

结果：
```json
{"name":"demo_keyspace"}
```
### 检查命名空间是否存在

要检查键空间是否存在，请执行 REST API 查询`cURL`以查找所有键空间：
```shell
curl -s -L -X GET api.easyolap.cn:8082/v2/schemas/keyspaces \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json" \
-H "Accept: application/json"
```
结果：
```json
{"data":[{"name":"system_schema"},{"name":"system"},{"name":"system_auth"},{"name":"system_distributed"},{"name":"system_traces"},{"name":"stargate_system"},{"name":"data_endpoint_auth"},{"name":"easyolapdemo"},{"name":"users_keyspace"},{"name":"demo_keyspace"}]}
```

要获取特定命名空间，请在 URL 中指定命名空间：

命令
```shell
curl -s -L -X GET api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json" \
-H "Accept: application/json"
```
结果：
```
{"data":{"name":"demo_keyspace"}}
```

## 创建table

发送`POST`请求以`/v2/schemas/keyspaces/{keyspace_name}/tables`创建表。在 JSON 正文中设置表名和列定义。

```shell
curl -s --location \
--request POST api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace/tables \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--data '{
	"name": "users",
	"columnDefinitions":
	  [
        {
	      "name": "firstname",
	      "typeDefinition": "text"
	    },
        {
	      "name": "lastname",
	      "typeDefinition": "text"
	    },
        {
	      "name": "favorite_color",
	      "typeDefinition": "text"
	    }
	  ],
	"primaryKey":
	  {
	    "partitionKey": ["firstname"],
	    "clusteringKey": ["lastname"]
	  },
	"tableOptions":
	  {
	    "defaultTimeToLive": 0,
	    "clusteringExpression":
	      [{ "column": "lastname", "order": "ASC" }]
	  }
}'
```
结果：
```json
{"name":"users"}
```
有关分区键和集群键的信息可在[CQL 参考](https://cassandra.apache.org/doc/latest/cql/)中找到 。



#### 检查table和cloum是否存在

要检查表是否存在，请执行 REST API 查询`cURL`以查找所有表：

```shell
curl -s -L -X GET api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace/tables \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json" \
-H "Accept: application/json"
```
如果表存在,显示表的详细信息：
```
{"data":[{"name":"users","keyspace":"demo_keyspace","columnDefinitions":[{"name":"firstname","typeDefinition":"varchar","static":false},{"name":"lastname","typeDefinition":"varchar","static":false},{"name":"favorite_color","typeDefinition":"varchar","static":false}],"primaryKey":{"partitionKey":["firstname"],"clusteringKey":["lastname"]},"tableOptions":{"defaultTimeToLive":0,"clusteringExpression":[{"order":"ASC","column":"lastname"}]}}]}
```
如果表不存在：
```
{"description":"Resource not found: keyspace 'demos_keyspace' not found","code":404}
```
要获取特定表，请在 URL 中指定该表：

```
curl -s -L \
-X GET api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace/tables/users \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json" \
-H "Accept: application/json"
```

由于demo_keyspace下只有一个表所以结果上查看所有表结果相同：

```
{"data":{"name":"users","keyspace":"demo_keyspace","columnDefinitions":[{"name":"firstname","typeDefinition":"varchar","static":false},{"name":"lastname","typeDefinition":"varchar","static":false},{"name":"favorite_color","typeDefinition":"varchar","static":false}],"primaryKey":{"partitionKey":["firstname"],"clusteringKey":["lastname"]},"tableOptions":{"defaultTimeToLive":0,"clusteringExpression":[{"order":"ASC","column":"lastname"}]}}}
```

要检查列是否存在，请执行 REST API 查询`cURL`以查找所有列：
```
curl -s -L \
-X GET api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace/tables/users/columns \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Accept: application/json" \
-H "Content-Type: application/json"
```

结果：

```
{"data":[{"name":"firstname","typeDefinition":"varchar","static":false},{"name":"lastname","typeDefinition":"varchar","static":false},{"name":"favorite_color","typeDefinition":"varchar","static":false}]}
```

要获取特定列，请在 URL 中指定该列：
```
curl -s -L \
-X GET api.easyolap.cn:8082/v2/schemas/keyspaces/demo_keyspace/tables/users/columns/favorite_color \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json" \
-H "Accept: application/json"
```

结果：

```
{"data":{"name":"favorite_color","typeDefinition":"varchar","static":false}}
```
字段不存在
```
{"description":"column 'XXX' not found in table","code":404}
```


### 写入数据

首先，让我们向`users`您创建的表中添加一些数据。发送`POST`请求以`/v2/keyspaces/{keyspace_name}/{table_name}` 向表中添加数据。列名称/值对在 JSON 正文中传递。

```
curl -s --location --request POST 'api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "firstname": "li",
    "lastname": "zc",
    "favorite_color": "blue"
}'
curl -s --location --request POST 'api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "firstname": "zhang",
    "lastname": "da",
    "favorite_color": "grey"
}'

curl -s --location --request POST 'api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users' \
--header "X-Cassandra-Token: $AUTH_TOKEN" \
--header 'Content-Type: application/json' \
--data '{
    "firstname": "demo",
    "lastname": "one",
    "favorite_color": "grey"
},
{
    "firstname": "demo",
    "lastname": "two",
    "favorite_color": "grey"
}'
```
结果：

```
{"firstname":"li","lastname":"zc"}
{"firstname":"zhang","lastname":"da"}
...
```
### 读取数据
让我们检查数据是否已插入。发送GET请求以 /v2/keyspaces/{keyspace_name}/{table_name}?where={searchPath}检索输入的两个用户：
```
curl -s -L -X GET 'http://api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users?where=\{"firstname":\{"$in":\["li","demo"\]\}\}' \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json"
```
结果：
```
{"count":2,"data":[{"firstname":"demo","favorite_color":"grey","lastname":"one"},{"firstname":"li","favorite_color":"blue","lastname":"zc"}]}
```
此查询用于$in查找两个用户。该WHERE条款可以与其他有效的搜索条件中可以使用：$eq，$lt， $lte，$gt，$gte，$ne，和$exists（如果适用）。WHERE子句中可以使用表的主键，但非主键列不能使用，除非有索引。

一次加多条数据没起作用，第二条没有入库。



### 更新数据
数据发生变化，因此经常需要更新整行。要更新一行，请向 发送PUT请求/v2/keyspaces/{keyspace_name}/{table_name}/{path}。该{path}由主键值的。在这个例子中，分区键是firstname“Mookie”，聚类键是lastname“Betts”；因此，我们在我们的请求中使用/Mookie/Bettsas {path}。

```
curl -s -L -X PUT 'api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users/demo/one' \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H 'Content-Type: application/json' \
-d '{
    "favorite_color": "blue"
}'
```
RESULT:
```
{"data":{"favorite_color":"blue"}}
```

### 删除数据
要删除一行，请向 发送DELETE请求 /v2/keyspaces/{keyspace_name}/{table_name}/{primaryKey}。对于这个例子，主键由一个分区键firstname和集群列组成lastname，所以我们删除所有数据Mookie/Betts：
```
curl -s -L -X DELETE api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users/demo/one \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json"

curl -s -L -X GET 'http://api.easyolap.cn:8082/v2/keyspaces/demo_keyspace/users?where=\{"firstname":\{"$in":\["demo"\]\}\}' \
-H "X-Cassandra-Token: $AUTH_TOKEN" \
-H "Content-Type: application/json"
```
RESULT:
```
{"count":0,"data":[]}
```

瞧！有关 REST API 的更多信息，请参阅API 参考部分中的 [使用 REST API](https://stargate.io/docs/stargate/1.0/developers-guide/rest-using.html) 或[REST API](https://stargate.io/docs/stargate/1.0/attachments/restv2.html)。
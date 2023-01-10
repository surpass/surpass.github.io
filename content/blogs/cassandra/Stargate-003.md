---
title: "Stargate-GraphQL CQL API"
date: 2022-01-09T21:10:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate rest api"
tags: ["GraphQL api","Data Mesh","Stargate"]
keywords: ["GraphQL api","Data Mesh","Stargate"]
image: "/img/stargate.jpg"
link: "https://stargate.io/"
fact: "Stargate GraphQL api"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://stargate.io/docs/latest/quickstart/qs-graphql-cql-first.html

测试机信息：Centos 7 , ip:192.168.139.6  绑定域名：api.easyolap.cn

 本次使用上次实验的镜像。

Stargate简介系列：
[Stargate-简介及Document ApiI](../stargate-001) 

[Stargate-REST ApiI（本文）](../stargate-002) 
[Stargate-Stargate GraphQL CQL](../stargate-003) 

# Stargate GraphQL CQL-first API QuickStart


## **一、简介**
​		Stargate是部署在客户端应用程序和数据库之间的数据网关。在本快速入门中，您将使用GraphQL API插件在本地计算机上启动并运行，该插件公开了对存储在Cassandra表中的数据的CRUD访问。

![img](/images/blog/cassandra/stargate-001-004.png)



有关 GraphQL API, 见[博客 GraphQL API](https://stargate.io/2020/10/05/hello-graphql.html).

## [   ](https://stargate.io/docs/latest/quickstart/qs-graphql-cql-first.html#prerequisites)

## 前置条件

- 安装curl工具，用于在命令行运行 REST, Document, or GraphQL 查询 .

- *[可选 ]* 可以使用Postman 工具做为api的客户端
  
- *[可选 ]* 如果要使用GraphQL API，则需要[使用GraphSQL Playground]
  
- *[可选]* 对于REST和文档API，您可以使用 [Swagger UI](https://stargate.io/docs/latest/develop/tooling.html#swagger-resources).

- 安装 [Docker for Desktop](https://www.docker.com/products/docker-desktop)

- 拉取 aStargate Docker image

- Cassandra 4.0

- DSE 6.8

  
  
  ##  运行Stargate Docker 镜像
  
  #### V2

  使用 docker-compose 在 <install_location>/stargate/docker-compose 目录, 运行脚本.例如：
```
 ./start_cass_4_0_dev_mode.sh
```
 这个脚本将启动一下V1版本的coordinator 和API 镜像 .
    
  #### V1
  在开发者模式下启动Stargate容器。开发者模式不需要设置单独的Cassandra实例，只适用于开发和测试。
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
    stargateio/stargate-4_0:v1.0.57

```

  


## 使用 GraphQL Playground

开始使用GraphQL的最简单方法是使用内置的GraphQL Playground。在Stargate中，转到浏览器并启动Url`http://api.easyolap.cn:8080/playground`

添加你的 application token 到 HTTP HEADERS 中 在GraphQL Playground窗口的左下角：

```plaintext
{"x-cassandra-token":"$AUTH_TOKEN"}
```

一旦进入playground，您就可以创建新的schema并与GraphQLAPI交互。服务器路径的结构可用于创建和查询schema，以及查询和修改Cassandra数据：

- `/graphql-schema`
  
  - 用于探索和创建schema或数据定义语言（DDL）的API。例如，Stargate有创建、修改或删除表的查询，如“createTable”或“dropTable”。
- `/graphql/<keyspace>`
  
  - 用于使用GraphQL字段查询和修改表的API。通常，您将使用“/grapqlschema”启动playground 以创建schema。
  
    

## 创建Schema

为了使用GraphQLAPI，必须创建定义keyspace 和存储数据的表的schema 。keyspace 是一个容器，定义了数据库的“`replication factor”，决定存储的数据副本的数量。表由具有定义的数据类型的列组成。一个keyspace中包含多个表，但一个表不能包含在多个keyspace内。

### [创建 keyspace]



在开始使用GraphQLAPI之前，必须首先在数据库中创建Cassandra keyspace 和至少一个table。如果要连接到已存在schema的Cassandra数据库，可以跳过此步骤。

在GraphQL playground 中，导航到http://api.easyolap.cn:8080/graphql-schema ，并通过执行以下语名创建密钥空间：

```plaintext
# create a keyspace called library
mutation createKsLibrary {
  createKeyspace(name:"library", replicas: 1)
}
```

对于Cassandra schema中创建的每个keyspace，都会在`graphql-path`根目录下创建一个新路径（默认为：“/grapql'”）。例如，当Cassandra创建密钥空间时，刚刚执行的语句为“library”keyspace创建了一个路径`/graphql/library`。

将auth token 添加到左下角的HTTP Headers框中：

```plaintext
{
  "X-Cassandra-Token":"bff33799-4682-4375-99e8-23c4a9d0f304"
}
```

* 注意，此JSON令牌的密钥与generate令牌的值不同。它是“X-Cassandra-Token”，而不是“auth-Token”。*

运行语句以创建keyspace。该看到返回值：

```plaintext
{
  "data": {
    "createKeyspace": true
  }
}
```

### 检查 keyspace

检查keyspace是否存在,执行GraphQL query:

- graphQL command

```shell
# Works in graphql-schema
# for either CQL-first or schema-first
query GetKeyspace {
  keyspace(name: "library") {
      name
      dcs {
          name
          replicas
      }
      tables {
          name
          columns {
              name
              kind
              type {
                  basic
                  info {
                      name
                  }
              }
          }
      }
  }
}
  ```

Result

  ```
{
  "data": {
    "keyspace": {
      "name": "library",
      "dcs": [],
      "tables": [
        {
          "name": "book",
          "columns": [
            {
              "name": "title",
              "kind": "PARTITION",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "author",
              "kind": "CLUSTERING",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "format",
              "kind": "REGULAR",
              "type": {
                "basic": "SET",
                "info": {
                  "name": null
                }
              }
            },
            {
              "name": "genre",
              "kind": "REGULAR",
              "type": {
                "basic": "SET",
                "info": {
                  "name": null
                }
              }
            },
            {
              "name": "isbn",
              "kind": "REGULAR",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "language",
              "kind": "REGULAR",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "pub_year",
              "kind": "REGULAR",
              "type": {
                "basic": "INT",
                "info": null
              }
            }
          ]
        },
        {
          "name": "reader",
          "columns": [
            {
              "name": "name",
              "kind": "PARTITION",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "user_id",
              "kind": "CLUSTERING",
              "type": {
                "basic": "UUID",
                "info": null
              }
            },
            {
              "name": "addresses",
              "kind": "REGULAR",
              "type": {
                "basic": "LIST",
                "info": {
                  "name": null
                }
              }
            },
            {
              "name": "birthdate",
              "kind": "REGULAR",
              "type": {
                "basic": "DATE",
                "info": null
              }
            },
            {
              "name": "email",
              "kind": "REGULAR",
              "type": {
                "basic": "SET",
                "info": {
                  "name": null
                }
              }
            },
            {
              "name": "reviews",
              "kind": "REGULAR",
              "type": {
                "basic": "TUPLE",
                "info": {
                  "name": null
                }
              }
            }
          ]
        }
      }
    }
}
```





### [创建一个表]

keyspace存在后, 可以通过执行以下语句建表.例如, 两个表被创建:

- graphQL command

​```shell
# create two tables (book, reader) in library with a single mutation
# DATA TYPES: TEXT, UUID, SET(TEXT), TUPLE(TEXT, INT, DATE), LIST(UDT)
mutation createTables {
  book: createTable(
    keyspaceName:"library",
    tableName:"book",
    partitionKeys: [ # The keys required to access your data
      { name: "title", type: {basic: TEXT} }
    ]
    clusteringKeys: [
      { name: "author", type: {basic: TEXT} }
    ]
  )
  reader: createTable(
    keyspaceName:"library",
    tableName:"reader",
    partitionKeys: [
      { name: "name", type: {basic: TEXT} }
    ]
    clusteringKeys: [ # Secondary key used to access values within the partition
      { name: "user_id", type: {basic: UUID}, order: "ASC" }
  	]
    values: [
      { name: "birthdate", type: {basic: DATE} }
      { name: "email", type: {basic: SET, info:{ subTypes: [ { basic: TEXT } ] } } }
      { name: "reviews", type: {basic: TUPLE, info: { subTypes: [ { basic: TEXT }, { basic: INT }, { basic: DATE } ] } } }
      { name: "addresses", type: { basic: LIST, info: { subTypes: [ { basic: UDT, info: { name: "address_type", frozen: true } } ] } } }
    ]
  )
}
```

Result

```
  "data": {
    "book": true,
    "reader": true
  }
}
```



有关分区键和群集键的信息可以在[CQL reference](https://cassandra.apache.org/doc/latest/cql/).

第二个表“reader”中还使用了用户自定义列[user-defined type (UDT)](https://stargate.io/docs/latest/develop/api-graphql-cql-first/gql-creating-udt.html).

其中一个表包括创建数据类型为“LIST”的列，这是文本值的有序集合。

#### [集合(set, list, map) columns]

在表中包含集合有两个额外的部分：

- graphQL command

```shell
# create a table with a MAP
# DATA TYPE: TEXT, INT, MAP(TEXT, DATE)
# Sample: btype=Editor, badge_id=1, earned = [Gold:010120, Silver:020221]
mutation createMapTable {
  badge: createTable (
    keyspaceName:"library",
    tableName: "badge",
    partitionKeys: [
      {name: "btype", type: {basic:TEXT}}
    ]
    clusteringKeys: [
      { name: "badge_id", type: { basic: INT} }
    ],
    ifNotExists:true,
    values: [
      {name: "earned", type:{basic:LIST { basic:MAP, info:{ subTypes: [ { basic: TEXT }, {basic: DATE}]}}}}
    ]
  )
}
```

Result

```
{
  "data": {
    "badge": true
  }
}
```



此示例显示了一张地图。前面的示例显示了一个列表。在下一个示例中，将定义一个集合

This example shows a map. A previous example shows a list. In the next example, a set will be defined.

### [添加列到表 schema]

如果需要向存储在表中的内容添加更多属性，可以添加一个或多个列：

- graphQL command
- 

```shell
# alter a table and add columns
# DATA TYPES: TEXT, INT, SET(TEXT)
mutation alterTableAddCols {
  alterTableAdd(
    keyspaceName:"library",
    tableName:"book",
    toAdd:[
      { name: "isbn", type: { basic: TEXT } }
      { name: "language", type: {basic: TEXT} }
      { name: "pub_year", type: {basic: INT} }
      { name: "genre", type: {basic:SET, info:{ subTypes: [ { basic: TEXT } ] } } }
      { name: "format", type: {basic:SET, info:{ subTypes: [ { basic: TEXT } ] } } }
    ]
  )
}
```

Result

```
{
  "data": {
    "alterTableAdd": true
  }
}
```



### [检查表和列是否存在]

要检查表或特定表列是否存在，请执行GraphQL查询：

- graphQL command

```shell
query GetTables {
  keyspace(name: "library") {
      name
      tables {
          name
          columns {
              name
              kind
              type {
                  basic
                  info {
                      name
                  }
              }
          }
      }
  }
}
```

Result

```
{
  "data": {
    "keyspace": {
      "name": "library",
      "tables": [
        {
          "name": "reader",
          "columns": [
            {
              "name": "name",
              "kind": "PARTITION",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
          ]
        },
        {
          "name": "book",
          "columns": [
            {
              "name": "title",
              "kind": "PARTITION",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "author",
              "kind": "REGULAR",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            },
            {
              "name": "isbn",
              "kind": "REGULAR",
              "type": {
                "basic": "VARCHAR",
                "info": null
              }
            }
          ]
        }
      ]
    }
  }
}
```

由于这些是命名查询，GraphQL playground 将允许您选择要运行的查询。

第一个查询将返回有关keyspace “`library` ”及其内的表的信息。

第二个查询将只返回有关该keyspace 中的表的相关信息。 

## [表交互] 

### [API 生成]

创建了schema，GraphQL API 就会生成语句并可以使用查询。在GraphQL playground中，展开右侧标签为“DOCS”或“SCHEMA”的选项卡，即可发现可用项和要使用的语法。



对于我们刚刚创建的Cassandraschema中的每个表，都会创建几个GraphQL字段来处理queries 和mutations。

例如，为“books”表生成的GraphQL API是：

```plaintext
schema {
  query: Query
  mutation: Mutation
}

type Query {
  book(value: bookInput, filter: bookFilterInput, orderBy: [bookOrder], options: QueryOptions): bookResult
  bookFilter(filter: bookFilterInput!, orderBy: [bookOrder], options: QueryOptions): bookResult
}

type Mutation {
  insertbook(value: bookInput!, ifNotExists: Boolean, options: UpdateOptions): bookMutationResult
  updatebook(value: bookInput!, ifExists: Boolean, ifCondition: bookFilterInput, options: UpdateOptions): bookMutationResult
  deletebook(value: bookInput!, ifExists: Boolean, ifCondition: bookFilterInput, options: UpdateOptions): bookMutationResult
}
```

查询“books（）”可以查询相等书。如果未提供值参数，则返回前一百个（默认页面大小）值。



创建了几个可以用于插入、更新或删除书籍的mutations 。关于这些mutations 的一些重要事实是

- `insertBooks()` 如果存在具有相同信息的书籍，则updateBooks（）`是一个**upstart**操作，除非“ifNotExists”设置为true。

- `updateBooks()` `也是一个**upsert**操作，如果它不存在，将创建一本新书，除非“ifNotExists”设置为true。

- 由于Cassandra中的比较和设置执行路径，使用“ifNotExists”或“ifCondition”选项会影响操作的性能。在幕后，这些操作正在使用Cassandra中的一个叫做轻量级事务（LWT）的功能。

  

随着keyspace中添加了更多的表，额外的GraphQL字段将添加可用于与表数据交互的查询和mutation类型。

### [插入数据]

任何创建的API都可以用于与GraphQL数据交互、写入或读取数据。

首先，让我们导航到playground的keyspace “`library` ”。将位置更改为http://api.easyolap.cn:8080/graphql/library并在“book”表中添加几本书： 

- graphQL command

```shell
# insert 2 books in one mutation
mutation insert2Books {
  moby: insertbook(value: {title:"Moby Dick", author:"Herman Melville"}) {
    value {
      title
    }
  }
  catch22: insertbook(value: {title:"Catch-22", author:"Joseph Heller"}) {
    value {
      title
    }
  }
}
```

Result

```
{
  "data": {
    "moby": {
      "value": {
        "title": "Moby Dick"
      }
    },
    "catch22": {
      "value": {
        "title": "Catch-22"
      }
    }
  }
}
```

注意，关键字值在mutation中使用了两次。

第一次使用定义了记录设置的值，例如，标题为Moby Dick，作者为 Herman Melville。

第二种用法定义了mutation成功后将显示的值，以便验证正确的插入。

此方法同样适用于更新和读取查询。

### [检索数据]

让我们检查数据是否已插入。

现在，让我们使用“WHERE”子句搜索指定记录。

表的主键可以在“WHERE”子句中使用，但非主键列只能在索引后使用。

以下查询，查看位置http://api.easyolap.cn:8080/graphql/library

将获得指定书籍“WHERE title:“Moby Dick””的“title”和“author”：

- graphQL command

```shell
# get one book using the primary key title with a value
query oneBook {
    book (value: {title:"Moby Dick"}) {
      values {
      	title
      	author
      }
    }
}
```

Result

```
{
  "data": {
    "books": {
      "values": [
        {
          "title": "Moby Dick",
          "author": "Herman Melville"
        }
      ]
    }
  }
}
```



### [Update data]

使用前面添加的列，书籍的数据将更新为ISBN值：

- graphQL command

```shell
mutation updateOneBook {
  moby: updatebook(value: {title:"Moby Dick", author:"Herman Melville", isbn: "9780140861723"}, ifExists: true ) {
    value {
      title
      author
      isbn
    }
  }
}
```

Result
```
{
  "data": {
    "moby": {
      "value": {
        "title": "Moby Dick",
        "author": "Herman Melville",
        "isbn": "9780140861723"
      }
    }
  }
}
```

更新是升级。如果该行不存在，将创建它。如果它确实存在，将使用新行数据更新它。

### [Delete data]

在insertBook（）添加带有”Pride and Prejudice“的书后，您可以使用“deleteBook（）”删除该书，以说明删除数据：

- graphQL command

```shell
mutation deleteOneBook {
  PaP: deletebook(value: {title:"Pride and Prejudice", author: "Jane Austen"}, ifExists: true ) {
    value {
      title
    }
  }
}
```

Result

```
{
  "data": {
    "PaP": {
      "value": {
        "title": "Pride and Prejudice"
      }
    }
  }
}
```

请注意，在删除图书之前，使用“ifExists”验证图书是否存在。

 有关GraphQL API（CQL-first）的更多信息，请参阅 [Using the GraphQL API (CQL-first)](https://stargate.io/docs/latest/develop/dev-with-graphql-cql-first.html) 在“使用Stargate API开发”部分中。


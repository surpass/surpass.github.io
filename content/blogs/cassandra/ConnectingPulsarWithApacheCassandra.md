---
title: "Connecting Pulsar With Apache Cassandra"
date: 2022-02-22T22:30:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate rest api"
tags: ["Apache Cassandra","Apache Pulsar","Tutorial", "连接器", "sink"]
keywords: ["Apache Cassandra","Apache Pulsar","Tutorial", "连接器", "sink"]
image: "https://pulsar.apache.org/img/pulsar.svg"
link: "https://pulsar.apache.org"
fact: "Connecting Pulsar With Apache Cassandra"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/cassandra/connectingpulsarwithapachecassandra/

测试机信息：Centos 8 , ip:192.168.139.8  绑定域名：api.easyolap.cn

 

本教程提供了一个亲身体验，了解如何在不编写一行代码的情况下将数据移出Pulsar。回顾Pulsar I/O的概念，同时运行本指南中的步骤，有助于加深理解。本教程结束时，您将能够：

        连接你的Pulsar和Cassandra

提示

1.这些说明假设您在独立模式下运行Pulsar。然而，本教程中使用的所有命令应该能够在多节点脉冲星群中使用，而无需任何更改。

2.假设所有指令都在Pulsar二进制发部的根目录下运行。

软件版本：

| Name                 | Version |
| -------------------- | ------- |
| `Apache Pulsar`      | `2.9.1` |
| Apache Cassandra | `4.0.1` |




# 安装Pulsar

## **一、简介**

要开始运行Pulsar，请通过以下方式之一下载二进制tarball版本：

- 通过单击下面的链接并从Apache镜像下载版本：

  - [Pulsar 2.9.1 binary release](https://archive.apache.org/dist/pulsar/pulsar-2.9.1/apache-pulsar-2.9.1-bin.tar.gz)

- 从 Pulsar [下载页面](https://pulsar.apache.org/download)

- 从 Pulsar [releases page](https://github.com/apache/pulsar/releases/latest)

- 使用 [wget](https://www.gnu.org/software/wget):

  ```shell
  $ wget https://archive.apache.org/dist/pulsar/pulsar-2.9.1/apache-pulsar-2.9.1-bin.tar.gz
  ```

下载tar包后，将其解压后，并将“cd”进入生成的目录：

```bash
$ tar xvfz apache-pulsar-2.9.1-bin.tar.gz
$ cd apache-pulsar-2.9.1
```

测试pulsar：
用pulsar命令行测试收发消息。

启动consume:

```bash
bin/pulsar-client consume persistent://public/default/test_cassandra_datastax -s test

```
生产消息：

```bash
bin/pulsar-client produce  -k "3" -m "{\"id\": 1,\"name\": \"doit\",\"value\": 1,\"tx_time\": 1642817730000}" persistent://public/default/example_topic -s $
```
-s 定义消息的分隔符。




## 二、安装内置连接器



​       自2.3.0版以后，Pulsar将所有内置连接器作为单独的归档文件发布。如果您想启用这些内置连接器，可以从Pulsar[下载页面](https://pulsar.apache.org/download)下载连接器“NAR”档案。



下载所需的内置连接器后，这些档案应该放在连接器目录下，在那里你已经解包了Pulsar发行版。

```
$ tar xvfz /opt/demo/apache-pulsar-2.9.1-bin.tar.gz
$ cd apache-pulsar-2.9.1
$ mkdir connectors
$ cp -r /opt/downloaded/connectors/*.nar ./connectors

$ ls connectors 
pulsar-io-cassandra-2.9.1.nar 
...
```
为简单启见，只保留一个connector。
	

## 三、启动Pulsar服务

```bash
bin/pulsar standalone
```

  All the components of a Pulsar service will start in order. You can curl those pulsar service endpoints to make sure Pulsar service is up running correctly.

Pulsar所有服务排顺序启动。你可以用curl 验证Pulsar服务，以确保Pulser服务运行正常

1. 验证pulsar二进制协议端口。

```bash
netstat -nap |grep 6650
```

Example output:
```bash
tcp        0      0 0.0.0.0:6650            0.0.0.0:*               LISTEN      15100/java          
tcp        0      0 127.0.0.1:6650          127.0.0.1:56328         ESTABLISHED 15100/java          
tcp        0      0 127.0.0.1:6650          127.0.0.1:47554         ESTABLISHED 15100/java 
...

```


2. 验证pulsar集群信息

```bash
curl -s http://localhost:8080/admin/v2/worker/cluster
```
Example output:
```bash
 [{"workerId":"c-standalone-fw-localhost-8080","workerHostname":"localhost","port":8080}]
```



3. 确认默认的租户(publiic)和命名空间（default）已经存

```bash
curl -s http://localhost:8080/admin/v2/worker/cluster
```

Example output:

```bash
 ["public/default","public/functions"]
```

4. 所有内置连接器为可用状态

```bash
curl -s http://localhost:8080/admin/v2/functions/connectors
```

Example output:

```bash
[{"name":"cassandra","description":"Writes data into Cassandra","sinkClass":"org.apache.pulsar.io.cassandra.CassandraStringSink","sinkConfigClass":"org.apache.pulsar.io.cassandra.CassandraSinkConfig"}]
```

## 三、将Pulsar连接到Apache Cassandra

##### 1. 安装和启动Cassandra集群

   下载
```
wget https://dlcdn.apache.org/cassandra/4.0.1/apache-cassandra-4.0.1-bin.tar.gz

```
启动cassandra服务
```bash
bin/cassandra
```

##### 2. 验证cassandra cql协议9042端口。

```bash
netstat -nap |grep 9042
```

Example output:
```bash
tcp        0      0 127.0.0.1:9042          0.0.0.0:*               LISTEN      24183/java 
...

```
##### 3. 检查cassandra集群状态。

```bash
bin/nodetool status
```

Example output:
```bash
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address    Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  127.0.0.1  130.58 KiB  16      100.0%            8560b4f3-49ae-4825-9ce2-c589d3b3a431  rack1

```

##### 4. cqlsh连接验证

```bash
./cqlsh localhost
```
Example output:
```bash
Connected to Test Cluster at localhost:9042
[cqlsh 6.0.0 | Cassandra 4.0.1 | CQL spec 3.4.5 | Native protocol v5]
Use HELP for help.
cqlsh>
```
已成功进入到cqlsh命令行模式下。





##### 5.创建keyspace `pulsar_test_keyspace`

```bash
cqlsh> CREATE KEYSPACE pulsar_test_keyspace WITH replication = {'class':'SimpleStrategy', 'replication_factor':1};
```

#### 6.创建table `pulsar_test_table`

```bash
cqlsh> USE pulsar_test_keyspace;
cqlsh:pulsar_test_keyspace> CREATE TABLE pulsar_test_table (key text PRIMARY KEY, col text);
```

 ## 四、配置Cassandra Sink
 现在我们有了一个在本地运行的Csassandra集群和Pulsar集群。接下来，我们将配置Cassandra Sink。Cassandra Sink将从Pulsar topic读取消息，并将消息写入Cassandra table。

为了运行Cassandra Sink，您需要准备一个yaml配置文件，包括Pulsar IO运行时需要的配置信息。例如，Pulsar IO如何连接cassandra集群，Pulsar IO将使用什么keyspace和table向其写入Pulsar信息。


#### 1.创建cassandra sink配置`
创建一个文件examples/cassandra-sink.yml并对其进行编辑，以填写以下内容：

```
configs:
    roots: "localhost:9042"
    keyspace: "pulsar_test_keyspace"
    columnFamily: "pulsar_test_table"
    keyname: "key"
    columnName: "col"
```
roots:配置cassandra cluster的连接地址
keyspace：为keyspace名字，参见步骤三中的5；
columnFamily：为table名字，参见步骤三中的6；
keyname:为主建名，参见步骤三中的6；
columnName：为列名，参见步骤三中的6；

#### 2.提交cassandra sink
Pulsar提供用于运行和管理Pulsar I/O连接器的CLI。

我们可以运行以下命令,根据 examples/cassandra-sink.yml文件，创建一个sink-type为cassandra的sink.
```
bin/pulsar-admin sink create \
    --tenant public \
    --namespace default \
    --name cassandra-test-sink \
    --sink-type cassandra \
    --sink-config-file examples/cassandra-sink.yml \
    --inputs test_cassandra
```
Example output:
```bash
"Created successfully"
```

检索Sink信息

```
bin/pulsar-admin sink get \
    --tenant public \
    --namespace default \
    --name cassandra-test-sink
```
Example output:
```bash
{
  "tenant": "public",
  "namespace": "default",
  "name": "cassandra-test-sink",
  "className": "org.apache.pulsar.io.cassandra.CassandraStringSink",
  "sourceSubscriptionPosition": "Latest",
  "inputs": [
    "test_cassandra"
  ],
  "inputSpecs": {
    "test_cassandra": {
      "isRegexPattern": false,
      "schemaProperties": {},
      "consumerProperties": {},
      "poolMessages": false
    }
  },
  "configs": {
    "keyspace": "pulsar_test_keyspace",
    "columnFamily": "pulsar_test_table",
    "keyname": "key",
    "roots": "localhost:9042",
    "columnName": "col"
  },
  "parallelism": 1,
  "processingGuarantees": "ATLEAST_ONCE",
  "retainOrdering": false,
  "autoAck": true,
  "archive": "builtin://cassandra"
}
```

验证Sink运行状态

```
bin/pulsar-admin sink status \
    --tenant public \
    --namespace default \
    --name cassandra-test-sink
```
Example output:
```bash
{
  "numInstances" : 1,
  "numRunning" : 1,
  "instances" : [ {
    "instanceId" : 0,
    "status" : {
      "running" : true,
      "error" : "",
      "numRestarts" : 0,
      "numReadFromPulsar" : 0,
      "numSystemExceptions" : 0,
      "latestSystemExceptions" : [ ],
      "numSinkExceptions" : 0,
      "latestSinkExceptions" : [ ],
      "numWrittenToSink" : 0,
      "lastReceivedTime" : 0,
      "workerId" : "c-standalone-fw-localhost-8080"
    }
  } ]
}

```

#### 3.测试cassandra sink

现在，让我们为Cassandra sink主题（test_Cassandra）生成一些消息。

```
for i in {0..9}; do bin/pulsar-client produce -m "key-$i" -n 1 test_cassandra; done
```
Example output:
```bash
2022-02-22T20:25:11,471+0800 [pulsar-client-io-1-1] INFO  org.apache.pulsar.client.impl.ConnectionPool - [[id: 0xd0b316c2, L:/127.0.0.1:45602 - R:localhost/127.0.0.1:6650]] Connected to server
...
2022-02-22T20:25:53,096+0800 [main] INFO  com.scurrilous.circe.checksum.Crc32cIntChecksum - SSE4.2 CRC32C provider initialized
2022-02-22T20:25:53,133+0800 [main] INFO  org.apache.pulsar.client.impl.PulsarClientImpl - Client closing. URL: pulsar://localhost:6650/
2022-02-22T20:25:53,145+0800 [pulsar-client-io-1-1] INFO  org.apache.pulsar.client.impl.ProducerImpl - [test_cassandra] [standalone-0-9] Closed Producer
2022-02-22T20:25:53,155+0800 [pulsar-client-io-1-1] INFO  org.apache.pulsar.client.impl.ClientCnx - [id: 0x88dcd6c8, L:/127.0.0.1:46072 ! R:localhost/127.0.0.1:6650] Disconnected
2022-02-22T20:25:55,214+0800 [main] INFO  org.apache.pulsar.client.cli.PulsarClientTool - 1 messages successfully produced

```

再次运行Sink运行状态查看命令，你会看到Cassandra sink已处理了10条消息。
```
bin/pulsar-admin sink status \
    --tenant public \
    --namespace default \
    --name cassandra-test-sink
```
Example output:
```
{
  "numInstances" : 1,
  "numRunning" : 1,
  "instances" : [ {
    "instanceId" : 0,
    "status" : {
      "running" : true,
      "error" : "",
      "numRestarts" : 0,
      "numReadFromPulsar" : 10,
      "numSystemExceptions" : 0,
      "latestSystemExceptions" : [ ],
      "numSinkExceptions" : 0,
      "latestSinkExceptions" : [ ],
      "numWrittenToSink" : 10,
      "lastReceivedTime" : 1645532753130,
      "workerId" : "c-standalone-fw-localhost-8080"
    }
  } ]
}

```
最后，通过cassandra cqlsh命令查看Cassandra中的结果
```bash
cqlsh> use pulsar_test_keyspace;
cqlsh:pulsar_test_keyspace> select * from pulsar_test_table;
```
Example output:
```
 key   | col
-------+-------
 key-5 | key-5
 key-0 | key-0
 key-9 | key-9
 key-2 | key-2
 key-1 | key-1
 key-3 | key-3
 key-6 | key-6
 key-7 | key-7
 key-4 | key-4
 key-8 | key-8

(10 rows)


#### 3.删除Cassandra Sink
```bash
bin/pulsar-admin sink delete \
    --tenant public \
    --namespace default \
    --name cassandra-test-sink
```
Example output:
```
"Deleted successfully"
```

以上是streamnative的那个pulsar-cassandra实例测试，比较弱，通过查看源码发列只能当示例用，无法做为生产或复杂的功能使用。DataStax开源的增强版的Cassandra连接器完全支持Pulsar Schema，比如Json，Avro。而且Pulsar Schema到CassandraSchema的映射是通过连接器的配置文件来实现的，比较灵活。

以下是DataStax的开源的pulsar-cassandra的测试，https://docs.datastax.com/en/pulsar-connector/1.4/index.html

## 五、测试DataStax开源的pulsar-cassandra连接器
本示例参照https://mp.weixin.qq.com/s/7Lz4WV45i2vNI6SeYArCow 

#### 1.下载及安装：
先删除上面示例的 pulsar-io-cassandra-2.9.1.nar 连接器。

```bash
$ wget https://github.com/datastax/pulsar-sink/releases/download/1.4.1/cassandra-enhanced-pulsar-sink-1.4.1-nar.nar
$ rm pulsar-io-cassandra-2.9.1.nar 
$ mv cassandra-enhanced-pulsar-sink-1.4.1-nar.nar connectors

```
重启pulsar cluster.



#### 2.简单将消息格式定义如下：
```bash
{
  "id": 1,
  "name": "doit",
  "value": 1,
  "tx_time": "2022-02-22 22:10:30.00000"
}
```


##### 3.创建keyspace `testks` 和pulsar_qs

```bash
cqlsh> CREATE KEYSPACE testks WITH replication = {'class':'SimpleStrategy', 'replication_factor':1};

cqlsh> CREATE KEYSPACE IF NOT EXISTS pulsar_qs
WITH replication = {
  'class' : 'SimpleStrategy',
  'replication_factor' : 1
};
```

#### 4.创建table `transaction`（存解析后的数据）和`pulsar_msg_his`(存原史消息) ，pulsar_kv（在另一个keyspace下的表）

```bash
cqlsh> USE testks;
cqlsh:testks> CREATE TABLE transaction (id bigint  PRIMARY KEY, name text,value bigint ,tx_time timestamp );

cqlsh:testks> CREATE TABLE pulsar_msg_his (key text PRIMARY KEY, datatx text);


cqlsh>  CREATE TABLE pulsar_qs.pulsar_kv (
	key text PRIMARY KEY,
	content text
);
```

#### 5.创建cassandra sink配置`
创建一个文件examples/cassandra-sink-datastax.yml并对其进行编辑，以填写以下内容：

```
configs:
  verbose: true
  batchSize: 3000
  batchFlushTimeoutMs: 1000
  topics: example_topic
  contactPoints: localhost
  loadBalancing.localDc: datacenter1
  port: 9042
  cloud.secureConnectBundle:
  ignoreErrors: None
  maxConcurrentRequests: 500
  maxNumberOfRecordsInBatch: 32
  queryExecutionTimeout: 30
  connectionPoolLocalSize: 4
  jmx: true
  compression: None
  auth:
    provider: None
    username:
    password:
    gssapi:
      keyTab:
      principal:
      service: dse
  ssl:
    provider: None
    hostnameValidation: true
    keystore:
      password:
      path:
    openssl:
      keyCertChain:
      privateKey:
    truststore:
      password:
      path:
    cipherSuites:
  topic:
    example_topic:
      testks:
        pulsar_msg_his:
          mapping: 'key=key,datatx=value'
          consistencyLevel: LOCAL_ONE
          ttl: -1
          ttlTimeUnit : SECONDS
          timestampTimeUnit : MICROSECONDS
          nullToUnset: true
          deletesEnabled: true
        transaction:
          mapping: 'id=value.id,name=value.name,value=value.value,tx_time=value.tx_time'
          consistencyLevel: LOCAL_ONE
          ttl: -1
          ttlTimeUnit : SECONDS
          timestampTimeUnit : MICROSECONDS
          nullToUnset: true
          deletesEnabled: true
      pulsar_qs:
        pulsar_kv:
          mapping: 'key=key,content=value'
          consistencyLevel: LOCAL_ONE
          ttl: -1
          ttlTimeUnit : SECONDS
          timestampTimeUnit : MICROSECONDS
          nullToUnset: true
          deletesEnabled: true
      codec:
        locale: en_US
        timeZone: UTC
        timestamp: CQL_TIMESTAMP
        date: ISO_LOCAL_DATE
        time: ISO_LOCAL_TIME
        unit: MILLISECONDS

```
相关配置项说明参见：https://docs.datastax.com/en/pulsar-connector/1.4/index.html

#### 6.提交cassandra sink

我们可以运行以下命令,根据 examples/cassandra-sink-datastax.yml文件，创建一个sink-type为cassandra的sink.
```
bin/pulsar-admin sinks create \
	--name  dse-sink-kv \
	--classname com.datastax.oss.sink.pulsar.StringCassandraSinkTask \
	--sink-config-file examples/cassandra-sink-datastax.yml \
	--sink-type cassandra-enhanced \
	--tenant public \
	--namespace default \
	--inputs "persistent://public/default/example_topic"

 
```
Example output:
```bash
"Created successfully"
```

#### 7.检索Sink信息

```
bin/pulsar-admin sink get \
    --tenant public \
    --namespace default \
    --name dse-sink-kv
```
Example output:
```bash
{
  "tenant": "public",
  "namespace": "default",
  "name": "dse-sink-kv",
  "className": "com.datastax.oss.sink.pulsar.StringCassandraSinkTask",
  "sourceSubscriptionPosition": "Latest",
  "inputs": [
    "persistent://public/default/example_topic"
  ],
  "inputSpecs": {
    "persistent://public/default/example_topic": {
      "isRegexPattern": false,
      "schemaProperties": {},
      "consumerProperties": {},
      "poolMessages": false
    }
  },
  "configs": {
    "loadBalancing.localDc": "datacenter1",
    "queryExecutionTimeout": 30,
    "auth": {
      "provider": "None",
      "gssapi": {
        "service": "dse"
      }
    },
    "topics": "example_topic",
    "contactPoints": "localhost",
    "batchFlushTimeoutMs": 1000,
    "maxConcurrentRequests": 500,
    "ignoreErrors": "None",
    "ssl": {
      "provider": "None",
      "hostnameValidation": true,
      "keystore": {},
      "openssl": {},
      "truststore": {}
    },
    "verbose": true,
    "connectionPoolLocalSize": 4,
    "jmx": true,
    "port": 9042,
    "maxNumberOfRecordsInBatch": 32,
    "topic": {
      "example_topic": {
        "testks": {
          "pulsar_msg_his": {
            "mapping": "key\u003dkey,datatx\u003dvalue",
            "consistencyLevel": "LOCAL_ONE",
            "ttl": -1,
            "ttlTimeUnit": "SECONDS",
            "timestampTimeUnit": "MICROSECONDS",
            "nullToUnset": true,
            "deletesEnabled": true
          },
          "transaction": {
            "mapping": "id\u003dvalue.id,name\u003dvalue.name,value\u003dvalue.value,tx_time\u003dvalue.tx_time",
            "consistencyLevel": "LOCAL_ONE",
            "ttl": -1,
            "ttlTimeUnit": "SECONDS",
            "timestampTimeUnit": "MICROSECONDS",
            "nullToUnset": true,
            "deletesEnabled": true
          }
        },
        "pulsar_qs": {
          "pulsar_kv": {
            "mapping": "key\u003dkey,content\u003dvalue",
            "consistencyLevel": "LOCAL_ONE",
            "ttl": -1,
            "ttlTimeUnit": "SECONDS",
            "timestampTimeUnit": "MICROSECONDS",
            "nullToUnset": true,
            "deletesEnabled": true
          }
        },
        "codec": {
          "locale": "en_US",
          "timeZone": "UTC",
          "timestamp": "CQL_TIMESTAMP",
          "date": "ISO_LOCAL_DATE",
          "time": "ISO_LOCAL_TIME",
          "unit": "MILLISECONDS"
        }
      }
    },
    "batchSize": 3000,
    "compression": "None"
  },
  "parallelism": 1,
  "processingGuarantees": "ATLEAST_ONCE",
  "retainOrdering": false,
  "autoAck": true,
  "archive": "builtin://cassandra-enhanced"
}


```

#### 8.验证Sink运行状态

```
bin/pulsar-admin sink status \
    --tenant public \
    --namespace default \
    --name dse-sink-kv
```
Example output:
```bash
{
  "numInstances" : 1,
  "numRunning" : 1,
  "instances" : [ {
    "instanceId" : 0,
    "status" : {
      "running" : true,
      "error" : "",
      "numRestarts" : 0,
      "numReadFromPulsar" : 0,
      "numSystemExceptions" : 0,
      "latestSystemExceptions" : [ ],
      "numSinkExceptions" : 0,
      "latestSinkExceptions" : [ ],
      "numWrittenToSink" : 0,
      "lastReceivedTime" : 0,
      "workerId" : "c-standalone-fw-localhost-8080"
    }
  } ]
}

```
#### 9.手动生产 pulsar 消息
```
bin/pulsar-client produce  -k "1" -m "{\"id\": 1,\"name\": \"doit\",\"value\": 6,\"tx_time\": \"2022-02-22 22:10:30.684\"}"  persistent://public/default/example_topic -s $
```
查看日志：
```
tail -f plusar/apache-pulsar-2.9.1/logs/functions/public/default/dse-sink-kv/dse-sink-kv-0.log 

```
如果日志没有异常，查看cassandra表中数据：
```
cqlsh:testks> select * from transaction ;

 id | name | tx_time                         | value
----+------+---------------------------------+-------
  1 | doit | 2022-02-22 22:10:30.684000+0000 |     6
```

#### 10.批量生产 pulsar 消息
以下代码来自https://mp.weixin.qq.com/s/7Lz4WV45i2vNI6SeYArCow

通过go程序向pulsar topic 发送消息。(go运行时环境略)
```
package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "time"

    "github.com/apache/pulsar-client-go/pulsar"
)

var (
    topic string
    count int
)

func init() {
    const (
        defaultTopic = "default"
        usage        = "the topic of pulsar"
    )
    flag.StringVar(&topic, "topic", defaultTopic, usage)
    flag.IntVar(&count, "count", 10, "how many messages to send")
}

func main() {
    flag.Parse()
    client, err := pulsar.NewClient(pulsar.ClientOptions{
        URL:               "pulsar://localhost:6650",
        OperationTimeout:  30 * time.Second,
        ConnectionTimeout: 30 * time.Second,
    })
    if err != nil {
        log.Fatalf("Could not instantiate Pulsar client: %v", err)
    }
    defer client.Close()

    produceBatchMessagesWithCount(client, topic, count)
    
    if err != nil {
        fmt.Println("Failed to publish message", err)
    }
    fmt.Println("Published message")
}

func produceBatchMessagesWithCount(client pulsar.Client, topic string, count int) error {
    log.Printf("Topic : %s, Count to send: %d\n", topic, count)
    producer, err := client.CreateProducer(pulsar.ProducerOptions{
        Topic: topic,
    })
    if err != nil {
        return err
    }
    defer producer.Close()

    for i := 1; i <= count; i++ {
        m := fmt.Sprintf(`{"id":%d, "name":"testn_%d","value": %d, "tx_time": "2022-02-22 22:10:30.%d"}`, i, i, i, i)
        producer.SendAsync(context.Background(), &pulsar.ProducerMessage{
            Payload: []byte(m),
        }, func(id pulsar.MessageID, producerMessage *pulsar.ProducerMessage, e error) {
            if e != nil {
                log.Printf("Failed to publish, error %v\n", e)
            } else {
                // log.Printf("Published message %v\n", id)
            }
        })
    }
    
    log.Printf("Produce %d messages DONE\n", count)
    
    if err = producer.Flush(); err != nil {
        log.Printf("Failed to Flush, error %v\n", err)
        return err
    }
    
    return nil
}
```

保存文件到 producer-cassandra-sink.go，运行以下命令，发送一百万消息到 public/default/example_topic 这个 topic。
```
go run producer-cassandra-sink.go -topic public/default/example_topic -count 100000
```
#### 11.cqlsh 查看消息数量

```
cqlsh:testks> select count(*) from transaction;

 count
---------
 100000

(1 rows)
```

#### 12.删除Cassandra Sink
```bash
bin/pulsar-admin sink delete \
    --tenant public \
    --namespace default \
    --name dse-sink-kv
```
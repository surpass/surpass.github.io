---
title: "搭建单节点Confluent Kafka的本地测试环境"
date: 2023-01-09T20:00:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "搭建单节点Confluent Kafka的本地测试环境"
tags: ["kafka","mq","企业","bigdata"]
keywords: ["kafka","mq","企业","bigdata"]
image: "/img/kafka.png"
link: "https://www.confluent.io"
fact: "Confluent Kafka学习笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/confluent-kafka

# 搭建单节点Confluent Kafka的本地测试环境

## 一、confluent简介

Confluent是由LinkedIn开发出Apache Kafka的团队成员，基于此技术另立山头，创建了新公司confluent。confluent对Kafka进行了更友好的封装，做成了一个平台化的工具，类似于CDH对Hadoop。其基本架构如下：

![img](/img/kafka/001.png)

- 官方网站

  https://www.confluent.io/

- 下载地址

  https://www.confluent.io/download

- 最新版文档

  https://docs.confluent.io/current/

## 二、Confluent的组件

- Confluent Platform 包括更多的工具和服务，使构建和管理数据流平台更加容易。
- Confluent Control Center（闭源）。管理和监控Kafka最全面的GUI驱动系统。
- Confluent Kafka Connectors（开源）。连接SQL数据库/Hadoop/Hive
- Confluent Kafka Clients（开源）。对于其他编程语言，包括C/C++,Python
- Confluent Kafka REST Proxy（开源）。允许一些系统通过HTTP和kafka之间发送和接收消息。
- Confluent Schema Registry（开源）。帮助确定每一个应用使用正确的schema当写数据或者读数据到kafka中。

## 三、快速安装体验

confluent的安装包括物理机、docker等安装方式，这里我选择的是本地快速安装测试。而且，我选择的版本也不是最新版本的confluent。如果你想体验最新版本的confluent，请移步至官网下载。由于商业版本收费，我体验的版本是社区版。

**我的环境**

- centos 7.6
- Jdk1.8
- confluent-7.3.0



**配置zookeepe**r

```
vim etc/kafka/zookeeper.properties

# 配置文件的内容如下
# 我本地存放kafka的数据目录
dataDir=/data/confluent-7.3.0/data/zookeeper
clientPort=2181
maxClientCnxns=0
```

**配置kafka的broker**

```
vim etc/kafka/server.properties

# 配置文件的内容如下
# The id of the broker. This must be set to a unique integer for each broker.
broker.id=50
# Switch to enable topic deletion or not, default value is false
delete.topic.enable=true
listeners=PLAINTEXT://kafka.easyolap.cn:9092
num.network.threads=3
# The number of threads that the server uses for processing requests, which may include disk I/O
num.io.threads=8
# The send buffer (SO_SNDBUF) used by the socket server
socket.send.buffer.bytes=102400
# The receive buffer (SO_RCVBUF) used by the socket server
socket.receive.buffer.bytes=102400
# The maximum size of a request that the socket server will accept (protection against OOM)
socket.request.max.bytes=104857600
# A comma seperated list of directories under which to store log files
log.dirs=/data/confluent-7.3.0/logs/kafka
# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=1
# The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
# This value is recommended to be increased for installations with data dirs located in RAID array.
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
# The minimum age of a log file to be eligible for deletion due to age
log.retention.hours=168
#log.retention.bytes=1073741824
# The maximum size of a log segment file. When this size is reached a new log segment will be created.
log.segment.bytes=1073741824
# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
log.retention.check.interval.ms=300000
############################# Zookeeper #############################
zookeeper.connect=zk.easyolap.cn:2181

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=6000
confluent.support.metrics.enable=true
group.initial.rebalance.delay.ms=0
confluent.support.customer.id=anonymous
```

**编辑环境变量**

```
vim ~/.bash_profile

#confluent kafka env
export CONFLUENT_HOME=/data/confluent-7.3.0
export PATH=$PATH:$CONFLUENT_HOME/bin
```

**快速启动**

这里只启动kafka 和 zookeeper，其他相关组件暂不做过多介绍，有用到时，会有详细的文章进行说明。

```
confluent start kafka

#confluent start 默认启动全部的组件
# 查看confluent相关组件的启动状态

confluent status
```

## 四、开始使用

### 1. 创建topic

```
kafka-topics --create --zookeeper kafka.easyolap.cn:2181 --replication-factor 1 --partitions 1 --topic topicTest
```

### 2. 列出所有的topic

```
kafka-topics --zookeeper zk.easyolap.cn:2181 --list
```

### 3. 查看某一个topic的详细信息

```
kafka-topics --zookeeper zk.easyolap.cn:2181 --describe -topic topicTest
```

### 4. 生产者生产消息

```
kafka-console-producer --broker-list kafka.easyolap.cn:9092 --topic topicTest
```

### 5. 消费者消费消息

```
kafka-console-consumer --zookeeper zk.easyolap.cn:2181 --from-beginning --topic topicTest
```

### 6. 删除topic

```
kafka-topics --zookeeper zk.easyolap.cn:2181 --delete --topic topicTest
```



## 四、Confluent Kafka Docker部署
1、Confluent Kafka一站式部署
Confluent提供了Confluent Kafka所有组件的一站式部署，即cp-all-in-one项目，分为企业版本和开源社区版本，企业版比社区版本多了Control Center服务。

GitHub项目地址：

https://github.com/confluentinc/cp-all-in-one

2、Confluent Kafka企业版
docker-compose.yml文件：

version: '2'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:5.5.0
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  broker:
    image: confluentinc/cp-server:5.5.0
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_METRIC_REPORTERS: io.confluent.metrics.reporter.ConfluentMetricsReporter
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_CONFLUENT_LICENSE_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS: broker:29092
      CONFLUENT_METRICS_REPORTER_ZOOKEEPER_CONNECT: zookeeper:2181
      CONFLUENT_METRICS_REPORTER_TOPIC_REPLICAS: 1
      CONFLUENT_METRICS_ENABLE: 'true'
      CONFLUENT_SUPPORT_CUSTOMER_ID: 'anonymous'

  schema-registry:
    image: confluentinc/cp-schema-registry:5.5.0
    hostname: schema-registry
    container_name: schema-registry
    depends_on:
      - zookeeper
      - broker
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL: 'zookeeper:2181'

  connect:
    image: cnfldemos/cp-server-connect-datagen:0.3.2-5.5.0
    hostname: connect
    container_name: connect
    depends_on:
      - zookeeper
      - broker
      - schema-registry
    ports:
      - "8083:8083"
    environment:
      CONNECT_BOOTSTRAP_SERVERS: 'broker:29092'
      CONNECT_REST_ADVERTISED_HOST_NAME: connect
      CONNECT_REST_PORT: 8083
      CONNECT_GROUP_ID: compose-connect-group
      CONNECT_CONFIG_STORAGE_TOPIC: docker-connect-configs
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_FLUSH_INTERVAL_MS: 10000
      CONNECT_OFFSET_STORAGE_TOPIC: docker-connect-offsets
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_STATUS_STORAGE_TOPIC: docker-connect-status
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.storage.StringConverter
      CONNECT_VALUE_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      CONNECT_INTERNAL_KEY_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_INTERNAL_VALUE_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      # CLASSPATH required due to CC-2422
      CLASSPATH: /usr/share/java/monitoring-interceptors/monitoring-interceptors-5.5.0.jar
      CONNECT_PRODUCER_INTERCEPTOR_CLASSES: "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor"
      CONNECT_CONSUMER_INTERCEPTOR_CLASSES: "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor"
      CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"
      CONNECT_LOG4J_LOGGERS: org.apache.zookeeper=ERROR,org.I0Itec.zkclient=ERROR,org.reflections=ERROR

  control-center:
    image: confluentinc/cp-enterprise-control-center:5.5.0
    hostname: control-center
    container_name: control-center
    depends_on:
      - zookeeper
      - broker
      - schema-registry
      - connect
      - ksqldb-server
    ports:
      - "9021:9021"
    environment:
      CONTROL_CENTER_BOOTSTRAP_SERVERS: 'broker:29092'
      CONTROL_CENTER_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      CONTROL_CENTER_CONNECT_CLUSTER: 'connect:8083'
      CONTROL_CENTER_KSQL_KSQLDB1_URL: "http://ksqldb-server:8088"
      CONTROL_CENTER_KSQL_KSQLDB1_ADVERTISED_URL: "http://localhost:8088"
      CONTROL_CENTER_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
      CONTROL_CENTER_REPLICATION_FACTOR: 1
      CONTROL_CENTER_INTERNAL_TOPICS_PARTITIONS: 1
      CONTROL_CENTER_MONITORING_INTERCEPTOR_TOPIC_PARTITIONS: 1
      CONFLUENT_METRICS_TOPIC_REPLICATION: 1
      PORT: 9021

  ksqldb-server:
    image: confluentinc/cp-ksqldb-server:5.5.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    depends_on:
      - broker
      - connect
    ports:
      - "8088:8088"
    environment:
      KSQL_CONFIG_DIR: "/etc/ksql"
      KSQL_BOOTSTRAP_SERVERS: "broker:29092"
      KSQL_HOST_NAME: ksqldb-server
      KSQL_LISTENERS: "http://0.0.0.0:8088"
      KSQL_CACHE_MAX_BYTES_BUFFERING: 0
      KSQL_KSQL_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
      KSQL_PRODUCER_INTERCEPTOR_CLASSES: "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor"
      KSQL_CONSUMER_INTERCEPTOR_CLASSES: "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor"
      KSQL_KSQL_CONNECT_URL: "http://connect:8083"

  ksqldb-cli:
    image: confluentinc/cp-ksqldb-cli:5.5.0
    container_name: ksqldb-cli
    depends_on:
      - broker
      - connect
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true

  ksql-datagen:
    image: confluentinc/ksqldb-examples:5.5.0
    hostname: ksql-datagen
    container_name: ksql-datagen
    depends_on:
      - ksqldb-server
      - broker
      - schema-registry
      - connect
    command: "bash -c 'echo Waiting for Kafka to be ready... && \
                       cub kafka-ready -b broker:29092 1 40 && \
                       echo Waiting for Confluent Schema Registry to be ready... && \
                       cub sr-ready schema-registry 8081 40 && \
                       echo Waiting a few seconds for topic creation to finish... && \
                       sleep 11 && \
                       tail -f /dev/null'"
    environment:
      KSQL_CONFIG_DIR: "/etc/ksql"
      STREAMS_BOOTSTRAP_SERVERS: broker:29092
      STREAMS_SCHEMA_REGISTRY_HOST: schema-registry
      STREAMS_SCHEMA_REGISTRY_PORT: 8081

  rest-proxy:
    image: confluentinc/cp-kafka-rest:5.5.0
    depends_on:
      - zookeeper
      - broker
      - schema-registry
    ports:
      - 8082:8082
    hostname: rest-proxy
    container_name: rest-proxy
    environment:
      KAFKA_REST_HOST_NAME: rest-proxy
      KAFKA_REST_BOOTSTRAP_SERVERS: 'broker:29092'
      KAFKA_REST_LISTENERS: "http://0.0.0.0:8082"
      KAFKA_REST_SCHEMA_REGISTRY_URL: 'http://schema-registry:8081'
启动容器服务：

docker-compose -f docker-compose.yml up -d
关闭容器服务：

docker-compose -f docker-compose.yml down
————————————————
版权声明：本文为CSDN博主「天山老妖」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/A642960662/article/details/123055555
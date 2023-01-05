---
title: "Apache Beam - TopN"
date: 2023-01-05T20:00:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Apache Beam - TopN"
tags: ["Apache Beam","TopN","bigdata"]
keywords: ["Apache Beam","bigdata"]
image: "/img/spring-boot.jpg"
link: "https://spring.io/"
fact: "Apache Beam学习笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/apache-beam-topn

通过练习一个小项目学习apache beam 计算TopN

一、背景

学习写一个跑步小程序。为了激励参与者，提高参与度，提供一个排名功能，利用此功能采用apache beam sdk来进行编写，为什么选择apache beam.因为apache beam是一个通用的sdk，对运行环境友好，支持。

 Apache Beam(Batch+strEAM)是一个用于批处理和流式数据处理作业的统一编程模型。它提供了一个软件开发工具包，用于定义和构建数据处理管道以及执行这些管道的运行程序。

Apache Beam旨在提供一个可移植的编程层。事实上，Beam管道运行程序将数据处理管道转换为与用户选择的后端兼容的API。目前，支持这些分布式处理后端有：

- Apache Apex

- Apache Flink

- Apache Gearpump (incubating)

- Apache Samza

- Apache Spark

- Google Cloud Dataflow

- Hazelcast Jet

#### 为啥选择 Apache Beam

  Apache Beam 将批处理和流式数据处理融合在一起，而其他组件通常通过单独的 API 来实现这一点 。因此，很容易将流式处理更改为批处理，反之亦然，例如，随着需求的变化。

  Apache Beam 提高了可移植性和灵活性。我们关注的是逻辑，而不是底层的细节。此外，我们可以随时更改数据处理后端。

  Apache Beam 可以使用 Java、Python、Go和 Scala等SDK。事实上，团队中的每个人都可以使用他们选择的语言。

#### 基本概念

使用 Apache Beam，我们可以构建工作流图(管道)并执行它们。编程模型中的关键概念是：

- PCollection–表示可以是固定批处理或数据流的数据集
- PTransform–一种数据处理操作，它接受一个或多个 PCollections 并输出零个或多个 PCollections。
- Pipeline–表示 PCollection 和 PTransform 的有向无环图，因此封装了整个数据处理作业。
- PipelineRunner–在指定的分布式处理后端上执行管道。

简单地说，PipelineRunner 执行一个管道，管道由 PCollection 和 PTransform 组成。





二、动手写

1.**依赖**

 

```
   <properties>
   <beam.version>2.43.0</beam.version>
   ...
   </properties>
  
  <dependencies>
   <dependency>
      <groupId>org.apache.beam</groupId>
      <artifactId>beam-sdks-java-core</artifactId>
      <version>${beam.version}</version>
    </dependency>
    <dependency>
      <groupId>org.apache.beam</groupId>
      <artifactId>beam-sdks-java-io-jdbc</artifactId>
      <version>${beam.version}</version>
    </dependency>
    <dependency>
      <groupId>org.apache.beam</groupId>
      <artifactId>beam-runners-direct-java</artifactId>
      <version>${beam.version}</version>
      <scope>test</scope>
    </dependency>
    
    ...
    </dependencies>
```

 

2.**实现**

核心代码：

```
//读取Mysql data
        PCollection<KV<String,Trip>> resultCollection =
                p.apply(JdbcIO.<KV<String,Trip>>read()
                .withDataSourceConfiguration(JdbcIO.DataSourceConfiguration.create(
                        driver,
                        options.getConnUrl())
                        .withUsername(options.getUserName())
                        .withPassword(options.getPassword()))
                .withQuery(querySql)
                // 对结果集中的每一条数据进行处理
                .withRowMapper(new JdbcIO.RowMapper<KV<String,Trip>>() {
                    @Override
                    public KV<String,Trip> mapRow(ResultSet resultSet) throws Exception {
                        Trip trip = new Trip();
                        String id = resultSet.getString("id");
                        String cid = resultSet.getString("cid");
                        String ccid = resultSet.getString("ccid");

                        String sid = resultSet.getString("sid");
                        BigDecimal distance = resultSet.getBigDecimal("distance");
                        Long runTime = resultSet.getLong("run_time");
                        Date createDate = resultSet.getDate("create_date");
                        if(createDate == null ){
                            createDate = new Date();
                        }
                        int year = DateUtil.year(createDate);
                        int month = DateUtil.month(createDate);
                        String day = DateUtil.format(createDate, DatePattern.NORM_DATE_PATTERN);
                        int week = DateUtil.weekOfYear(createDate);
                        trip.setId(id);
                        trip.setYear(year+"");
                        trip.setMonth(month+"");
                        trip.setDay(day);
                        trip.setWeek(week+"");

                        trip.setsId(sid);
                        trip.setCcId(ccid);
                        trip.setcId(cid);
                        trip.setDistance(distance);
                        trip.setRunTimes(runTime);
                        log.info("sid:{},distance:{}",sid , distance);
                        String key = sid +"_"+trip.getDay();
                        return KV.of(key,trip);
                    }
                }));

        // 根据sid聚合,把同一个人的数据聚合为一条
        PCollection<KV<String, Trip>> resultPerson = resultCollection.apply(
                GroupByKey.<String,Trip>create())
                // 对聚合后的结果进行处理
                .apply(MapElements.into(TypeDescriptors.kvs(TypeDescriptors.strings(),TypeDescriptor.of(Trip.class)))
                        .via(e -> {
                    Iterable<Trip> value = e.getValue();
                    if (value == null) {
                        throw new NullPointerException();
                    }
                    Iterator<Trip> iterator = e.getValue().iterator();
                    BigDecimal d = BigDecimal.ZERO;
                    long t = 0;
                    Trip tmp = null;
                    while (iterator.hasNext()) {
                        tmp = iterator.next();
                        d = d.add(tmp.getDistance());
                        t+= tmp.getRunTimes();
                    }
                    //把某个人的数据聚合完成
                   Trip trip = new Trip();
                    BeanUtil.copyProperties(tmp,trip);
                    //聚合后的
                    trip.setDistance(d);
                    trip.setRunTimes(t);
                    return KV.of(e.getKey(), trip);
                }));

                // 自定义算子打印结果集
        PCollection<KV<String, List<Trip>>> largest10ValuesPerKey =
                resultPerson.apply(ParDo.of(new DoFn<KV<String, Trip>, KV<String, Trip>>() {
                    @ProcessElement
                    public void processElement(ProcessContext context) {
                        // 从管道中取出的每个元素
                        KV<String, Trip> element = context.element();
                        log.info("========== trip element info:{}",element);
                        context.output(element);
                    }
                })).apply(
                        "Max top N",
                        Top.largestPerKey(options.getTopn()));


        PCollection<KV<String, Trip>> topnTrips = largest10ValuesPerKey.apply(
                ParDo.of(new DoFn<KV<String, List<Trip>>,KV<String, Trip>>() {
            @ProcessElement
            public void processElement(ProcessContext context) {
                // 从管道中取出的每个元素
                KV<String, List<Trip>> element = context.element();
                String key = element.getKey();
                List<Trip> vals = element.getValue();
                if(vals!=null){
                    log.info("===key is:{}==vals size is ：{}",key,vals.size());
                    int i = 1;
                    for(Trip t : vals){
                        Trip trip = new Trip();
                        trip.setRank(i);
                        BeanUtil.copyProperties(t,trip);
                        log.info("sid group by info:{},topn is:{}", key, i);

                        i++;
                        KV<String,  Trip> kv = KV.of(key,trip);
                        context.output(kv);
                    }

                }else{
                    log.info("=====vals is empty ");
                }
            }
        }));

        // 将结果集写入数据库
        topnTrips.apply(JdbcIO.<KV<String,Trip>>write()
                .withDataSourceConfiguration(JdbcIO.DataSourceConfiguration.create(
                        driver,
                        options.getConnUrl())
                        .withUsername(options.getUserName())
                        .withPassword(options.getPassword()))
                .withStatement("insert into u_ranks " +
                        "(year,month,day,week,sid,cid,ccid,distance,run_time,rank,types,id,create_date) " +
                        "values(?,?,?,?,?,?,?,?,?,?,?,?,?)")
                .withPreparedStatementSetter(new JdbcIO.PreparedStatementSetter<KV<String,Trip>>() {
                    @Override
                    public void setParameters(KV<String,Trip> e,
                                              PreparedStatement preparedStatement) throws Exception {
                        if (e != null) {
                            String key = e.getKey();
                            Trip element = e.getValue();

                            log.info("==========JdbcIO==============key:{},size:{}",key,element);
                            LocalDate createDate = element.getCreateDate();

                            preparedStatement.setString(1, element.getYear());
                            preparedStatement.setString(2, element.getMonth());
                            preparedStatement.setString(3, element.getDay());
                            preparedStatement.setString(4, element.getWeek());

                            preparedStatement.setString(5, element.getsId());
                            preparedStatement.setString(6, element.getcId());
                            preparedStatement.setString(7, element.getCcId());

                            preparedStatement.setBigDecimal(8, element.getDistance());
                            preparedStatement.setLong(9, element.getRunTimes());
                            preparedStatement.setLong(10, element.getRank());

                            preparedStatement.setInt(11, RankType.TYPE_CLASS_DAY);
                            preparedStatement.setString(12,key);
                            preparedStatement.setDate(13, new java.sql.Date(System.currentTimeMillis()));
                            //preparedStatement.execute();  不需要执行，如果加上此句则会出现数据重复

                        }
                    }
                }));

                p.run().waitUntilFinish();
    }



    public static void main(String[] args) {
        log.info("logback 计算开始");
        RankCountByClass.RankCountByClassOptions options =
                PipelineOptionsFactory.fromArgs(args)
                        .withValidation()
                        .as(RankCountByClass.RankCountByClassOptions.class);

        runCount(options);
    }
```



 过程解释：

1.读取Mysql data

2.根据sid聚合,把同一个人的数据聚合为一个PCollection

3.自定义算子打印结果集，并调用Top.largestPerKey方法。

4.将结果集写入数据库。

打包：

以调试环境直接运行为例

```
mvn clean package -P direct-runner
```



运行：

```
java -cp ./rank-count-beam-bundled-0.1.jar:./ cn.easyolap.bigdata.RankCountByClass \
  --runner=DirectRunner \
  --connUrl=jdbc:mysql://sql.easyolap.cn:3306/sport \
  --userName=root \
  --password=123456 \
  --scopeStart=2022-12-01 \
  --scopeEnd=2022-12-12

```

在spark,flink环境中运行待以后补充。
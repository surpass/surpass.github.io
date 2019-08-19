---
title: "Presto实现原理"
date: 2018-08-19T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Presto实现原理"
tags: ["mysql","优化"]
keywords: ["Presto","优化"]
image: "/img/presto.jpg"
link: "https://mysql.com/"
fact: " Presto实现原理"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/mysql-001

# Presto实现原理

转自（https://www.toutiao.com/i6721655256595300868）


Facebook的数据仓库存储在少量大型Hadoop/HDFS集群。Hive是Facebook在几年前专为Hadoop打造的一款数据仓库工具。在以前，Facebook的科学家和分析师一直依靠Hive来做数据分析。但Hive使用MapReduce作为底层计算框架，是专为批处理设计的。但随着数据越来越多，使用Hive进行一个简单的数据查询可能要花费几分到几小时，显然不能满足交互式查询的需求。Facebook也调研了其他比Hive更快的工具，但它们要么在功能有所限制要么就太简单，以至于无法操作Facebook庞大的数据仓库。

2012年开始试用的一些外部项目都不合适，他们决定自己开发，这就是Presto。2012年秋季开始开发，目前该项目已经在超过 1000名Facebook雇员中使用，运行超过30000个查询，每日数据在1PB级别。Facebook称Presto的性能比Hive要好上10倍多。2013年Facebook正式宣布开源Presto。

本文首先介绍Presto从用户提交SQL到执行的这一个过程，然后尝试对Presto实现实时查询的原理进行分析和总结，最后介绍Presto在美团的使用情况。

# Presto架构

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/21bc66c863df43898a66f3c451b7efbf)





Presto查询引擎是一个Master-Slave的架构，由一个Coordinator节点，一个Discovery Server节点，多个Worker节点组成，Discovery Server通常内嵌于Coordinator节点中。Coordinator负责解析SQL语句，生成执行计划，分发执行任务给Worker节点执行。Worker节点负责实际执行查询任务。Worker节点启动后向Discovery Server服务注册，Coordinator从Discovery Server获得可以正常工作的Worker节点。如果配置了Hive Connector，需要配置一个Hive MetaStore服务为Presto提供Hive元信息，Worker节点与HDFS交互读取数据。

# Presto执行查询过程简介

既然Presto是一个交互式的查询引擎，我们最关心的就是Presto实现低延时查询的原理，我认为主要是下面几个关键点，当然还有一些传统的SQL优化原理，这里不介绍了。

1. 完全基于内存的并行计算
2. 流水线
3. 本地化计算
4. 动态编译执行计划
5. 小心使用内存和数据结构
6. 类BlinkDB的近似查询
7. GC控制

为了介绍上述几个要点，这里先介绍一下Presto执行查询的过程

提交查询

用户使用Presto Cli提交一个查询语句后，Cli使用HTTP协议与Coordinator通信，Coordinator收到查询请求后调用SqlParser解析SQL语句得到Statement对象，并将Statement封装成一个QueryStarter对象放入线程池中等待执行。

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/4236b74eddb44c97aea644464fdc9f0e)

提交查询

# SQL编译过程

Presto与Hive一样，使用Antlr编写SQL语法，语法规则定义在Statement.g和StatementBuilder.g两个文件中。 如下图中所示从SQL编译为最终的物理执行计划大概分为5部，最终生成在每个Worker节点上运行的LocalExecutionPlan，这里不详细介绍SQL解析为逻辑执行计划的过程，通过一个SQL语句来理解查询计划生成之后的计算过程。

![Presto实现原理](http://p3.pstatp.com/large/pgc-image/979d62c18d474523a2472ac88b7c5d19)

SQL解析过程



样例SQL：

```
select c1.rank, count(*) from dim.city c1 join dim.city c2 on c1.id = c2.id where c1.id > 10 group by c1.rank limit 10;
```

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/465f300d26d84631b4e87599fdd84bc0)

逻辑执行计划



上面的SQL语句生成的逻辑执行计划Plan如上图所示。那么Presto是如何对上面的逻辑执行计划进行拆分以较高的并行度去执行完这个计划呢，我们来看看物理执行计划。

# 物理执行计划

逻辑执行计划图中的虚线就是Presto对逻辑执行计划的切分点，逻辑计划Plan生成的SubPlan分为四个部分，每一个SubPlan都会提交到一个或者多个Worker节点上执行。

SubPlan有几个重要的属性planDistribution、outputPartitioning、partitionBy属性。

1. PlanDistribution表示一个查询Stage的分发方式，逻辑执行计划图中的4个SubPlan共有3种不同的PlanDistribution方式：Source表示这个SubPlan是数据源，Source类型的任务会按照数据源大小确定分配多少个节点进行执行；Fixed表示这个SubPlan会分配固定的节点数进行执行（Config配置中的query.initial-hash-partitions参数配置，默认是8）；None表示这个SubPlan只分配到一个节点进行执行。在下面的执行计划中，SubPlan1和SubPlan0 PlanDistribution=Source，这两个SubPlan都是提供数据源的节点，SubPlan1所有节点的读取数据都会发向SubPlan0的每一个节点；SubPlan2分配8个节点执行最终的聚合操作；SubPlan3只负责输出最后计算完成的数据。
2. OutputPartitioning属性只有两个值HASH和NONE，表示这个SubPlan的输出是否按照partitionBy的key值对数据进行Shuffle。在下面的执行计划中只有SubPlan0的OutputPartitioning=HASH，所以SubPlan2接收到的数据是按照rank字段Partition后的数据。

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/d5c8dc818dd447f5bfdb42b35f3d4f28)

物理执行计划



# 完全基于内存的并行计算

**查询的并行执行流程**

Presto SQL的执行流程如下图所示

1. Cli通过HTTP协议提交SQL查询之后，查询请求封装成一个SqlQueryExecution对象交给Coordinator的SqlQueryManager#queryExecutor线程池去执行
2. 每个SqlQueryExecution线程（图中Q-X线程）启动后对查询请求的SQL进行语法解析和优化并最终生成多个Stage的SqlStageExecution任务，每个SqlStageExecution任务仍然交给同样的线程池去执行
3. 每个SqlStageExecution线程（图中S-X线程）启动后每个Stage的任务按PlanDistribution属性构造一个或者多个RemoteTask通过HTTP协议分配给远端的Worker节点执行
4. Worker节点接收到RemoteTask请求之后，启动一个SqlTaskExecution线程（图中T-X线程）将这个任务的每个Split包装成一个PrioritizedSplitRunner任务（图中SR-X）交给Worker节点的TaskExecutor#executor线程池去执行

![Presto实现原理](http://p3.pstatp.com/large/pgc-image/3cc6253531f641e8936b5906b997062c)

查询执行流程



上面的执行计划实际执行效果如下图所示。

1. Coordinator通过HTTP协议调用Worker节点的 /v1/task 接口将执行计划分配给所有Worker节点（图中蓝色箭头）
2. SubPlan1的每个节点读取一个Split的数据并过滤后将数据分发给每个SubPlan0节点进行Join操作和Partial Aggr操作
3. SubPlan1的每个节点计算完成后按GroupBy Key的Hash值将数据分发到不同的SubPlan2节点
4. 所有SubPlan2节点计算完成后将数据分发到SubPlan3节点
5. SubPlan3节点计算完成后通知Coordinator结束查询，并将数据发送给Coordinator

![Presto实现原理](http://p3.pstatp.com/large/pgc-image/76a0cf543016437592e2b69dd4e1b5fb)

执行计划计算流程



源数据的并行读取

在上面的执行计划中SubPlan1和SubPlan0都是Source节点，其实它们读取HDFS文件数据的方式就是调用的HDFS InputSplit API，然后每个InputSplit分配一个Worker节点去执行，每个Worker节点分配的InputSplit数目上限是参数可配置的，Config中的query.max-pending-splits-per-node参数配置，默认是100。

分布式的Hash聚合

上面的执行计划在SubPlan0中会进行一次Partial的聚合计算，计算每个Worker节点读取的部分数据的部分聚合结果，然后SubPlan0的输出会按照group by字段的Hash值分配不同的计算节点，最后SubPlan3合并所有结果并输出

# 流水线

**数据模型**

Presto中处理的最小数据单元是一个Page对象，Page对象的数据结构如下图所示。一个Page对象包含多个Block对象，每个Block对象是一个字节数组，存储一个字段的若干行。多个Block横切的一行是真实的一行数据。一个Page最大1MB，最多16*1024行数据。

![Presto实现原理](http://p3.pstatp.com/large/pgc-image/b2473eb0aadd492099eab5ff8f1add23)

数据模型

**节点内部流水线计算**

下图是一个Worker节点内部的计算流程图，左侧是任务的执行流程图。

Worker节点将最细粒度的任务封装成一个PrioritizedSplitRunner对象，放入pending split优先级队列中。每个

Worker节点启动一定数目的线程进行计算，线程数task.shard.max-threads=availableProcessors() * 4，在config中配置。

每个空闲的线程从队列中取出一个PrioritizedSplitRunner对象执行，如果执行完成一个周期，超过最大执行时间1秒钟，判断任务是否执行完成，如果完成，从allSplits队列中删除，如果没有，则放回pendingSplits队列中。

每个任务的执行流程如下图右侧，依次遍历所有Operator，尝试从上一个Operator取一个Page对象，如果取得的Page不为空，交给下一个Operator执行。

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/9d0bf4bb8aa44f1b9b7e4aeb54b6904e)

节点内部流水线计算



**节点间流水线计算**

下图是ExchangeOperator的执行流程图，ExchangeOperator为每一个Split启动一个HttpPageBufferClient对象，主动向上一个Stage的Worker节点拉数据，数据的最小单位也是一个Page对象，取到数据后放入Pages队列中

![Presto实现原理](http://p3.pstatp.com/large/pgc-image/5109d2600f694dceae942ef2ac059259)

节点间流水线计算



# 本地化计算

Presto在选择Source任务计算节点的时候，对于每一个Split，按下面的策略选择一些minCandidates

1. 优先选择与Split同一个Host的Worker节点
2. 如果节点不够优先选择与Split同一个Rack的Worker节点
3. 如果节点还不够随机选择其他Rack的节点

对于所有Candidate节点，选择assignedSplits最少的节点。

# 动态编译执行计划

Presto会将执行计划中的ScanFilterAndProjectOperator和FilterAndProjectOperator动态编译为Byte Code，并交给JIT去编译为native代码。Presto也使用了Google Guava提供的LoadingCache缓存生成的Byte Code。

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/65f75f5723b64d0abe299e7835278720)

动态编译执行计划

![Presto实现原理](http://p1.pstatp.com/large/pgc-image/539fe8f214524270bf35adc64354b652)

动态编译执行计划

上面的两段代码片段中，第一段为没有动态编译前的代码，第二段代码为动态编译生成的Byte Code反编译之后还原的优化代 码，我们看到这里采用了循环展开的优化方法。

循环展开最常用来降低循环开销，为具有多个功能单元的处理器提供指令级并行。也有利于指令流水线的调度。

# 小心使用内存和数据结构

使用Slice进行内存操作，Slice使用Unsafe#copyMemory实现了高效的内存拷贝，Slice仓库参考：https://github.com/airlift/slice

Facebook工程师在另一篇介绍ORCFile优化的文章中也提到使用Slice将ORCFile的写性能提高了20%~30%，参考：https://code.facebook.com/posts/229861827208629/scaling-the-facebook-data-warehouse-to-300-pb/

# 类BlinkDB的近似查询

为了加快avg、count distinct、percentile等聚合函数的查询速度，Presto团队与BlinkDB作者之一Sameer Agarwal合作引入了一些近似查询函数approx_avg、approx_distinct、approx_percentile。approx_distinct使用HyperLogLog Counting算法实现。

# GC控制

Presto团队在使用hotspot java7时发现了一个JIT的BUG，当代码缓存快要达到上限时，JIT可能会停止工作，从而无法将使用频率高的代码动态编译为native代码。

Presto团队使用了一个比较Hack的方法去解决这个问题，增加一个线程在代码缓存达到70%以上时进行显式GC，使得已经加载的Class从perm中移除，避免JIT无法正常工作的BUG。
---
title: "Cassandra集群优化与运维"
date: 2023-03-07T22:30:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Stargate-一个为数据打造的开源API框架"
tags: ["cassandra"]
keywords: ["cassandra"]
image: "/img/stargate.jpg"
link: "https://cassandra.apache.org/"
fact: "Cassandra集群优化与运维"
weight: 400
sitemap:
  priority : 0.8
---

# **Cassandra集群优化与运维**

# **集群部署**

Cassandra集群的性能与其规模线性正相关。可以说Cassandra在目前流行的开源分布式中间件中，设计最为优雅，架构堪称完美，没有之一。在苹果公司内部Cassandra数据库得到大规模应用，总共有16w个节点，Netflix中有数千个节点。

根据设计压力要求（私有行情峰值持续吞吐量为30w/s,单条数据0.5KB,流量150MB/s，支持单节点1w/s左右写入操作），部署三台物理机（3物理机优于2物理机），每台256G内存，96核CPU，每台部署3个cassandra节点，共九张普通网卡。

具体安装过程参考《Cassandra安装部署手册》，本文只讲述配置，包括Performance Tuning的细节。

在建立表时，可以通过脚本创建，也可以在应用启动时检查创建，**请务必设置TTL时间**，以确保缓存失效。

关闭swap非常关键，这个操作需要申请运维支持。  
将不同节点的commitlog和datalog写在不同的磁盘逻辑分区中，进一步优化性能和可靠性。

在生产环境，一旦上线后要密切监控服务器IO剩余能力，能力不足时，及时扩充服务器和节点。

在设计上，避免使用一个Cassandra集群解决多个不同特征类型业务场景的问题。要针对性的利用Cassandra性能优化策略，优化每个业务场景的性能。

# **首次访问cassandra**

安装完成之后

```undefined
./cqlsh xxx.xxx.xxx.xxx 9042 -uxxx -pxxx
对应服务器IP地址，如果要访问默认的IP地址127.0.0.1，需要修改etc策略
```

CQL和SQL非常相似，具体详见[CQL语法](https://links.jianshu.com/go?to=http%3A%2F%2Fcassandra.apache.org%2Fdoc%2Flatest%2Fcql%2Fdml.html)。

# **集群日常监控命令**

登陆Cassandra服务器，访问到cassandra的安装目录

```bash
cd dev/cassandra/cluster/1/bin
```

查看集群状态总览

```undefined
./nodetool status
```

查看集群总体各个阶段的性能

```undefined
./nodetool tpstats
```

查看集群读写延迟，超过1s都要重点关注

```bash
./nodetool cfstats tbs.mkt_info |head -7
#tbs.mkt_info表示：${keyspace}.${table}
```

查看集群读写延迟统计信息，识别性能问题，一般使用该命令，关注ReadLatency和WriteLatency数值，超过1s都要重点关注

```undefined
./nodetool proxyhistograms
```

查看对应表读写延迟统计信息，当分析具体涉及的数据表结构时，一般使用该命令，关注ReadLatency和WriteLatency数值，超过1s都要重点关注

```bash
./nodetool tablehistograms tbs mkt_info
#tbs表示：${keyspace}
#mkt_info表示：${table}
```

查看集群KeyCache命中率，重点关注hits，命中率越高，说明缓存越有效

```bash
./nodetool info |grep 'Key Cache'
```

查看集群RowCache命中率，重点关注hits，命中率越高，说明缓存越有效

```bash
./nodetool info |grep 'Row Cache'
```

监控磁盘读写流量，间隔2s刷新一次

```undefined
iostat -dx 2
```

建议增加服务器IO监控日志。

进行数据查询，并将查询结果导出到日志

```ruby

$ echo "SELECT video_id,title FROM stackoverflow.videos;" > select.cql
$ bin/cqlsh -f select.cql > output.txt


$ bin/cqlsh -e'SELECT video_id,title FROM stackoverflow.videos' > output.txt
$ cat output.txt
```

# **针对业务特点优化配置**

性能调优首先要明确业务场景以及调优目标，否则就是瞎调。我们当前的业务场景主要追求的是高速大吞吐量的写入操作，容许一定时间2s内读数据不一致。当前9节点集群要求极限必须支持100w/s写和10w/s读，当前实际业务场景要求能够支持30w/s写和1w/s读。

Cassandra性能优化主要着手点：

1. 禁用Read Repair
2. 调整Compression
3. 调整Key Cache 和 Row Cache
4. 调整JVM Heap

优化落脚点：

1. 配置文件cassandra.yaml
2. 启动脚本jvm.options
3. 应用使用CassandraTemplate和Session的方法

配置调整，创建目录，其中commitlog用于存放提交日志，建议使用单独的盘存放，dataNfile用于存放数据文件，有条件建议务必使用SSD，如果是硬盘，建议用raid0，saved_casches用于存放查询缓存，可以与数据文件放在同一个盘上。

根据实战经验看，集群优化要点是减少GC暂停时间，提高服务器CPU利用率。

设计集群部署策略，内存和磁盘运用和监控，数据存储位置，数据文件管理策略，数据日志清理策略。所有服务器都在同一个机架里面，比较简单，也满足实际要求。关于Cassandra的同城异地灾备，可以后续设计跟进。

```bash
################部署调整############### 
#集群名称
cluster_name: XXXXX

#加密验证
authenticator: PasswordAuthenticator

#数据文件位置
data_file_directories:/home/xxx/dev/cassandra/cassdata/cassdata1

#日志文件位置 
commitlog_directory: /home/xxx/dev/cassandra/casscomm/casscomm1

#Key Cache和Row Cache缓存文件对应地址
saved_caches_directory: /home/xxx/dev/cassandra/applogs/saved_caches/1

#集群种子节点配置，同一个集群的每个节点的种子节点必须一致，配置2-3个种子就可以了
seed_provider:  
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:          
        - seeds: "xxx.xxx.xxx.xxx,xxx.xxx.xxx.xxx"

#本地IP和端口
native_transport_port: 9042
listen_address: xxx.xxx.xxx.xxx
rpc_address: xxx.xxx.xxx.xxx

#网关设置时间，保持一致
request_timeout_in_ms: 30000

#集群拓扑结构感知方式
endpoint_snitch: GossipingPropertyFileSnitch
dynamic_snitch_update_interval_in_ms: 100
dynamic_snitch_reset_interval_in_ms: 10000
dynamic_snitch_badness_threshold: 0.1
################部署调整###############
```

数据结构优化。Cassandra写数据的速度非常快, 其原因就在于Cassandra是一个基于日志结构的存储引擎, Cassandra对数据的操作全部采用append的方式. 当Cassandra的任何一个节点, 接收到写请求时

1. 将新记录写入CommitLog。Cassandra在将数据写入到Memtable前, 会先将数据append到CommitLog中。当节点从故障中恢复时, 会从CommitLog中读取数据;
2. 将新纪录写入Memtable;
3. 在特定的时间, 将Memtable中的数据刷入到SSTables, 清空JVM Heap和CommitLog;
4. 在特定的时间, Cassandra Compaction将SSTables合并.

```bash

################数据结构############### 
#批量数据大小超过5M则报警，增加该值可能引起节点不稳定，根据自己业务数据评估来针对性优化
batch_size_warn_threshold_in_kb: 5000

#批量数据大小超过100M则批量操作失败
batch_size_fail_threshold_in_kb: 100000

#提交日志相关优化
#行情是周期性很强的应用，所以为了保证数据能够异步持久化到磁盘上，并减少损失，使用1s间隔刷新，避免因为batch导致写阻塞block
commitlog_sync: periodic
commitlog_sync_period_in_ms: 1000
#每个commit log 32M
commitlog_segment_size_in_mb: 32
#全部commit log大小 4G，促使memtable刷入sstable
commitlog_total_space_in_mb: 4096

batchlog_replay_throttle_in_kb: 32768

#结合业务特点，大量写，尽快进行压缩
compaction_throughput_mb_per_sec: 256


################数据结构###############
```

线程分配优化

```bash
###############线程优化###############  
#处理CQL的最大线程数          
native_transport_max_threads: 4092

#刷盘线程
memtable_flush_writers: 2

#压缩线程
concurrent_compactors: 8

#并发读线程
concurrent_reads: 512

#并发写线程
concurrent_writes: 256

#并发计数器线程
concurrent_counter_writes: 512
###############线程优化############### 
```

内存使用优化。导致GC暂停的根本原因是存入的速度大于移除的速度。所以优化的重点就是尽快删除数据。

```bash

###############内存优化############### 
#确保CDC配置关闭
cdc_enabled: false

#调整key cache占用heap大小，设置为0，关闭key cache
key_cache_size_in_mb: 0

#调整row cache，使用操作系统物理内存
row_cache_size_in_mb: 32768

#定时将缓存刷入磁盘，启动时预热缓存，优化读性能
row_cache_save_period: 1000

#设置缓存的key数量，根据业务场景分析，可以保存所有key值
row_cache_keys_to_save: 0

#实现类
row_cache_class_name: org.apache.cassandra.cache.OHCProvider

#通过Java NIO操作非堆，如果允许，配置成offheap_objects
memtable_allocation_type: offheap_buffers
memtable_offheap_space_in_mb: 32768
#memtable_heap_space_in_mb: 4096


#SSTable读缓存大小
file_cache_size_in_mb: 8192

#当SSTable读缓存耗尽，不分配heap作为读缓存
buffer_pool_use_heap_if_exhausted: false

#数据回传机制的同步带宽 260MB/s
hinted_handoff_throttle_in_kb: 262144

hints_flush_period_in_ms: 1000
max_hints_file_size_in_mb: 256

#索引内存大小
index_summary_capacity_in_mb: 1024
###############内存优化############### 
```

JVM环境变量调整，经过比较，使用G1更合理，能够极大减少暂停时间（STW)。  
内存调大，能极大缓解高并发写入和读取压力下，Cassandra的可靠性和稳定性。

```bash
-Xms32G
-Xmx32G

###关闭CMS

#-XX:+UseParNewGC
#-XX:+UseConcMarkSweepGC
#-XX:+CMSParallelRemarkEnabled
#-XX:SurvivorRatio=8
#-XX:MaxTenuringThreshold=1
#-XX:CMSInitiatingOccupancyFraction=75
#-XX:+UseCMSInitiatingOccupancyOnly
#-XX:CMSWaitDuration=10000
#-XX:+CMSParallelInitialMarkEnabled
#-XX:+CMSEdenChunksRecordAlways
#-XX:+CMSClassUnloadingEnabled


#实测结果G1相对CMS暂停时间更短，虽然transport-request-response阻塞概率更大，但强烈建议使用G1

-XX:+UseG1GC
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:MaxGCPauseMillis=500
-XX:InitiatingHeapOccupancyPercent=70
-XX:ParallelGCThreads=32
-XX:ConcGCThreads=32

##具体配置原因，请参考如下说明
## Have the JVM do less remembered set work during STW, instead
## preferring concurrent GC. Reduces p99.9 latency.
#-XX:G1RSetUpdatingPauseTimePercent=5
#
## Main G1GC tunable: lowering the pause target will lower throughput and vise versa.
## 200ms is the JVM default and lowest viable setting
## 1000ms increases throughput. Keep it smaller than the timeouts in cassandra.yaml.
#-XX:MaxGCPauseMillis=500
#
# Save CPU time on large (>= 16GB) heaps by delaying region scanning
# until the heap is 70% full. The default in Hotspot 8u40 is 40%.
#-XX:InitiatingHeapOccupancyPercent=70
#
# For systems with > 8 cores, the default ParallelGCThreads is 5/8 the number of logical cores.
# Otherwise equal to the number of cores when 8 or less.
# Machines with > 10 cores should try setting these to <= full cores.
#-XX:ParallelGCThreads=16
# By default, ConcGCThreads is 1/4 of ParallelGCThreads.
# Setting both to the same value can reduce STW durations.
#-XX:ConcGCThreads=16

```

# **应用连接池配置**

Cassandra的datastax驱动使用的是异步nio实现的，发出去的请求，不会阻塞线程，当有响应的时候会通知你。所以cassandra客户端和服务器之间不需要太多的连接，因为发送一个请求是很快的，只要一个线程不断监听响应就可以了。

能否充分发挥cassandra的能力，应用合理的使用cassandra api是关键。

```cpp


PoolingOptions poolingOptions = new PoolingOptions();
poolingOptions
.setMaxSimultaneousRequestsPerConnectionThreshold(HostDistance.LOCAL, 32);
poolingOptions.setCoreConnectionsPerHost(HostDistance.LOCAL, 2);
poolingOptions.setMaxConnectionsPerHost(HostDistance.LOCAL, 4);
poolingOptions.setCoreConnectionsPerHost(HostDistance.REMOTE, 2);
poolingOptions.setMaxConnectionsPerHost(HostDistance.LOCAL, 4);
```

# **应用读写一致性配置**

```cpp
QueryOptions qo=new QueryOptions();
qo.setConsistencyLevel(ConsistencyLevel.ONE);
```

```cpp
PreparedStatement  pre=getSession().prepare("select * fromzrf_test where serid=? ");
pre.setConsistencyLevel(ConsistencyLevel.ONE);//设置数据一致性
```

确保在读的时候，不因read repair导致性能变差。

行情场景数据量非常大，可以通过API端压缩，减少网络传输的带宽，但是因为增加应用端CPU消耗，不建议使用。

# **其它服务器优化**

这些优化需要申请root权限。

ulimit的优化

```cpp
cat/etc/security/limits.conf
*soft nofile 102400
*hard nofile 102400
*soft stack 1024
*hard stack 1024
```

内核的tcp优化

```undefined
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_wmem=8192436600873200
net.ipv4.tcp_rmem=32768436600873200
net.ipv4.tcp_mem=945000009150000092700000
net.ipv4.tcp_max_orphans=3276800
net.ipv4.tcp_fin_timeout=30

vm.swappiness=5
```

# **Nodetool运维工具介绍**

nodetool是一个命令行的工具集，提供了一批用于查看表的指标、服务器指标和压缩统计等集群统计信息，它可以监控Cassandra和执行例行的数据库操作。

1. nodetool status 各节点总览状态
2. nodetool cfstats 显示了每个表和keyspace的统计数据，包括读的次数，写的次数，sstable的数量，memtable信息，压缩信息，bloomfilter信息。
3. nodetool netstats 提供了网络连接操作的统计数据。
4. nodetool tpstats 提供了如active、pending以及完成的任务等Cassandra操作的每个阶段的状态。
5. nodetool describecluster 输出集群信息。
6. nodetool describering 后面需要跟keyspace的名字，显示圆环的节点信息。
7. nodetool tpstats 列出Cassandra维护的线程池的信息，你可以直接看到每个阶段有多少操作，以及他们的状态是活动中、等待还是完成。
8. nodetool cfhistograms 提供了表的统计数据，包括读写延迟，行大小，列的数量和SSTable的数量。

# **Cassandra集群原理**

Cassandra是基于事件驱动的架构设计的SEDA(Staged Event Driven Architecture)。其特性Feature包括：

1. Open Source(可快速学习和修改)
2. Distributed(提供性能优化空间)
3. Decentralized(无须配置中心，部署结构简单)
4. Elastically scalable(可扩展)
5. Highly available(安全可靠)
6. Fault-tolerant(安全可靠)
7. Tuneably consistent(可根据性能需求配置调整)
8. Row-oriented database(可分区分片)

其Stage包含：

 1. ReadStage
 2. MiscStage
 3. CompactionExecutor
 4. MutationStage
 5. MemtableReclaimMemory
 6. PendingRangeCalculator
 7. GossipStage
 8. SecondaryIndexManagement
 9. RequestResponseStage
10. Native-Transport-Requests
11. ReadRepairStage
12. CounterMutationStage
13. MigrationStage
14. MemtablePostFlush
15. PerDiskMemtableFlushWriter
16. ValidationExecutor
17. Sampler
18. MemtableFlushWriter
19. InternalResponseStage
20. ViewMutationStage
21. AntiEntropyStage
22. CacheCleanupExecutor

对于想要深入了解cassandra的学习者来说，了解其架构模型、数据模型和各个stage是关键。

# **集群一致性技术**

Cassandra数据采用了最终一致性。最终一致性是指分布式系统中的一个数据对象的多个副本尽管在短时间内可能出现不一致，但是经过一段时间之后，这些副本最终会达到一致。我们在实际运用中，以业务场景为考量，并未采取阻塞至少两节点的方式，而是允许在1s的间隔内，commitlog能够同步就好。

依据分布式系统基本理论CAP原理，应用在使用Cassandra过程中，必须在C和A之间做出权衡。为了提高可用性（Availability），Cassandra采用了副本备份，一般是3副本，当需要修改数据时，就需要更新所有的副本数据，这样才能保证数据的一致性（Consistency）。

Quorum机制是一种C&A权衡机制，一种将“读写转化”的模型，Quorum机制无法保证强一致性，但是我们可以通过，中心节点(服务器)读取R个副本，选择R个副本中版本号最高的副本作为新的primary，新选出的primary不能立即提供服务，还需要与至少与W个副本完成同步后，才能提供服务（为了保证Quorum机制的规则：W+R>N）。

至于如何处理同步过程中冲突的数据，则需要视情况而定。

比如，(V2，V2，V1，V1，V1），R=3，如果读取的3个副本是：(V1，V1，V1)则高版本的 V2需要丢弃。

如果读取的3个副本是（V2，V1，V1），则低版本的V1需要同步到V2

```undefined
N: cassandra网络中复制数据的节点数
R: cassandra网络中读节点数
W: cassandra网络中阻塞写节点数

如果W+R>N, 那么写读写操作都会有多份,这种模式下可以保证数据的强一致性. 在实现了同步(注意,这里不是异步)数据复制类master-slaver的场景中,N=2, W=2, R=1,这种模型可以保证数据一致性. 但是如果是异步数据复制的类master-slaver场景,那么如同我们使用Oracle集群的例子一样,是不能保证数据一致性的.
```

Cassandra 通过4个技术来维护数据的最终一致性，分别为逆熵（Anti-Entropy），读修复（Read Repair），提示移交（Hinted Handoff）和分布式删除。

1. 逆熵。这是一种备份之间的同步机制。节点之间定期互相检查数据对象的一致性，这里采用的检查不一致的方法是 Merkle Tree。
2. 读修复。客户端读取某个对象的时候，触发对该对象的一致性检查，举例：读取Key A的数据时，系统会读取Key A的所有数据副本，如果发现有不一致，则进行一致性修复。如果读一致性要求为ONE，会立即返回离客户端最近的一份数据副本。然后会在后台执行Read Repair。这意味着第一次读取到的数据可能不是最新的数据；如果读一致性要求为QUORUM，则会在读取超过半数的一致性的副本后返回一份副本给客户端，剩余节点的一致性检查和修复则在后台执行；如果读一致性要求高(ALL)，则只有Read Repair完成后才能返回一致性的一份数据副本给客户端。可见，该机制有利于减少最终一致的时间窗口。
3. 提示移交。对写操作，如果其中一个目标节点不在线，先将该对象中继到另一个节点上，中继节点等目标节点上线再把对象给它。举例：Key A按照规则首要写入节点为N1，然后复制到N2。假如N1宕机，如果写入N2能满足ConsistencyLevel要求，则Key A对应的RowMutation将封装一个带hint信息的头部（包含了目标为N1的信息），然后随机写入一个节点N3，此副本不可读。同时正常复制一份数据到N2，此副本可以提供读。如果写N2不满足写一致性要求，则写会失败。 等到N1恢复后，原本应该写入N1的带hint头的信息将重新写回N1。
4. 分布式删除。单机删除非常简单，只需要把数据直接从磁盘上去掉即可，而对于分布式，则不同，分布式删除的难点在于：如果某对象的一个备份节点 A 当前不在线，而其他备份节点删除了该对象，那么等 A 再次上线时，它并不知道该数据已被删除，所以会尝试恢复其他备份节点上的这个对象，这使得删除操作无效。Cassandra 的解决方案是：本地并不立即删除一个数据对象，而是给该对象标记一个hint，定期对标记了hint的对象进行垃圾回收。在垃圾回收之前，hint一直存在，这使得其他节点可以有机会由其他几个一致性保证机制得到这个hint。Cassandra 通过将删除操作转化为一个插入操作，巧妙地解决了这个问题。

# **Cassandra架构模型**

Cassandra集群中任何一台机器出现故障，整个系统都不会受影响，依旧可以正常，这是由其架构模型决定的。其工作拓扑结构：

1. 数据中心Data Center
2. 机架Rack
3. 节点Node

Cassandra 使用分布式哈希表（DHT）来确定存储某一个数据对象的节点。每条数据并不是保存在cassandra中所有的节点上,部分数据会保存在部分节点上。在 DHT 里面，负责存储的节点以及数据对象都被分配一个 token。token 只能在一定的范围内取值，比如说如果用 MD5 作为 token 的话，那么取值范围就是 \[0, 2^128-1\]。存储节点以及对象根据 token 的大小排列成一个环，即最大的 token 后面紧跟着最小的 token，比如对 MD5 而言，token 2^128-1 的下一个 token 就是 0。Cassandra 使用以下算法来分布数据：

首先，每个存储节点被分配一个随机的 token（涉及数据分区策略），该 token 代表它在 DHT 环上的位置；

然后，用户为数据对象指定一个 key（即 row-key），Cassandra 根据这个 key 计算一个哈希值作为 token，再根据 token 确定对象在 DHT 环上的位置；

最后，该数据对象由环上拥有比该对象的 token 大的最小的 token 的节点来负责存储；

根据用户在配置时指定的备份策略（涉及网络拓扑策略），将该数据对象备份到另外的 N-1 个节点上。网络中总共存在该对象的 N 个副本。

客户端（应用）可以访问任何一个节点，这个节点可以被视作Coordinator Nod，其负责确定数据的primary节点，并执行read repair操作和连接对应节点，获取数据。

# **Snitch**

那么如何来计算各个节点上存储的数据之间的差异呢？如何判断自己申请的那一份数据就是最新版本的？

Snitches 按实现分为三种：

1. SimpleSnitch：这种策略不能识别数据中心和机架信息，适合在单数据中心使用；
2. NetworkTopologySnitch：这种策略提供了网络拓扑结构，以便更高效地消息路由；
3. DynamicEndPointSnitch：这种策略可以记录节点之间通信时间间隔，记录节点之间的通信速度，从而达到动态选择最合适节点的目的。

# **Cassandra的缓存模型**

缓存主要目的通过运用内存改善读的性能，良好的配置也能极大改善写的性能。其缓存类型包括：Key Cache 、Row Cache和Counter Cache。官方文档说：如果配置了Row Cache，就不需要配置Key Cache。缓存以key-value形式保存索引数据。

Key Cache存储了分区键和Row之间的映射索引，便于快速访问SSTable，定位和读取存储的数据。Cassandra会对partition key 做一个hash计算，并自己决定将这一条记录放在哪个node，key cache在内存中保存了记录的位置。当一个row的column很大时，不适宜将row整个放在内存中，这个时候使用Key Cache。如果是小数据体，服务器资源足够，可以重点考虑Row Cache。Row Cache在系统内存中完整缓存Row信息。优化需要特别小心，否则可能带来更多的问题。具体优化参考上文实际优化配置。

# **Cassandra内存模型**

Cassandra中有三个非常重要的数据结构：记录在内存中的Memtable，以及保存在磁盘中的Commit Log和SSTable。其存储机制借鉴了Bigtable的设计，和关系数据库一样，Cassandra在写数据之前，也需要先记录日志，称之为commitlog（数据库中的commit log 分为 undo-log, redo-log 以及 undo-redo-log 三类，由于 cassandra采用时间戳识别新老数据而不会覆盖已有的数据，所以无须使用 undo 操作，因此它的 commit log 使用的是 redo log），然后数据才会写入到Column Family对应的Memtable中，且Memtable中的数据是按照key排序好的。Memtable是一种内存结构，满足一定条件后批量刷新（flush）到磁盘上，存储为SSTable。这种机制，相当于缓存写回机制(Write-back Cache)，优势在于将随机IO写变成顺序IO写，降低大量的写操作对于存储系统的压力。SSTable一旦完成写入，就不可变更，只能读取。下一次Memtable需要刷新到一个新的SSTable文件中。所以对于Cassandra来说，可以认为只有顺序写，没有随机写操作。

Cassandra使用Memtable的主要目的是改善写的性能。

SSTable是不可修改的，且一般情况下，一个CF可能会对应多个SSTable，这样，当用户检索数据时，如果每个SSTable均扫描一遍，将大大增加工作量。Cassandra为了减少没有必要的SSTable扫描，使用了BloomFilter，即通过多个hash函数将key映射到一个位图中，来快速判断这个key属于哪个SSTable。

为了减少大量SSTable带来的开销，Cassandra会定期进行compaction，简单的说，compaction就是将同一个CF的多个SSTable合并成一个SSTable。在Cassandra中，compaction主要完成的任务是：

（1）垃圾回收： cassandra并不直接删除数据，因此磁盘空间会消耗得越来越多，compaction 会把标记为删除的数据真正删除；

（2）合并SSTable：compaction 将多个 SSTable 合并为一个（合并的文件包括索引文件，数据文件，bloom filter文件），以提高读操作的效率；

（3）生成 MerkleTree：在合并的过程中会生成关于这个 CF 中数据的 MerkleTree，用于与其他存储节点对比以及修复数据。

变更数据捕获（CDC）提供了一种机制来标记特定的表用于存档，一旦数据量达到配置的刷新和未刷新的CDC日志的大小之和，就拒绝对这些表的写入。然后将任何包含启用表（启用CDC）数据的CommitLogSegments移动到cassandra.yaml中指定的目录丢弃。在yaml中指定允许的总磁盘空间的阈值，此时新分配的CommitLogSegments将不允许写入CDC数据，直到消费者解析并从目标存档目录中删除数据。

性能优化的重点就是充分利用服务器的内存资源，但是尽量不要利用JVM堆，JVM进行垃圾回收时需要收集所有的这些对象的内存。增加了GC压力。因此需要使用堆外内存

# **Cassandra数据模型**

Cassandra中的Keyspace类似关系型数据库的RMDBS中的Database的概念。在Cassandra中存在keyspace>>column family(CF)>>column的模型。

Cassandra的Primary Key由Partition Key和Clustering Key两部分组成。先看只有Partition Key的情况。每一个partition key对应着一个RowKey, 所有的column都存放在这一行上。Cassandra中所有的数据都只能根据Primary Key中的字段来排序, 因此, 如果想根据某个column来排序, 必须将改column加到Primary key中, 如 primary key (id, c1, c2 ,c3), 其中id时partition key, c1, c2 ,c3是Clustering Key.(如果想用id和c1作为partition key, 只需添加括号: primary key ((id, c1), c2 ,c3))。

在Cassandra中, 每一行数据记录是以key/value的形式存储的, 其中key是唯一标识。Cassandra中每个key/value对中的value又称为column, 类似于SQL数据库中的列, 但又有不同. SQL数据库中的列只是一个具体的值, 在Cassandra中, 它是一个三元组, 即: name，value和timestamp, 其中name需要是唯一的.具体存储形式如下所示:

。keyspace由配置文件conf/storage-conf.xml内的配置决定

```xml
<Keyspaces>  
   <Keyspace Name="Keyspace1">  
     <KeysCachedFraction>0.01</KeysCachedFraction>  
     <ColumnFamily CompareWith="BytesType" Name="Standard1"/>  
     <ColumnFamily CompareWith="UTF8Type" Name="Standard2"/>  
     <ColumnFamily CompareWith="TimeUUIDType" Name="StandardByUUID1"/>  
     <ColumnFamily ColumnType="Super"  
                   CompareWith="UTF8Type"  
                   CompareSubcolumnsWith="UTF8Type"  
                   Name="Super1"  
                   Comment="注解"/>  
   </Keyspace>  
</Keyspaces>  
```

# **Cassandra常见错误分析**

使用误区，刚开始我们设计的是每日创建一个表，最后我们放弃了这个方案，虽然cassandra api提供了灵活的建表功能。我们遇到多节点同时建表导致的同步异常。各种血的教训下终于明白，不要重复修改Schema！不要重复修改Schema！不要重复修改Schema！因为Cassandra是一个无中心的分布式数据库，其CREATE/DROP/ALTER等对Schema的修改操作，都是在一个节点上完成后，再同步给集群其它节点的。

出现如下日志：

```swift
Cassandra timeout during write query at consistency LOCAL_ONE (1 replica were required but only 0 acknowledged the write)
```

GC导致如下问题, 也就是发生了非常长时间的gc, 导致整个系统hang住了。观察debug.log日志会出现如下信息：

```bash
Not marking nodes down due to local pause of 53690474502 > 500000000
```

表明集群出现性能瓶颈

# **重点监控**

配置监控/home/xxx/dev/cassandra/cluster/{1,2,3}/logs/debug.log文件，

如果存在如下一种信息，则都有Cassandra出现问题，服务中止。

```css
is now DOWN
UnavailableException
Unexpected exception
Out of memory
java.io.EOFException
Cannot achieve consistency level
Column family ID mismatch
```

Cassandra schema version 不一致

关注集群GC情况，统计一天中性能较差的时间点：

```dart
#按照小时统计长时间GC的次数
grep 'GC' /usr/install/cassandra/logs/system.log | awk '{print $4":"substr($5,0,2)}' | sort | uniq -c | awk '{print $2" "$1}' 
zgrep 'GC in [0-9][0-9][0-9][0-9][0-9]ms' /usr/install/cassandra/logs/system.log.1.zip | awk '{print $4":"substr($5,0,2)}' | sort | uniq -c | awk '{print $2" "$1}'
zgrep 'GC in [0-9][0-9][0-9][0-9][0-9]ms' /usr/install/cassandra/logs/system.log.1.zip | awk '{print $4}' | sort | uniq -c | awk '{print $2" "$1}'
```

# **JMX**

nodetool工具集支持大多数重要的JMX指标和操作，并且包含了一些为管理员准备的命令。这个工具集用得最多的还是输出集群环的快速摘要和集群的当前状况——也就是nodetool status。

# **应急操作**

# **生产环境运维实际问题**

我们的业务因为每天要清表，虽然truncate表，但是cassandra为truncate做了snapshot保存删除的全部数据，所以磁盘占用很快就满了

需要执行清除快照命令

```undefined
./nodetool clearsnapshot custom-table
```

当前报错信息：IncomingTcpConnection closed due to one bad message  
导致数据无法写入cassandra  
查询非常耗时或者出现超时现象

开始我们以为是网络问题，但是ping又没问题

我们发现日志有很多各类异常

Not enough replica available for query at consistency ONE (1 required but only 0 alive)

java.lang.RuntimeException: java.util.concurrent.ExecutionException: java.lang.RuntimeException: org.apache.cassandra.exceptions.ConfigurationException: Column family ID mismatch (found 1660db50-3717-11e5-bb49-4d1f4d3a1785; expected 16490d90-3717-11e5-baae-43ee31cfdaef)

最近一次生产问题，我们发现是升级失误导致不同节点配置不一样。在业务调整后压力徒增4倍后，Cassandra配置不一致和配置不足的问题，导致Cassandra节点宕掉，导致集群不稳定，在生产环境，如果偶发一个节点宕掉，建议不要着急重启，而是等待时机合适（非服务时段或者服务低谷期），再入集群。

最后我们发现，应用连接cassandra的seed节点信息配置信息有误，但是应用竟然成功的启动，并且连接了cassandra。

1. 1到多个IP（ip不要写错，写错一个可能应用可以成功连接，但是查询时，超时）
2. ip之间符号必须是“，”

nodetool

<https://github.com/AppliedInfrastructure/cassandra-snapshot-tools>

# **参考文献**

[Cassandra运维手册](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.iyunv.com%2Fforum.php%3Fmod%3Dviewthread%26tid%3D189088%26highlight%3Dcassandra)

[Cassandra日常运维](https://links.jianshu.com/go?to=http%3A%2F%2Fzqhxuyuan.github.io%2F2015%2F10%2F15%2FCassandra-Daily%2F)

[Cassandra视频学习参考](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.jikexueyuan.com%2Fcourse%2F1985_1.html)

[Cassandra中rowcached对性能的影响](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.csdn.net%2Fhankesi2000%2Farticle%2Fdetails%2F83666952)

[变更数据捕获（CDC）](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.csdn.net%2Fnangongyanya%2Farticle%2Fdetails%2F54090979)

[AKKA和Cassandra结合的一种有效结构](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.jdon.com%2F49535)

[Cassandra简介](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.cnblogs.com%2Floveis715%2Fp%2F5299495.html)

[3\.x Cassandra系列优化](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.csdn.net%2Fqq_32523587%2Farticle%2Fdetails%2F53982900)

[Cassandra无中心化设计元素](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.ibm.com%2Fdeveloperworks%2Fcn%2Fopensource%2Fos-cn-apache-cassandra3x3%2Findex.html)

[分布式系统理论之Quorum机制](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.cnblogs.com%2Fhapjin%2Fp%2F5626889.html)

[译文-调整G1收集器窍门](https://links.jianshu.com/go?to=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000007815623)

[iostat命令详解](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.cnblogs.com%2Fggjucheng%2Farchive%2F2013%2F01%2F13%2F2858810.html)

[cassandra查询超时](https://www.jianshu.com/p/322389395fd6)

[解决Cassandra Schema不一致导致的 Column family ID mismatch](https://links.jianshu.com/go?to=%255Bhttp%3A%2F%2Fblog.imaou.com%2Fcassandra_column_family_id_mismatch%2F%255D%28http%3A%2F%2Fblog.imaou.com%2Fcassandra_column_family_id_mismatch%2F%29)

# **Cassandra配置、运维和监控有关问题索引**

 1. 根据实际业务场景，提供Cassandra安装部署和集群配置方案，加密配置方式，日常运维操作方法和监控事项，以及运维和开发人员培训手册。
 2. 提供Cassandra参数调优分析报告，包括操作系统层面的参数调优，主要针对私有报价行情场景针对性调优。
 3. 介绍Cassandra存储模型和分布式集群设计。
 4. 准备Cassandra生产问题跟踪、应急预案和灾备方案。
 5. Cassandra高可用原理和集群监控方案。
 6. CassandraGUI客户端和命令行客户端集成。
 7. Cassandra基准测试工具使用方法。
 8. 进行Cassandra网络问题专项研究。
 9. 集成spring-data-cassandra，并完善tbs-s-cassandra构件，当前针对大并发写入场景已进行针对性的设计和优化。
10. 提供可视化cassandra数据方式和操作方式。
11. Cassandra集群分区策略与实时分析。
12. Cassandra集群部署设计与数据表设计和管理。
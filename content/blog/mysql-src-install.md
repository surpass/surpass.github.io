---
title: "Mysql源码安装！"
date: 2017-07-31T21:44:58+08:00
draft: false
banner: "https://ws4.sinaimg.cn/large/0069RVTdgy1fttdt7l2qxj30rs0ku0yj.jpg"
author: "Frank Li"
authorlink: "https://surpass.github.io/"
translator: "宋净超"
translatorlink: "https://easyolap.cn"
originallink: "https://surpass.github.io/public/mysql-src-install/"
summary: "今天，我们很高兴地宣布 Istio 1.0。这距离最初的 0.1 版本发布以来已经过了一年多时间了。从 0.1 起，Istio 就在蓬勃发展的社区、贡献者和用户的帮助下迅速发展。现在已经有许多公司成功将 Istio 应用于生产，并通过 Istio 提供的洞察力和控制力获得了真正的价值。"
tags: ["mysql linus install"]
categories: ["mysql"]
keywords: ["mysql","linus"]
---

> 本文转载自：Istio 官方网站，原文地址：https://surpass.github.io/public/announcing-1.0/
 

一、编译安装MySQL前准备工作						
						
安装编译源码所需的工具和库						
yum -y install gcc gcc-c++ ncurses-devel perl  openssl-devel bison						
						
安装cmake（记得好像从mysql 5.5开始需要cmake编译安装），可从https://cmake.org/download/ 中下载。						
tar zxvf cmake-3.6.1.tar.gz 						
cd cmake-3.6.1 						
./bootstrap						
make && make install						
						
二、创建用户及MySQL所需目录						
新增mysql用户						
groupadd -r mysql 						
useradd -r -g mysql mysql						
						
新建MySQL所需目录						
mkdir -p /data/mysql/server 						
mkdir -p /data/mysql/data						
mkdir -p /data/mysql/etc						
						
三、编译安装MySQL						
						
可从http://dev.mysql.com/downloads/mysql/ 下载mysql源码(MySQL Community Server 5.6.32 )。						
tar zxvf mysql-5.6.32.tar.gz 						
cd mysql-5.6.32 						
"cmake -DCMAKE_INSTALL_PREFIX=/data/mysql/server\
 -DDEFAULT_CHARSET=utf8\ 
 -DDEFAULT_COLLATION=utf8_general_ci\ 
 -DWITH_INNOBASE_STORAGE_ENGINE=1\ 
 -DWITH_ARCHIVE_STORAGE_ENGINE=1\ 
 -DWITH_BLACKHOLE_STORAGE_ENGINE=1\ 
 -DMYSQL_DATADIR=/data/mysql/data\ 
 -DMYSQL_TCP_PORT=3306\ 
 -DENABLE_DOWNLOADS=1\ 
 -DSYSCONFDIR=/data/mysql/etc\ 
 -DWITH_SSL=system\ 
 -DWITH_ZLIB=system\ 
 -DWITH_LIBWRAP=0 
"						
						
make && make install						
DCMAKE_INSTALL_PREFIX=dir_name	设置mysql安装目录					
修改mysql目录权限						
cd /data/mysql/server 						
chown -R mysql:mysql ./						
cd /data/mysql/data 						
chown -R mysql:mysql ./						
						
初始化mysql数据库						
cd /data/mysql/server/						
./scripts/mysql_install_db --user=mysql --datadir=/data/mysql/data						
						
编辑MySQL配置文件						
mv /etc/my.cnf /data/mysql/etc/my.cnf						
chown -R mysql:mysql /data/mysql/etc/my.cnf						
编辑my.cnf，my.cnf可在percona官网中及按照自己的情况生成。网址如下：https://tools.percona.com/wizard 。						
[mysql] 						
  						
# CLIENT # 						
port                          = 3306 						
socket                        = /data/mysql/data/mysql.sock 						
  						
[mysqld] 						
  						
# GENERAL # 						
user                          = mysql 						
default-storage-engine        = InnoDB 						
socket                        = /data/mysql/data/mysql.sock 						
pid-file                      = /data/mysql/data/mysql.pid 						
						
skip-external-locking						
skip-name-resolve						
						
# MyISAM # 						
key-buffer-size                = 32M 						
myisam-recover                = FORCE,BACKUP 						
  						
# SAFETY # 						
max-allowed-packet            = 16M 						
max-connect-errors            = 1000000 						
  						
# DATA STORAGE # 						
datadir                        = /data/mysql/data						
  						
# BINARY LOGGING # 						
log-bin                        = /data/mysql/data/mysql-bin						
expire-logs-days              = 14 						
sync-binlog                    = 1 						
  						
# REPLICATION # 						
skip-slave-start              = 1 						
relay-log                      = /data/mysql/data/relay-bin						
slave-net-timeout              = 60 						
  						
# CACHES AND LIMITS # 						
tmp-table-size                = 32M 						
max-heap-table-size            = 32M 						
query-cache-type              = 0 						
query-cache-size              = 0 						
max-connections                = 500 						
thread-cache-size              = 50 						
open-files-limit              = 65535 						
table-definition-cache        = 4096 						
table-open-cache              = 4096 						
  						
# INNODB # 						
innodb-flush-method            = O_DIRECT 						
innodb-log-files-in-group      = 2 						
innodb-log-file-size          = 64M 						
innodb-flush-log-at-trx-commit = 1 						
innodb-file-per-table          = 1 						
innodb-buffer-pool-size        = 592M 						
  						
# LOGGING # 						
log-error                      = /data/mysql/data/mysql-error.log 						
log-queries-not-using-indexes  = 1 						
slow-query-log                = 1 						
slow-query-log-file            = /data/mysql/data/mysql-slow.log						
						
复制MySQL启动文件及其命令加入PATH						
						
cp support-files/mysql.server /etc/init.d/mysqld  						
vim /etc/profile.d/mysql.sh 						
    PATH=/data/mysql/server/bin:/data/mysql/server/lib:$PATH 						
    export PATH 						
source /etc/profile.d/mysql.sh						
						
启动MySQL并增加启动项						
service mysqld start  						
chkconfig  mysqld on						
						
设置MySQL登录权限						
drop user ''@localhost; 						
drop user ''@hostname; 						
update mysql.user set password=password('3qw0ku7'); 						
flush privileges;						
						
至此，MySQL编译安装完成。						
			
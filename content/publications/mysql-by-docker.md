---
title: "Mysql install by Docker！"
date: 2017-07-31T21:44:58+08:00
author: "Frank Li"
authorlink: "https://surpass.github.io/public/about"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "采用docker运行mysql server."
tags: ["mysql","docker","Agile","DevOps"]
keywords: ["mysql","linus"]
image: "/img/mysql.jpg"
link: "https://www.mysql.com/"
fact: "mysql docker"
weight: 400
sitemap:
  priority : 0.8
---
 

						
Docker运行mysql镜像						
-------------------
						
启动mysql镜像						
        [root@CentOS ~]\# docker run -d -e MYSQL_ROOT_PASSWORD=admin --name mysql -v /data/mysql/etc:/etc/mysql/conf.d -v /data/mysql/data:/var/lib/mysql -v /etc/localtime:/etc/localtime:ro mysql 						
						
						
说明：						
1.把数据文件存贮在宿主机中的/data/mysql/data目录下，所以挂载/data/mysql/data到/var/lib/mysql						
2.采用宿主机中的配置启动mysql服务，所以挂载 /data/mysql/etc到/etc/mysql/conf.d 配置文件见下文的my.cnf文件						
3.使容器与宿主机时间同步，挂载/etc/localtime到/etc/localtime:ro  只读的方式。						
						
						
						
						
						
my.cnf 						
						
 						
[mysqld]						
user = mysql						
default-storage-engine = InnoDB						
socket = /var/lib/mysql/mysql.sock 						
pid-file = /var/lib/mysql/mysql.pid 						
						
skip-external-locking						
skip-name-resolve						
						
\\# MyISAM \\# 						
key-buffer-size                = 32M 						
  						
\# SAFETY \# 						
max-allowed-packet            = 16M 						
max-connect-errors            = 1000000 						
  						
\# DATA STORAGE \# 						
datadir                        = /var/lib/mysql						
  						
\# CACHES AND LIMITS \# 						
tmp-table-size                = 32M 						
max-heap-table-size            = 32M 						
query-cache-type              = 0 						
query-cache-size              = 0 						
max-connections                = 500 						
thread-cache-size              = 50 						
open-files-limit              = 65535 						
table-definition-cache        = 4096 						
table-open-cache              = 4096 						
  						
\# INNODB \# 						
innodb-flush-method            = O_DIRECT 						
innodb-log-files-in-group      = 2 						
innodb-log-file-size          = 64M 						
innodb-flush-log-at-trx-commit = 1 						
innodb-file-per-table          = 1 						
innodb-buffer-pool-size        = 592M 						
  						
\# LOGGING \# 						
log-error                      = /var/lib/mysql/mysql-error.log 						
log-queries-not-using-indexes  = 1 						
slow-query-log                = 1 						
slow-query-log-file            = /var/lib/mysql/mysql-slow.log						

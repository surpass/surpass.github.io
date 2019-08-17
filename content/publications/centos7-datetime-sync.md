---
title: "CentOS 7时间和日期和时间同步"
date: 2018-06-27T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "CentOS 7时间和日期和时间同步."
tags: ["Linux","cenots7","timedatectl","chronyc"]
image: "/img/ceph/ceph.jpg"
link: "https://www.centos.org"
fact: "CentOS 7时间和日期和时间同步"
weight: 400
sitemap:
  priority : 0.8
---

CentOS 7时间和日期和时间同步
2018年05月15日 20:35:19 l1212xiao 阅读数 6186
在CentOS 6版本，时间设置有date、hwclock命令

从CentOS 7开始，使用了一个新的命令timedatectl。

1. 基本概念
1.1 GMT、UTC、CST、DST 时间
UTC
整个地球分为二十四时区，每个时区都有自己的本地时间。在国际无线电通信场合，为了统一起见，使用一个统一的时间，称为通用协调时(UTC, Universal Time Coordinated)。

GMT
格林威治标准时间 (Greenwich Mean Time)指位于英国伦敦郊区的皇家格林尼治天文台的标准时间，因为本初子午线被定义在通过那里的经线。(UTC与GMT时间基本相同，本文中不做区分)

CST
中国标准时间 (China Standard Time)

GMT + 8 = UTC + 8 = CST
DST
夏令时(Daylight Saving Time) 指在夏天太阳升起的比较早时，将时间拨快一小时，以提早日光的使用。（中国不使用）

1.2 硬件时间和系统时间
硬件时间
RTC(Real-Time Clock)或CMOS时间，一般在主板上靠电池供电，服务器断电后也会继续运行。仅保存日期时间数值，无法保存时区和夏令时设置。

系统时间
一般在服务器启动时复制RTC时间，之后独立运行，保存了时间、时区和夏令时设置。

2. timedatectl 命令
2.1 使用帮助
[root@localhost ~]# timedatectl -h
timedatectl [OPTIONS...] COMMAND ...

Query or change system time and date settings.

  -h --help              Show this help
     --version           Show package version
     --adjust-system-clock
                         Adjust system clock when changing local RTC mode
     --no-pager          Do not pipe output into a pager
  -P --privileged        Acquire privileges before execution
     --no-ask-password   Do not prompt for password
  -H --host=[USER@]HOST  Operate on remote host

Commands:
  status                 Show current time settings
  set-time TIME          Set system time
  set-timezone ZONE      Set system timezone
  list-timezones         Show known timezones
  set-local-rtc BOOL     Control whether RTC is in local time
  set-ntp BOOL           Control whether NTP is enabled
2.2 命令示例
1.显示系统的当前时间和日期

timedatectl
# timedatectl status
# 两条命令效果等同
2.设置日期与时间

timedatectl set-time "YYYY-MM-DD HH:MM:SS"
timedatectl set-time "YYYY-MM-DD"
timedatectl set-time "HH:MM:SS"
3.查看所有可用的时区

timedatectl list-timezones
# 亚洲
timedatectl list-timezones |  grep  -E "Asia/S.*"
4.设置时区

timedatectl set-timezone Asia/Shanghai
5.设置硬件时间

# 硬件时间默认为UTC
timedatectl set-local-rtc 1
# hwclock --systohc --localtime
# 两条命令效果等同
6.启用时间同步

timedatectl set-ntp yes
# yes或no; 1或0也可以
3. Chrony 服务
Chrony是网络时间协议的 (NTP) 的另一种实现，由两个程序组成，分别是chronyd和chronyc。

chronyd是一个后台运行的守护进程，用于调整内核中运行的系统时钟和时钟服务器同步。它确定计算机增减时间的比率，并对此进行补偿。

chronyc提供了一个用户界面，用于监控性能并进行多样化的配置。它可以在chronyd实例控制的计算机上工作，也可以在一台不同的远程计算机上工作。

优势：

更快的同步只需要数分钟而非数小时时间，从而最大程度减少了时间和频率误差，这对于并非全天 24 小时运行的台式计算机或系统而言非常有用。
能够更好地响应时钟频率的快速变化，这对于具备不稳定时钟的虚拟机或导致时钟频率发生变化的节能技术而言非常有用。
在初始同步后，它不会停止时钟，以防对需要系统时间保持单调的应用程序造成影响。
在应对临时非对称延迟时（例如，在大规模下载造成链接饱和时）提供了更好的稳定性。
无需对服务器进行定期轮询，因此具备间歇性网络连接的系统仍然可以快速同步时钟。
在CentOS7下为标配的时间同步服务，当然也可以使用以前的NTP同步方式，不过要安装NTP服务。

3.1 安装使用
```
yum install chrony
systemctl start chronyd
systemctl enable chronyd
```
3.2 配置文件
当Chrony启动时，它会读取/etc/chrony.conf配置文件中的设置。也就是锁，如果需要更改时间同步的服务器，修改此配置文件即可。
```
[root@localhost ~]# grep -Ev "^$|^#" /etc/chrony.conf
# 该参数可以多次用于添加时钟服务器，必须以"server "格式使用。一般而言，你想添加多少服务器，就可以添加多少服务器。
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst
# stratumweight指令设置当chronyd从可用源中选择同步源时，每个层应该添加多少距离到同步距离。默认情况下，设置为0，让chronyd在选择源时忽略源的层级。
stratumweight 0
# chronyd程序的主要行为之一，就是根据实际时间计算出计算机增减时间的比率，将它记录到一个文件中是最合理的，它会在重启后为系统时钟作出补偿，甚至可能的话，会从时钟服务器获得较好的估值。
driftfile /var/lib/chrony/drift
# rtcsync指令将启用一个内核模式，在该模式中，系统时间每11分钟会拷贝到实时时钟（RTC）。
rtcsync
# 通常，chronyd将根据需求通过减慢或加速时钟，使得系统逐步纠正所有时间偏差。在某些特定情况下，系统时钟可能会漂移过快，导致该调整过程消耗很长的时间来纠正系统时钟。
# 该指令强制chronyd在调整期大于某个阀值时步进调整系统时钟，但只有在因为chronyd启动时间超过指定限制（可使用负值来禁用限制），没有更多时钟更新时才生效。
makestep 10 3
# 这里你可以指定一台主机、子网，或者网络以允许或拒绝NTP连接到扮演时钟服务器的机器。
#allow 192.168/16
# 该指令允许你限制chronyd监听哪个网络接口的命令包（由chronyc执行）。该指令通过cmddeny机制提供了一个除上述限制以外可用的额外的访问控制等级。
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
# 指定了/etc/chrony.keys中哪一条密码被使用
commandkey 1
# 此参数指定了产生一个SHA1或MD5加密的密码，存放在/etc/chrony.keys中
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
```
/etc/chrony.keys文件
```
[root@localhost ~]#  cat /etc/chrony.keys
```
#1 a_key

1 SHA1 HEX:8B96920E9C83612FE34A8C281C31310BD2E1F624
内容来自 RHEL7 -- 使用Chrony设置时间与时钟服务器同步

3.3 chronyc
1.查看帮助
```
[root@localhost ~]# chronyc --help
```
Usage: chronyc [-h HOST] [-p PORT] [-n] [-4|-6] [-a] [-f FILE] [-m] [COMMAND]
2.查看详细的帮助信息
```
[root@localhost ~]# chronyc
```
chrony version 2.1.1
Copyright (C) 1997-2003, 2007, 2009-2015 Richard P. Curnow and others
chrony comes with ABSOLUTELY NO WARRANTY.  This is free software, and
you are welcome to redistribute it under certain conditions.  See the
GNU General Public License version 2 for details.

chronyc> help
Commands:
accheck <address> : Check whether NTP access is allowed to <address>
activity : Check how many NTP sources are online/offline
add peer <address> ... : Add a new NTP peer
add server <address> ... : Add a new NTP server
allow [<subnet-addr>] : Allow NTP access to that subnet as a default
allow all [<subnet-addr>] : Allow NTP access to that subnet and all children
burst <n-good>/<n-max> [<mask>/<masked-address>] : Start a rapid set of measurements
clients : Report on clients that have accessed the server
cmdaccheck <address> : Check whether command access is allowed to <address>
cmdallow [<subnet-addr>] : Allow command access to that subnet as a default
cmdallow all [<subnet-addr>] : Allow command access to that subnet and all children
cmddeny [<subnet-addr>] : Deny command access to that subnet as a default
cmddeny all [<subnet-addr>] : Deny command access to that subnet and all children
cyclelogs : Close and re-open logs files
delete <address> : Remove an NTP server or peer
deny [<subnet-addr>] : Deny NTP access to that subnet as a default
deny all [<subnet-addr>] : Deny NTP access to that subnet and all children
dump : Dump all measurements to save files
local off : Disable server capability for unsynchronised clock
local stratum <stratum> : Enable server capability for unsynchronised clock
makestep [<threshold> <updates>] : Correct clock by stepping
manual off|on|reset : Disable/enable/reset settime command and statistics
manual list : Show previous settime entries
maxdelay <address> <new-max-delay> : Modify maximum round-trip valid sample delay for source
maxdelayratio <address> <new-max-ratio> : Modify max round-trip delay ratio for source
maxdelaydevratio <address> <new-max-ratio> : Modify max round-trip delay dev ratio for source
maxpoll <address> <new-maxpoll> : Modify maximum polling interval of source
maxupdateskew <new-max-skew> : Modify maximum skew for a clock frequency update to be made
minpoll <address> <new-minpoll> : Modify minimum polling interval of source
minstratum <address> <new-min-stratum> : Modify minimum stratum of source
offline [<mask>/<masked-address>] : Set sources in subnet to offline status
online [<mask>/<masked-address>] : Set sources in subnet to online status
password [<new-password>] : Set command authentication password
polltarget <address> <new-poll-target> : Modify poll target of source
reselect : Reselect synchronisation source
rtcdata : Print current RTC performance parameters
settime <date/time (e.g. Nov 21, 1997 16:30:05 or 16:30:05)> : Manually set the daemon time
smoothing : Display current time smoothing state
smoothtime reset|activate : Reset/activate time smoothing
sources [-v] : Display information about current sources
sourcestats [-v] : Display estimation information about current sources
tracking : Display system time information
trimrtc : Correct RTC relative to system clock
waitsync [max-tries [max-correction [max-skew]]] : Wait until synchronised
writertc : Save RTC parameters to file

authhash <name>: Set command authentication hash function
dns -n|+n : Disable/enable resolving IP addresses to hostnames
dns -4|-6|-46 : Resolve hostnames only to IPv4/IPv6/both addresses
timeout <milliseconds> : Set initial response timeout
retries <n> : Set maximum number of retries
exit|quit : Leave the program
help : Generate this help

chronyc> quit
3.常用命令

accheck 检查NTP访问是否对特定主机可用
activity 该命令会显示有多少NTP源在线/离线
add server 手动添加一台新的NTP服务器
clients 在客户端报告已访问到服务器
delete 手动移除NTP服务器或对等服务器
settime 手动设置守护进程时间
tracking 显示系统时间信息
示例：查看时间同步的信息来源
```
[root@localhost ~]# chronyc sources
```
210 Number of sources = 3
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^+ 202.118.1.130                 2   6    37   104  +2189us[  +23ms] +/-   27ms
^* dns1.synet.edu.cn             2   6    77    40   +626us[  +21ms] +/-   33ms
^? 2001:da8:9000::81             0   6     0   10y     +0ns[   +0ns] +/-    0ns
sources可以加-v参数查看状态信息的说明
```
[root@localhost ~]# chronyc sources -v
```
210 Number of sources = 3

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
| /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^+ 202.118.1.130                 2   6    37   126  +2189us[  +23ms] +/-   27ms
^* dns1.synet.edu.cn             2   6    77    61   +626us[  +21ms] +/-   33ms
^? 2001:da8:9000::81             0   6     0   10y     +0ns[   +0ns] +/-    0ns
4.chronyc在桌面版提供用户界面，需要通过以下命令安装
```
yum -y install system-config-date
```
4. 实例
4.1 设置系统时间为中国时区并启用时间同步
# 安装
```
yum install chrony
```
# 启用
```
systemctl start chronyd
systemctl enable chronyd
```
# 设置亚洲时区
```
timedatectl set-timezone Asia/Shanghai
```
# 启用NTP同步
```
timedatectl set-ntp yes
```
这样服务器的时间就跟NTP服务器同步了，非常简单的操作。

也可以不使用Chrony，用NTP服务的时间同步。但不推荐。

4.2 安装NTP服务使用其同步时间
# 安装ntp服务
```
yum install ntp
```
# 开机启动服务
```
systemctl enable ntpd
```
# 启动服务
```
systemctl start ntpd
```
# 设置亚洲时区
```
timedatectl set-timezone Asia/Shanghai
# 启用NTP同步
```
timedatectl set-ntp yes
```
# 重启ntp服务
```
systemctl restart ntpd
```
# 手动同步时间
```
ntpq -p
```
5.4.3 RTC设为本地时间会有告警
```
[root@localhost ~]# timedatectl set-local-rtc 1
[root@localhost ~]# timedatectl
      Local time: Thu 2016-05-26 15:31:59 CST
  Universal time: Thu 2016-05-26 07:31:59 UTC
        RTC time: Thu 2016-05-26 15:31:59
       Time zone: Asia/Shanghai (CST, +0800)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: yes
      DST active: n/a

Warning: The system is configured to read the RTC time in the local time zone.
         This mode can not be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.
```
因为硬件时钟不能保存时区和夏令时调整，修改后就无法从硬件时钟中读取出准确标准时间；不建议修改。
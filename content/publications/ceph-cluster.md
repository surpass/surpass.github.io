---
title: "使用ceph-deploy 2.0.0 部署ceph "
date: 2018-09-27T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "使用ceph-deploy 2.0.0 部署ceph ."
tags: ["DevOps","Cluster FS","Continuous Integration","Continuous Delivery","CI/CD pipelines","docker","agile","Culture"]
image: "/img/ceph/ceph.jpg"
link: "https://ceph.com"
fact: "使用ceph-deploy 2.0.0 部署ceph 。"
weight: 400
sitemap:
  priority : 0.8
---


OpenShift Origin  3.9.0手动单机安装

1.环境

1.1 硬件
6台 Linux虚拟机： server0, server1, server2, server3 , server4, server5
每台有两块磁盘 ： /dev/vdb, /dev/vdc 
每台有一块网卡 ：eth0

1.2 软件
linux版本： CentOS 7.2.1511 
内核版本 ： 3.10.0-327.el7.x86_64 
ceph版本： 13.2.2 
ceph-deploy版本： 2.0.0

2.准备工作(所有server)

2.1 配置静态IP 

10.3.14.0/24  


2.2 生成ssh key

```
# ssh-keygen
```
2.3 配置主机名解析
把如下内容追加到/etc/hosts:

10.3.14.19 server0 deploy
10.3.14.20 server1
10.3.14.12 server2
10.3.14.13 server3

修改所有节点的主机名，方法如下：
sudo hostnamectl set-hostname server0


2.4.添加用户
下一件要做的就是，让添加部署的时候要用的用户了。在每个节点都执行：

sudo useradd -d /data/devops -m devops
sudo echo "devops ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devops
sudo chmod 0440 /etc/sudoers.d/devops
sudo passwd devops

 

2.5.无密码 ssh 登录
添加部署节点 deploy 对 node 的无密码 ssh 登录，以搭建 Ansible 然后可以批量对 node 执行操作。在 deploy 执行：

```
su devops
ssh-keygen
cat /data/devops/.ssh/id_rsa.pub
```

三下回车生成密钥对，然后拷贝 /data/devops/.ssh/id_rsa.pub 文件的内容到各个 node 节点：
```
scp -P7777 /data/devops/.ssh/id_rsa.pub devops@server0:/data/devops/.ssh/authorized_keys
su test
mkdir ~/.ssh
vi ~/.ssh/authorized_keys
sudo chmod 600 ~/.ssh/authorized_keys
```
在server0中编辑 ~/.ssh/config 文件：
```
Host server0
User devops
Port 7777

Host server1
User devops
Port 7777

Host server2
User devops
Port 7777

Host server3
User devops
Port 7777
```

sudo chmod 600 .ssh/config


3.安装 Ansible

以下操作无特殊说明都在 deploy 节点进行操作。

3.1. 从包管理工具安装
sudo yum -y update && sudo yum -y install ansible

3.2. 修改 Ansible 配置文件
在 /etc/ansible/hosts 文件加入：
```
[ceph-deploy]
localhost  ansible_connection=local


[ceph-node]
server1
server2
server3
```

3.3. 验证&&测试：
ansible all -m ping
结果如下：

[devops@node-19 .ssh]$ ansible all -m ping
server1 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
localhost | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
server2 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
server3 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}



4.Ceph deploy 节点安装

4.1. 从包管理工具安装
添加国内源
sudo vi  /etc/yum.repos.d/ceph.repo

[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.163.com/ceph/rpm-mimic/el7/$basearch
enabled=1
priority=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.163.com/ceph/rpm-mimic/el7/noarch
enabled=1
priority=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.163.com/ceph/rpm-mimic/el7/SRPMS
enabled=0
priority=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

4.2安装：

sudo yum -y update && sudo yum -y install ceph-deploy

5.Ceph 节点安装准备

5.1. 安装 ntp
修改时区：

ansible all -a "sudo timedatectl set-timezone Asia/Shanghai" --sudo


建议在所有 Ceph 节点上安装 NTP 服务（特别是 Ceph Monitor 节点），并跟同一个 ntp 服务器进行时间同步，以免因时钟漂移导致故障：

ansible all -a   "sudo yum -y update" --sudo
ansible all -a   "sudo yum -y install ntp " --sudo

编辑 ntp 配置文件：

vi ntp.conf

restrict cn.pool.ntp.org
server cn.pool.ntp.org

分发，重启服务：

ansible all -m copy -a "src=/etc/ntp.conf dest=/etc/ntp.conf" --sudo
ansible all -a "sudo systemctl restart ntpd" --sudo 

5.2. 安装依赖
安装 python：

ansible all -a "sudo yum -y install python -y" --sudo
开放端口
ansible all -a "sudo firewall-cmd --permanent --add-port=6789/tcp" --sudo 
ansible all -a "sudo firewall-cmd --permanent --add-port=6800-7300/tcp" --sudo 
ansible all -a "sudo firewall-cmd --reload" --sudo

3.安装依赖
ansible all -a "sudo yum install -y yum-utils " --sudo
ansible all -a "sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ " --sudo
ansible all -a "sudo yum install --nogpgcheck -y epel-release " --sudo
ansible all -a "sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 " --sudo
ansible all -a "sudo rm -f /etc/yum.repos.d/dl.fedoraproject.org* " --sudo

ansible all -a "sudo yum install redhat-lsb  -y " --sudo

6.ceph-mon 安装

6.1. 添加 mon 节点
cd /data/devops/
mkdir ceph-cluster && cd ceph-cluster

ceph-deploy new server1 server2 server3 server4 server5

ceph-deploy new server0 server1 server2 

6.2. 修改配置文件
修改 ceph.conf 文件(vi /data/devops/ceph-cluster/ceph.conf)，添加：

# osd 节点个数
osd_pool_default_size = 3
# osd 节点最小个数
osd_pool_default_min_size = 1
# ceph 公共网络
public network = 10.3.14.0/24

6.3. 安装 ceph 节点
使用国内镜像源安装：

 
export CEPH_DEPLOY_REPO_URL=http://mirrors.163.com/ceph/rpm-mimic/el7
export CEPH_DEPLOY_GPG_URL=http://mirrors.163.com/ceph/keys/release.asc

ceph-deploy install  server0 server1 server2 server3 

注：如有提示“Delta RPMs disabled because /usr/bin/applydeltarpm not installed”需要在所有节点中安装以下内容：
sudo yum provides '*/applydeltarpm'
sudo yum -y install deltarpm 


ansible all -a "sudo yum provides '*/applydeltarpm' " --sudo
ansible all -a "sudo yum -y install deltarpm " --sudo 



6.4. 初始化 mon 节点
ceph-deploy mon create-initial

如果有重复安装时用ceph-deploy --overwrite-conf mon create-initial

ceph-deploy admin server1 server2 server3 server4 server5

7.ceph osd 节点安装

7.1. 查看集群 uuid
集群的 uuid 就是这个 ceph 集群的唯一标识，后面要用：

 cat /etc/ceph/ceph.conf 
[global]
fsid = 9d21dbff-dcf3-41d0-88a9-10bbdefde284
mon_initial_members = server0, server1, server2
mon_host = 10.3.14.19,10.3.14.20,10.3.14.12
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx



# osd 节点个数
osd_pool_default_size = 3
# osd 节点最小个数
osd_pool_default_min_size = 1
# ceph 公共网络
public network = 10.3.14.0/24



其中 9d21dbff-dcf3-41d0-88a9-10bbdefde284 就是 uuid

ansible all -a "sudo chmod +r /etc/ceph/ceph.client.admin.keyring  " --sudo


7.2. 安装 osd
ssh 到各个节点，执行以下命令：

mkdir /data/devops/osd0
sudo chown ceph: /data/devops/osd0/
sudo ceph-disk prepare --cluster ceph   --cluster-uuid 9d21dbff-dcf3-41d0-88a9-10bbdefde284 --fs-type  ext4 /data/devops/osd0/
sudo ceph-disk activate /data/devops/osd0/

以上命令是在 server1 上执行的，请将 uuid 替换成自己的，–fs-type 是 ext4，请换成自己的类型。然后将 osd0 替换掉对应节点的 osd 编号。

7.3. 查看集群健康状况
当所有节点都安装完成，可以在任一节点执行以下命令查看集群健康状况:

ceph -s

或者查看集群健康状况 
$ ceph health 
HEALTH_OK

查看集群 OSD 信息 
$ ceph osd tree 




8.清理 Ceph 安装包:

ceph-deploy purge server1 server2 server3 server4 server5
清理配置:

ceph-deploy purgedata server0 server1 server2 server3 server4 server5
ceph-deploy forgetkeys



9.问题

1：ERROR: missing keyring, cannot use cephx for authentication
解决：1.确认/etc/ceph/ceph.client.admin.keyring 是否存在，如不存在请确认hostname.修改主机名后需重新安装cehp.
			2.设置权限 sudo chmod +r /etc/ceph/ceph.client.admin.keyring 
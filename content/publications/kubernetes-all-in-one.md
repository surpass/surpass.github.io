---
title: "使用kubeadm安装k8s all-in-one单机测试环境 (版本1.11.1)"
date: 2018-09-01T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "使用kubeadm安装k8s all-in-one单机测试环境."
tags: ["DevOps","Continuous Integration","Continuous Delivery","CI/CD pipelines","docker","agile","Culture"]
image: "/img/k8s.png"
link: "https://www.kubernetes.org.cn/"
fact: "使用kubeadm安装k8s all-in-one单机测试环境"
weight: 400
sitemap:
  priority : 0.8
---


使用kubeadm安装k8s all-in-one单机测试环境

1.环境准备

 * 使用Oracle VM VirtualBox安装虚拟机

 * 配置双网卡，网卡1使用net方式;网卡2使用host-only（配置静态ip 192.168.134.0网段）;这样就可以实现虚拟机与宿主机，宿主机与虚拟机之前的通信。
 * 安装centos 7操作系统（CentOS-7-x86_64-DVD-1708.iso），最小安装版。
 * 配置国内yum源，我采用的是阿里的镜像。
 * 安装常用工具 
```
		yum install -y telnet net-tools vim wget curl lrssz git unzip
```
 * 关闭防火墙
```
	  systemctl stop firewalld && systemctl disable firewalld
```
 * 关闭selinux
```
setenforce 0
sed -i s/"SELINUX=enforcing"/"SELINUX=disabled"/g  /etc/selinux/config
sed -i s/"^SELINUXTYPE=targeted"/""/g  /etc/selinux/config
```

 * 安装docker-ce
	curl -fsSL https://get.docker.com/ | sh
 * 重启docker，配置自起
	systemctl enable docker && systemctl start docker
 * 配置系统参数
```
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
```
 * 关闭swap
		swapoff -a && sysctl -w vm.swappiness=0
		vim /etc/fstab
		修改 /etc/fstab 文件，注释掉 SWAP 的自动挂载，使用free -m确认swap已经关闭
 * 安装k8s前重起一次操作，以验证以上配置是否完全生效。(可选)
		reboot

 



2.安装kubelet，kubectl，kubeadm，kubernetes-cni

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF
yum -y install epel-release
yum clean all
yum makecache
yum -y install kubelet kubeadm kubectl kubernetes-cni

systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet

```
3.上传镜像并导入到本地镜像库中。
由于网络原因访问不到k8s.gcr.io，采用先载然后导入到本地镜像库。

4.kubeadm安装k8s
```
kubeadm init --kubernetes-version=v1.11.0 --pod-network-cidr=10.244.0.0/16

```
滚动日志，直到有以下类似内容出现：
```

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.134.3:6443 --token hro1kc.upqh2abab12pfd0o --discovery-token-ca-cert-hash sha256:3f843b4ccb23c0e0d54b5e454d2404323e863c7e065aa20e042d386b31a271be
```

5.复制配置信息到root用户下
```
mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

6.master节点负载node
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

7.安装 flannel
```
mkdir -p /etc/cni/net.d/

cat <<EOF> /etc/cni/net.d/10-flannel.conf
{
“name”: “cbr0”,
“type”: “flannel”,
“delegate”: {
“isDefaultGateway”: true
}
}
EOF

mkdir /usr/share/oci-umount/oci-umount.d -p
mkdir /run/flannel/
cat <<EOF> /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.0/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```
8.安装dashboard
直接在线安装
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.0/src/deploy/recommended/kubernetes-dashboard.yaml
先下载后安装
	到https://github.com/kubernetes/dashboard/releases下载指定版本的kubernetes-dashboard.yaml文件，上传到服务器
	kubectl apply -f /home/beyond/kubernetes-dashboard.yaml 
	
	

9.查看运行端口
```
kubectl describe --namespace kube-system service kubernetes-dashboard
```
10.获取令牌
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```
11.安装heapster
```
git clone https://github.com/dolphintwo/k8s-manual-files.git
cd  k8s-manual-files/addons
kubectl create -f kube-heapster/influxdb/
kubectl create -f kube-heapster/rbac/
kubectl get pods --all-namespaces
```
重启dashboard即可见
访问地址：
https://192.168.134.3:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

12.常用的命令

查看指定pod详情
```
kubectl describe pod  -n=kube-system   pod_name
```
查看某命名空间下的pods，-n指定的命名空间名
kubectl get pods -n=kube-system


查看日志
```
kubectl logs -n=kube-system -f --tail=10 pod_name 
```




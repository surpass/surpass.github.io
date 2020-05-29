---
title: "使用kubeadm在Centos7.6上部署kubernetes1.18"
date: 2020-05-29T14:56:26+08:00
pubtype: "Talk"
featured: true
description: "使用kubeadm安装k8s all-in-one单机测试环境."
tags: ["DevOps","kubernates","Continuous Delivery","CI/CD pipelines","docker","agile","Culture"]
image: "/img/k8s.png"
link: "https://www.kubernetes.org.cn/"
fact: "使用kubeadm安装kubernetes1.18单机测试环境"
weight: 400
sitemap:
  priority : 0.8
---

# [使用kubeadm在Centos7.6上部署kubernetes1.18](https://www.kubernetes.org.cn/7189.html)

虚拟机：Oracle VM VirtualBox

OS：Centos7.6系统。

kubernetes1.18

### 1 系统准备

查看系统版本

```
[root@localhost]# cat /etc/centos-release
CentOS Linux release 7.6.1810 (Core) 
```

配置网络

```
[root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp0s8
UUID=a97ef2d6-9c96-4e2b-9d38-40d7efc4a0da
DEVICE=enp0s8
ONBOOT=yes
IPADDR="192.168.139.6"
NETMASK="255.255.255.0"
GATEWAY="192.168.139.1
```

添加阿里源

```
[root@localhost ~]# rm -rfv /etc/yum.repos.d/*
[root@localhost ~]# curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
```

配置主机名

```
[root@antsdb-server ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.139.6   antsdb-server  nosql-node1
```

关闭swap，注释swap分区

```
[root@antsdb-server ~]# swapoff -a
[root@antsdb-server ~]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sun May  5 23:57:46 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/centos-root /                       xfs     defaults        0 0
UUID=c4cd5a1b-c77c-474a-a686-96f72983e4f3 /boot                   xfs     defaults        0 0
##/dev/mapper/centos-swap swap                    swap    defaults        0 0
/dev/vg0/lv1          /data  btrfs    defaults        0 0

```

配置内核参数，将桥接的IPv4流量传递到iptables的链

```
[root@antsdb-server ~]# cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

### 2 安装常用包

```
[root@antsdb-server ~]# yum install vim bash-completion net-tools gcc -y
```

### 3 使用aliyun源安装docker-ce

```
[root@antsdb-server ~]# yum install -y yum-utils device-mapper-persistent-data lvm2
[root@antsdb-server ~]# yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
[root@antsdb-server ~]# yum -y install docker-ce
```

然后再安装docker-ce即可成功
添加aliyundocker仓库加速器

```
[root@antsdb-server ~]# mkdir -p /etc/docker
[root@antsdb-server ~]# tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://fl791z1h.mirror.aliyuncs.com"]
}
EOF
[root@antsdb-server ~]# systemctl daemon-reload
[root@antsdb-server ~]# systemctl restart docker
```

### 4 安装kubectl、kubelet、kubeadm

添加阿里kubernetes源

```
[root@antsdb-server ~]# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

安装

```
[root@antsdb-server ~]# yum install kubectl kubelet kubeadm
[root@antsdb-server ~]# systemctl enable kubelet
```

### 5 初始化k8s集群

```
[root@antsdb-server ~]# kubeadm init --kubernetes-version=1.18.0  \
--apiserver-advertise-address=192.168.139.6   \
--image-repository registry.aliyuncs.com/google_containers  \
--service-cidr=10.10.0.0/16 --pod-network-cidr=192.168.139.0/24
```

POD的网段为: 192.168.139.0/24， api server地址就是master本机IP。

这一步很关键，由于kubeadm 默认从官网k8s.grc.io下载所需镜像，国内无法访问，因此需要通过–image-repository指定阿里云镜像仓库地址。

集群初始化成功后返回如下信息：

```
...

[bootstrap-token] Using token: zxwif9.z44fm3qcs2980btk
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.139.6:6443 --token zxwif9.z44fm3qcs2980btk \
    --discovery-token-ca-cert-hash sha256:3b378b1f9a9fc2348266e0f7842d2ed03f7d35cc0f583f1d21ca9e261ef24e07 
```

记录生成的最后部分内容，此内容需要在其它节点加入Kubernetes集群时执行。
根据提示创建kubectl

```
[root@antsdb-server ~]#  mkdir -p $HOME/.kube
[root@antsdb-server ~]# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@antsdb-server ~]#   sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

执行下面命令，使kubectl可以自动补充

```
[root@antsdb-server ~]# source <(kubectl completion bash)
```

查看节点，pod

```
[root@antsdb-server ~]# kubectl get node
NAME                STATUS     ROLES    AGE     VERSION
antsdb-server   Ready    master   3m29s   v1.18.3
[root@antsdb-server ~]# kubectl get pod --all-namespaces
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE
kube-system   coredns-7ff77c879f-fsj9l                    0/1     Pending   0          4m12s
kube-system   coredns-7ff77c879f-q5ll2                    0/1     Pending   0          4m12s
kube-system   etcd-antsdb-server                      1/1     Running   0          4m22s
kube-system   kube-apiserver-antsdb-server            1/1     Running   0          4m22s
kube-system   kube-controller-manager-antsdb-server   1/1     Running   0          4m22s
kube-system   kube-proxy-n89f8                            1/1     Running   0          4m12s
kube-system   kube-scheduler-antsdb-server            1/1     Running   0          4m22s
[root@antsdb-server ~]#
```

node节点为NotReady，因为corednspod没有启动，缺少网络pod

### 6 安装calico网络

```
[root@antsdb-server ~]# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
```

查看pod和node

```
[root@antsdb-server ~]# kubectl get pod --all-namespaces
NAMESPACE     NAME                                        READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-555fc8cc5c-k8rbk    1/1     Running   0          36s
kube-system   calico-node-5km27                           1/1     Running   0          36s
kube-system   coredns-7ff77c879f-fsj9l                    1/1     Running   0          5m22s
kube-system   coredns-7ff77c879f-q5ll2                    1/1     Running   0          5m22s
kube-system   etcd-antsdb-server                      1/1     Running   0          5m32s
kube-system   kube-apiserver-antsdb-server            1/1     Running   0          5m32s
kube-system   kube-controller-manager-antsdb-server   1/1     Running   0          5m32s
kube-system   kube-proxy-n89f8                            1/1     Running   0          5m22s
kube-system   kube-scheduler-antsdb-server            1/1     Running   0          5m32s
[root@antsdb-server ~]# kubectl get node
NAME                STATUS   ROLES    AGE     VERSION
antsdb-server.paas.com   Ready    master   5m47s   v1.18.0
[root@antsdb-server ~]#
```

此时集群状态正常

### 7 安装kubernetes-dashboard

官方部署dashboard的服务没使用nodeport，将yaml文件下载到本地，在service里添加nodeport

```
[root@antsdb-server ~]# wget  https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml
[root@antsdb-server ~]# vim recommended.yaml
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30000
  selector:
    k8s-app: kubernetes-dashboard

[root@antsdb-server ~]# kubectl create -f recommended.yaml
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

查看pod，service

```
[root@antsdb-server ~]# kubectl get  pod -n kubernetes-dashboard
NAME                                        READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-dc6947fbf-869kf   1/1     Running   0          37s
kubernetes-dashboard-5d4dc8b976-sdxxt       1/1     Running   0          37s
[root@antsdb-server ~]# kubectl get svc -n kubernetes-dashboard
NAME                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.10.123.195    <none>        8000/TCP        44s
kubernetes-dashboard        NodePort    10.10.27.4   <none>        443:30000/TCP   44s
[root@antsdb-server ~]#
```

通过页面访问，推荐使用firefox浏览器
![使用kubeadm在Centos8上部署kubernetnes1.18] 
https://192.168.139.6:3000
显示登录页面
(/img/k8s-login.png)
使用token进行登录，执行下面命令获取token

```
[root@antsdb-server k8s]# kubectl get secrets -n kubernetes-dashboard 
NAME                               TYPE                                  DATA   AGE
default-token-g6mrp                kubernetes.io/service-account-token   3      15m32s
kubernetes-dashboard-certs         Opaque                                0      15m32s
kubernetes-dashboard-csrf          Opaque                                1      15m32s
kubernetes-dashboard-key-holder    Opaque                                2      15m32s
kubernetes-dashboard-token-fgf5n   kubernetes.io/service-account-token   3      3h28m


[root@antsdb-server ~]# kubectl describe secrets -n kubernetes-dashboard kubernetes-dashboard-token-fgf5n  | grep token | awk 'NR==3{print $2}'
eyJhbGciOiJSUzI1NiIsImtpZCI6Ikp3MDIzZWtpcWN5aTh0cU8yUngxSTlYX2ZwZ1FpVnV5VGhkdUFCWlRySmMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC10b2tlbi1mZ2Y1biIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjVlOTYwNTFkLWQ5NzQtNDkyNi1iYzVjLTA0YzUxOGJiZTlmZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDprdWJlcm5ldGVzLWRhc2hib2FyZCJ9.ua4ThU-nvpl73Ftrqe8TuCnb90nhKTIDwscs3P8LyQYPnIau528RMy_iLKk-KqC2SGQPQjrj4sdMe7Cb9tfaLXtUym5zj7fwVWWQwiIxNlAPUC24WoJXQjhFq_yNUNt1XgR6b17e9hifvvYRdO4WaLrSqRwpRduDMwjbsvOQOShCKgsvJDgElnBLT_hYFzDI5ckK7O-Bmajc8j0Vw6k_9ZcVHPlXBcthF4gIVcYzd7XKo1X314o78SZQWpWQRhl9Bn9jEyIhonrP8l0CheWbOFL2awE3M0aUwruPkllB1NVBPyuudeuVPQPzLzCY_KAegVTtTtXMjw41pqjUlwZMow
```

登录后如下展示，如果没有namespace可选，并且提示找不到资源 ，那么就是权限问题
![使用kubeadm在Centos8上部署kubernetnes1.18]
通过查看dashboard日志，得到如下 信息

```
[root@antsdb-server ~]# kubectl logs -f -n kubernetes-dashboard kubernetes-dashboard-5d4dc8b976-skt8b
 
```

解决方法

```
[root@antsdb-server ~]# kubectl create clusterrolebinding serviceaccount-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccount 
clusterrolebinding.rbac.authorization.k8s.io/serviceaccount-cluster-admin created
```

查看dashboard日志

```
[root@antsdb-server ~]# kubectl logs -f -n kubernetes-dashboard kubernetes-dashboard-5d4dc8b976-skt8b
 
```

此时再查看dashboard，即可看到有资源展示
![img]( /img/k8s-dashboard.png)

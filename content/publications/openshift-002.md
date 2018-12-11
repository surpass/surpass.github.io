---
title: "OpenShift Origin  3.9.0手动单机安装"
date: 2018-06-15T21:56:26+08:00
pubtype: "Talk"
featured: true
description: "OpenShift Origin  3.9.0手动单机安装."
tags: ["DevOps","Continuous Integration","Continuous Delivery","CI/CD pipelines","docker","agile","Culture"]
image: "/img/openshift.jpg"
link: "https://www.openshift.com"
fact: "OpenShift是红帽的云开发平台即服务（PaaS）。自由和开放源码的云计算平台使开发人员能够创建、测试和运行他们的应用程序，并且可以把它们部署到云中。"
weight: 400
sitemap:
  priority : 0.8
---



[OSEv3:children]
masters
nodes
etcd
nfs

[OSEv3:vars]
ansible_ssh_user=devops
openshift_deployment_type=origin
#因采用虚拟机部署学习 配置此选项跳过主机硬件信息检查
openshift_disable_check=disk_availability,docker_storage,memory_availability,docker_image_availability
openshift_master_identity_providers=[{'name':'htpasswd_auth','login':'true','challenge':'true','kind':'HTPasswdPasswordIdentityProvider',}]

openshift_master_default_subdomain=okd.easyolap.cn
openshift_deployment_type=origin
os_firewall_use_firewalld=true

[masters]
server0

[etcd]
server0

[nodes]
server1 openshift_node_group_name='node-config-master'
server2 openshift_node_group_name='node-config-compute'
server3 openshift_node_group_name='node-config-compute'

[nfs]
server0


安装docker
sudo curl -fsSL https://get.docker.com/ | sh




问题 ：fatal: [server0]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host server0 port 22: Connection refused\r\n", "unreachable": true}
解决  sudo ansible-playbook openshift-ansible/playbooks/prerequisites.yml  --limit @/data/devops/openshift-ansible/playbooks/prerequisites.retry


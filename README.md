 

# Kubernates

[安装前准备](#table1)   

[kubeadm部署](#table2)   

[二进制部署](#table3)  



## 一、K8S概述

## 二、K8S快速入门

## 三、k8s的安装部署

### 1. 安装要求

在开始之前，部署Kubernetes集群机器需要满足以下几个条件：

- 一台或多台机器，操作系统 CentOS7.x-86_x64
- 硬件配置：2GB或更多RAM，2个CPU或更多CPU，硬盘30GB或更多
- 集群中所有机器之间网络互通
- 可以访问外网，需要拉取镜像
- 禁止swap分区

### 2. 准备环境

单Master架构图

 ![kubernetesæ¶æå¾](https://blog-1252881505.cos.ap-beijing.myqcloud.com/k8s/single-master.jpg) 

| 角色       | IP              |
| ---------- | --------------- |
| k8s-master | 192.168.159.143 |
| k8s-node1  | 192.168.159.144 |
| k8s-node2  | 192.168.159.145 |

​	<a id="table1">升级centos内核：</a>

```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org  #导入ELRepo仓库的公共密钥
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm  #安装ELRepo仓库的yum源
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available  #查看可用的系统内核包
yum --enablerepo=elrepo-kernel install kernel-ml  #安装最新版本内核
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg  #生成 grub 配置文件并重启
reboot
```

​	配置yum源和epel源：

```shell
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
yum -y install epel-release
```



​	关闭防火墙：

```shell
systemctl stop firewalld
systemctl disable firewalld
```

​	关闭selinux：

```shell
sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久,进入后注释掉有swap的那一行
setenforce 0  # 临时
```

​	关闭swap：

```shell
swapoff -a  # 临时
vim /etc/fstab  # 永久
```

​	设置主机名：

```shell
hostnamectl set-hostname <hostname>
```

​	在master添加hosts：      node节点可以不需要添加hosts

```shell
cat >> /etc/hosts << EOF
192.168.159.143 k8s-master
192.168.159.144 k8s-node1
192.168.159.145 k8s-node2
EOF
```

​	将桥接的IPv4流量传递到iptables的链：

```shell
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system  # 生效
```

​	时间同步：    必须要同步才行

```shell
yum install ntpdate -y
ntpdate time.windows.com
```

​	配置静态ip地址

```shell
ifconfig   #查看IP地址


vim /etc/sysconfig/network-scripts/ifcfg-ens33 
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="static"    #这里要修改为static   
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens33"
UUID="cd4ce59b-0bcf-42b8-ab7d-312644bb46f3"
DEVICE="ens33"
ONBOOT="yes"
IPADDR="192.168.159.143"    #从这一行开始都是要添加的，这里添加上述查看到的ip地址
PREFIX="24"
GATEWAY="192.168.159.2"
DNS1="202.119.248.66"   #我这里是我学校的DNS，你可以自己选择一个公有DNS
```

​	重启网络服务

```shell
systemctl restart network
ping www.baidu.com
```



### 	(一)使用minikube（很小，仅供学习用，不是用于生产）

​		可以在官网上下载使用

### <a id="table2">(二)、使用kubeadmin安装部署(版本可依据个人情况，本文使用的是1.20.0)</a>

kubeadm是官方社区推出的一个用于快速部署kubernetes集群的工具。

这个工具能通过两条指令完成一个kubernetes集群的部署：

```shell
# 创建一个 Master 节点
$ kubeadm init

# 将一个 Node 节点加入到当前集群中
$ kubeadm join <Master节点的IP和端口 >
```

#### 1. 安装Docker/kubeadm/kubelet【所有节点】

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。

##### 1.1 安装Docker（注意版本与Kubernetes版本的兼容性）

```shell
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum install -y docker-ce-19.03.5-3.el7 docker-ce-cli-19.03.5-3.el7 containerd.io
systemctl enable docker && systemctl start docker
```

配置镜像下载加速器：

```shell
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://tzksttqp.mirror.aliyuncs.com"]
}
EOF

vim /usr/lib/systemd/system/docker.service
#在ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock  这一行添加 --exec-opt native.cgroupdriver=systemd  参数


systemctl daemon-reload &&  systemctl restart docker


docker info | grep Cgroup   #查看docker的 cgroup driver
```

##### 1.2 添加阿里云YUM软件源，为了能够下载kubeadm、kubelet和kubectl

```shell
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

##### 1.3 安装kubeadm，kubelet和kubectl

由于版本更新频繁，这里可以指定版本号部署：（不指定即下载最新版本），这里使用的是1.20版本

```shell
yum install -y kubelet-1.20.0 kubeadm-1.20.0 kubectl-1.20.0


systemctl enable kubelet
```

#### 2. 部署Kubernetes Master

参考文档： https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file 

 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node 

在192.168.159.143（Master）执行。

```shell
kubeadm init --apiserver-advertise-address=192.168.159.143 --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.20.0 --service-cidr=10.96.0.0/12 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all
```

- --apiserver-advertise-address 集群通告地址

- --image-repository  由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址

- --kubernetes-version K8s版本，与上面kubeadm等安装的版本一致

- --service-cidr 集群内部虚拟网络，Pod统一访问入口

- --pod-network-cidr Pod网络，，与下面部署的CNI网络组件yaml中保持一致

- --ignore-preflight-errors=all   忽视一些不是很重要的警告

  

**PS：可能会出现It seems like the kubelet isn't running or healthy的错误，此时可以参考这两篇博客：**

​	https://blog.csdn.net/boling_cavalry/article/details/91306095

​	https://blog.csdn.net/weixin_41298721/article/details/114916421

​	http://www.manongjc.com/detail/23-umxjtqmublnyjwl.html



或者使用配置文件引导：

```shell
vi kubeadm.conf

apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.20.0
imageRepository: registry.aliyuncs.com/google_containers 
networking:
  podSubnet: 10.244.0.0/16 
  serviceSubnet: 10.96.0.0/12 




kubeadm init --config kubeadm.conf --ignore-preflight-errors=all  
```



kubeadmin init步骤：

1、[preflight]  环境检查

2、[kubelet-start]   准备kublet配置文件并启动/var/lib/kubelet/config.yaml

3、[certs]   证书目录 /etc/kubernetes/pki

4、[kubeconfig]   kubeconfig是用于连接k8s的认证文件 

5、[control-plane]  静态pod目录  /etc/kubernetes/manifests  启动组件用的

6、[etcd]   etcd的静态pod目录

7、[upload-config]  kubeadm-config存储到kube-system的命名空间中

8、[mark-control-plane]  给master节点打污点，不让pod分配

9、[bootstrp-token]   用于引导kubernetes的证书





拷贝kubectl使用的连接k8s认证文件到默认路径：

```shell
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes

#  NAME         STATUS   ROLES    AGE   VERSION
#  k8s-master   Ready    master   2m    v1.20.0
```

#### 3. 加入Kubernetes Node

在192.168.159.144/145（Node）执行。

向集群添加新节点，执行在node结点上：

```shell
kubeadm join 192.168.159.143:6443 --token esce21.q6hetwm8si29qxwn --discovery-token-ca-cert-hash sha256:00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
```

默认token有效期为24小时，当过期之后，上述token就不可用了。这时就需要重新创建token，在master节点中操作：

```shell
kubeadm token create
kubeadm token list    
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

在node结点中使用最新的token

```shell
kubeadm join 192.168.159.143:6443 --token nuja6n.o3jrhsffiqs9swnu --discovery-token-ca-cert-hash sha256:63bca849e0e01691ae14eab449570284f0c3ddeea590f8da988c07fe2729e924
```

**PS：kubeadm token create --print-join-command        可用于生成kubeadm join命令**

<https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/>



#### 4. 部署容器网络（CNI）

 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network 

注意：只需要部署下面其中一个，推荐Calico。

##### 4.1 Calico（推荐）

Calico是一个纯三层的数据中心网络方案，Calico支持广泛的平台，包括Kubernetes、OpenStack等。

Calico 在每一个计算节点利用 Linux Kernel 实现了一个高效的虚拟路由器（ vRouter） 来负责数据转发，而每个 vRouter 通过 BGP 协议负责把自己上运行的 workload 的路由信息向整个 Calico 网络内传播。

此外，Calico  项目还实现了 Kubernetes 网络策略，提供ACL功能。

 https://docs.projectcalico.org/getting-started/kubernetes/quickstart 

```shell
wget https://docs.projectcalico.org/manifests/calico.yaml --no-check-certificate
```

下载完后还需要修改里面配置项：

- 定义Pod网络（CALICO_IPV4POOL_CIDR），与前面kubeadmin.conf文件中的podSubnet配置一样
- 选择工作模式（CALICO_IPV4POOL_IPIP），支持**BGP（Never）**、**IPIP（Always）**、**CrossSubnet**（开启BGP并支持跨子网）

修改完后应用清单：

```shell
kubectl apply -f calico.yaml


kubectl get pods -n kube-system
```

**PS：可能会出现calico pod处于not ready状态，此时可以参考这两篇博客：**

​	https://blog.csdn.net/qq_39698985/article/details/123960741

修改kube-proxy为IPVS模式：

```shell
yum install ipset -y
yum install ipvsadm -y
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
# 使用lsmod | grep -e ip_vs -e nf_conntrack_ipv4命令查看是否已经正确加载所需的内核模块。
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

kubectl edit cm kube-proxy -n kube-system   #将其中的mode=""  改为mode="ipvs"
kubectl rollout restart daemonset kube-proxy -n kube-system 
```



##### 4.2 Flannel

Flannel是CoreOS维护的一个网络组件，Flannel为每个Pod提供全局唯一的IP，Flannel使用ETCD来存储Pod子网与Node IP之间的关系。flanneld守护进程在每台主机上运行，并负责维护ETCD信息和路由数据包。

```
$ wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
$ sed -i -r "s#quay.io/coreos/flannel:.*-amd64#lizhenliang/flannel:v0.11.0-amd64#g" kube-flannel.yml
$ kubectl apply -f kube-flannel.yml
```

修改国内镜像仓库。



#### 5. 测试kubernetes集群

- 验证Pod工作
- 验证Pod网络通信
- 验证DNS解析

在Kubernetes集群中创建一个pod，验证是否正常运行：

```shell
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get pod,svc
```

访问地址：http://NodeIP:Port  



以下是测试DNS服务：

​	临时启动个pod：

```shell
kubectl run dns-test -it --rm --image=busybox:1.28.4  -- sh
```

​	进去之后ping一下外网，看看能不能ping通，再nslookup kube-dns.kube-system

​	到此，集群就搭建好了，可以开始在K8s的海洋中遨游了~





### <a id="table3">(三)、使用二进制安装部署(版本可依据个人情况，本文使用的是1.20.0)</a>

#### 1. 安装Docker【所有节点】

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。

##### 1.1 安装Docker（注意版本与Kubernetes版本的兼容性）

```shell
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum install -y docker-ce-19.03.5-3.el7 docker-ce-cli-19.03.5-3.el7 containerd.io
systemctl enable docker && systemctl start docker
```

配置镜像下载加速器：

```shell
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://tzksttqp.mirror.aliyuncs.com"]
}
EOF

vim /usr/lib/systemd/system/docker.service
#在ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock  这一行添加 --exec-opt native.cgroupdriver=systemd  参数


systemctl daemon-reload &&  systemctl restart docker


docker info | grep Cgroup   #查看docker的 cgroup driver
```

#### 2. 部署etcd集群

##### 2.1 etcd简介

Etcd 是一个分布式键值存储系统，Kubernetes使用Etcd进行数据存储，所以先准备一个Etcd数据库，为解决Etcd单点故障，应采用集群方式部署，这里使用3台组建集群，可容忍1台机器故障，当然，你也可以使用5台组建集群，可容忍2台机器故障

##### 2.2 服务器规划

| 节点名称 |       IP        |
| :------: | :-------------: |
|  etcd-1  | 192.168.159.143 |
|  etcd-2  | 192.168.159.144 |
|  etcd-3  | 192.168.159.145 |


说明:
为了节省机器,这里与k8s节点复用,也可以部署在k8s机器之外,只要apiserver能连接到就行。

##### 2.3 cfssl证书生成工具准备


cfssl是一个开源的证书管理工具，使用json文件生成证书，相比openssl更方便使用。找任意一台服务器操作，这里用k8s-master节点。

使用相关工具

```shell
./TLS/cfssl.sh
```

##### 2.4 自签证书颁发机构(CA)

###### 2.4.2 生成自签CA配置

```shell
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}

EOF

cat > ca-csr.json << EOF
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}

EOF


```

###### 2.4.3 创建证书申请文件

```shell
cat > server-csr.json << EOF
{
    "CN": "etcd",
    "hosts": [
        "192.168.159.149",
        "192.168.159.151",
        "192.168.159.152"
        ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing"
        }
    ]
}

EOF
```

说明:
上述文件hosts字段中ip为所有etcd节点的集群内部通信ip,一个都不能少,为了方便后期扩容可以多写几个预留的ip。

###### 2.4.4 生成自签CA证书，并使用自签CA签发etcd https证书

```shell
cd TLS/etcd
./generate_etcd_cert.sh
ls
```



##### 2.5下载etcd二进制文件

下载地址
https://github.com/etcd-io/etcd/releases

##### 2.6部署etcd集群

以下操作在k8s-master上面操作,为简化操作,待会将该节点生成的所有文件拷贝到其他work节点。

##### 2.7. 创建工作目录并解压二进制包，将上述创建的ssl证书拷贝到etcd的ssl目录下

```shell
mkdir /opt/etcd/{bin,cfg,ssl} -p
tar -xf etcd-v3.5.4-linux-amd64.tar.gz
mv etcd-v3.5.4-linux-amd64/{etcd,etcdctl} /opt/etcd/bin/
cp -r 前面生成的所有pem文件  /opt/etcd/ssl
```

##### 2.8 创建etcd配置文件

```shell
cat > /opt/etcd/cfg/etcd.conf << EOF
#[Member]
ETCD_NAME="etcd-1"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.159.143:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.159.143:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.159.143:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.159.143:2379"
ETCD_INITIAL_CLUSTER="etcd-1=https://192.168.159.143:2380,etcd-2=https://192.168.159.151:2380,etcd-3=https://192.168.159.152:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
```

配置说明:

ETCD_NAME： 节点名称,集群中唯一
ETCD_DATA_DIR：数据目录
ETCD_LISTEN_PEER_URLS：集群通讯监听地址
ETCD_LISTEN_CLIENT_URLS：客户端访问监听地址
ETCD_INITIAL_CLUSTER：集群节点地址
ETCD_INITIALCLUSTER_TOKEN：集群Token
ETCD_INITIALCLUSTER_STATE：加入集群的状态：new是新集群,existing表示加入已有集群

##### 2.9 systemd管理etcd

```shell
cat > /usr/lib/systemd/system/etcd.service << EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/opt/etcd/cfg/etcd.conf
ExecStart=/opt/etcd/bin/etcd \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--peer-cert-file=/opt/etcd/ssl/server.pem \
--peer-key-file=/opt/etcd/ssl/server-key.pem \
--trusted-ca-file=/opt/etcd/ssl/ca.pem \
--peer-trusted-ca-file=/opt/etcd/ssl/ca.pem \
--logger=zap
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

##### 2.10 将master1节点所有生成的文件拷贝到节点144和节点145

```shell
for i in {4..5}
do
scp -r /opt/etcd/ root@192.168.159.14$i:/opt/
scp /usr/lib/systemd/system/etcd.service root@192.168.159.14$i:/usr/lib/systemd/system/
done
```

##### 2.11 修改节点144，节点145 ,etcd.conf配置文件中的节点名称和当前服务器IP

```shell
#[Member]
ETCD_NAME="etcd-1"    #节点144修改为: etcd-2 节点145修改为: etcd-3
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.159.143:2380"  #修改为对应节点IP
ETCD_LISTEN_CLIENT_URLS="https://192.168.159.143:2379"  #修改为对应节点IP

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.159.143:2380" #修改为对应节点IP
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.159.143:2379" #修改为对应节点IP
ETCD_INITIAL_CLUSTER="etcd-1=https://192.168.159.143:2380,etcd-2=https://192.168.159.144:2380,etcd-3=https://192.168.159.145:2380"  
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
```



##### 2.12 启动etcd并设置开机自启

说明:
etcd须多个节点同时启动,不然执行systemctl start etcd会一直卡在前台,连接其他节点,建议通过批量管理工具,或者脚本同时启动etcd。

```shell
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd
```

##### 2.13 检查etcd集群状态

```shell
ETCDCTL_API=3 /opt/etcd/bin/etcdctl --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints="https://192.168.159.143:2379,https://192.168.159.144:2379,https://192.168.159.145:2379" endpoint health --write-out=table
```

​										+-----------------------------+--------+-------------+-------+
​										|          ENDPOINT           | HEALTH |    TOOK     | ERROR |
​										+-----------------------------+--------+-------------+-------+
​										| https://192.168.242.52:2379 |   true | 67.267851ms |       |
​										| https://192.168.242.51:2379 |   true | 67.374967ms |       |
​										| https://192.168.242.53:2379 |   true | 69.244918ms |       |
​											+-----------------------------+--------+-------------+-------+

如果为以上状态证明部署的没有问题



#### 3、部署Master节点

##### 3.1 生成kube-apiserver、kube-proxy、kube-scheduler、kube-controller-manager、admin证书

###### 3.1.1 生成自签CA配置

```shell
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}


EOF

cat > ca-csr.json << EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
      	    "O": "k8s",
            "OU": "System"
        }
    ]
}


EOF


```

###### 3.1.2 创建证书申请文件

```shell
cat > server-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "10.0.0.1",
      "127.0.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local",
      "192.168.159.143",
      "192.168.159.144",
      "192.168.159.145"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}


EOF


cat > kube-controller-manager-csr.json << EOF
{
    "CN": "system:kube-controller-manager",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "CN",
        "L": "BeiJing", 
        "ST": "BeiJing",
        "O": "system:masters",
        "OU": "System"
        }
    ]
}
EOF

cat > kube-scheduler-csr.json << EOF
{
    "CN": "system:kube-scheduler",
    "hosts": [],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "L": "BeiJing",
        "ST": "BeiJing",
        "O": "system:masters",
        "OU": "System"
      }
    ]
}

EOF


cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}

EOF

cat > admin-csr.json << EOF
{
    "CN": "admin",
    "hosts": [],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "L": "BeiJing",
        "ST": "BeiJing",
        "O": "system:masters",
        "OU": "System"
      }
    ]
}
EOF
```

###### 3.1.3 生成自签CA证书，并使用自签CA签发https证书

```shell
cd TLS/k8s
./generate_etcd_cert.sh
ls
```

##### 3.2 下载

下载地址:
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.20.md

##### 3.3 解压二进制包

上传刚才下载的k8s软件包到服务器上（本文下载的是1.20.15版本）

```shell
mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs} 
tar zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin
cp kube-apiserver kube-scheduler kube-controller-manager /opt/kubernetes/bin
cp kubectl /usr/bin/
```

##### 3.4 部署kube-apiserver

###### 3.4.1 创建配置文件

```shell
cat > /opt/kubernetes/cfg/kube-apiserver.conf << EOF
KUBE_APISERVER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--etcd-servers=https://192.168.159.143:2379,https://192.168.159.144:2379,https://192.168.159.145:2379 \\
--bind-address=192.168.159.143 \\
--secure-port=6443 \\
--advertise-address=192.168.159.143 \\
--allow-privileged=true \\
--service-cluster-ip-range=10.0.0.0/24 \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--enable-bootstrap-token-auth=true \\
--token-auth-file=/opt/kubernetes/cfg/token.csv \\
--service-node-port-range=30000-32767 \\
--kubelet-client-certificate=/opt/kubernetes/ssl/server.pem \\
--kubelet-client-key=/opt/kubernetes/ssl/server-key.pem \\
--tls-cert-file=/opt/kubernetes/ssl/server.pem  \\
--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \\
--client-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--service-account-issuer=api \\
--service-account-signing-key-file=/opt/kubernetes/ssl/server-key.pem \\
--etcd-cafile=/opt/etcd/ssl/ca.pem \\
--etcd-certfile=/opt/etcd/ssl/server.pem \\
--etcd-keyfile=/opt/etcd/ssl/server-key.pem \\
--requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \\
--proxy-client-cert-file=/opt/kubernetes/ssl/server.pem \\
--proxy-client-key-file=/opt/kubernetes/ssl/server-key.pem \\
--requestheader-allowed-names=kubernetes \\
--requestheader-extra-headers-prefix=X-Remote-Extra- \\
--requestheader-group-headers=X-Remote-Group \\
--requestheader-username-headers=X-Remote-User \\
--enable-aggregator-routing=true \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=3 \\
--audit-log-maxsize=100 \\
--audit-log-path=/opt/kubernetes/logs/k8s-audit.log"
EOF
```


说明:
上面两个\\第一个是转义符,第二个是换行符,使用转义符是为了使用EOF保留换行符。

--logtostderr ：启用日志
--v ：日志等级
--log-dir ：日志目录
--etcd-servers ：etcd集群地址
--bind-address ：监听地址
--secure-port ：https安全端口
--advertise-address ：集群通告地址
--allow-privileged ：启动授权
--service-cluster-ip-range ：Service虚拟IP地址段
--enable-admission-plugins ： 准入控制模块
--authorization-mode ：认证授权,启用RBAC授权和节点自管理
--enable-bootstrap-token-auth ：启用TLS bootstrap机制
--token-auth-file ：bootstrap token文件
--service-node-port-range ：Service nodeport类型默认分配端口范围
--kubelet-client-xxx ：apiserver访问kubelet客户端证书
--tls-xxx-file ：apiserver https证书
1.20版本必须加的参数：--service-account-issuer,--service-account-signing-key-file
--etcd-xxxfile ：连接etcd集群证书
--audit-log-xxx ：审计日志
启动聚合层网关配置：--requestheader-client-ca-file,--proxy-client-cert-file,--proxy-client-key-file,--requestheader-allowed-names,--requestheader-extra-headers-prefix,--requestheader-group-headers,--requestheader-username-headers,--enable-aggregator-routing

###### 3.4.2 拷贝刚才生成的证书

把刚才生成的证书拷贝到配置文件中的路径：

```shell
cp TLS/k8s/*.pem  /opt/kubernetes/ssl/
```



###### 3.4.3 启用TLS bootstrapping机制

TLS Bootstraping：Master apiserver启用TLS认证后，Node节点kubelet和kube-proxy要与kube-apiserver进行通信，必须使用CA签发的有效证书才可以，当Node节点很多时，这种客户端证书颁发需要大量工作，同样也会增加集群扩展复杂度。为了简化流程，Kubernetes引入了TLS bootstraping机制来自动颁发客户端证书，kubelet会以一个低权限用户自动向apiserver申请证书，kubelet的证书由apiserver动态签署。所以强烈建议在Node上使用这种方式，目前主要用于kubelet，kube-proxy还是由我们统一颁发一个证书。
TLS bootstraping 工作流程：







创建上述配置文件中token文件：

```shell
cat > /opt/kubernetes/cfg/token.csv << EOF
4136692876ad4b01bb9dd0988480ebba,kubelet-bootstrap,10001,"system:node-bootstrapper"
EOF
```


格式：token,用户名,UID,用户组

token也可自行生成替换：

```shell
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
```



###### 3.4.4 systemd管理apiserver

```shell
cat > /usr/lib/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-apiserver.conf
ExecStart=/opt/kubernetes/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```



###### 3.4.5 启动并设置开机启动

```shell
systemctl daemon-reload
systemctl start kube-apiserver 
systemctl enable kube-apiserver
```



##### 3.5 部署kube-controller-manager

###### 3.5.1 创建配置文件

```shell
cat > /opt/kubernetes/cfg/kube-controller-manager.conf << EOF
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--leader-elect=true \\
--kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig \\
--bind-address=127.0.0.1 \\
--allocate-node-cidrs=true \\
--cluster-cidr=10.244.0.0/16 \\
--service-cluster-ip-range=10.0.0.0/24 \\
--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \\
--root-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--cluster-signing-duration=87600h0m0s"
EOF
```

--kubeconfig ：连接apiserver配置文件。
--leader-elect ：当该组件启动多个时,自动选举(HA)
--cluster-signing-cert-file ：自动为kubelet颁发证书的CA,apiserver保持一致
--cluster-signing-key-file ：自动为kubelet颁发证书的CA,apiserver保持一致

###### 3.5.2 生成kubeconfig文件

生成kubeconfig文件(以下是shell命令,直接在shell终端执行)

```shell

cd TLS/k8s  #先进入到证书目录

KUBE_CONFIG="/opt/kubernetes/cfg/kube-controller-manager.kubeconfig"
KUBE_APISERVER="https://192.168.159.143:6443"

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-credentials kube-controller-manager \
  --client-certificate=./kube-controller-manager.pem \
  --client-key=./kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-controller-manager \
  --kubeconfig=${KUBE_CONFIG}

kubectl config use-context default --kubeconfig=${KUBE_CONFIG}
```

###### 3.5.3 systemd管理controller-manager

```shell
cat > /usr/lib/systemd/system/kube-controller-manager.service << EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-controller-manager.conf
ExecStart=/opt/kubernetes/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```



###### 3.5.4 启动并设置开机自启

```shell
systemctl daemon-reload
systemctl start kube-controller-manager
systemctl enable kube-controller-manager
```



##### 3.6 部署 kube-scheduler

###### 3.6.1 创建配置文件

```shell
cat > /opt/kubernetes/cfg/kube-scheduler.conf << EOF
KUBE_SCHEDULER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--leader-elect \\
--kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig \\
--bind-address=127.0.0.1"
EOF
```

--kubeconfig ：连接apiserver配置文件
--leader-elect ：当该组件启动多个时,自动选举(HA)。

###### 3.6.2 生成kubeconfig文件


生成kubeconfig文件 ：

```shell

cd TLS/k8s


KUBE_CONFIG="/opt/kubernetes/cfg/kube-scheduler.kubeconfig"
KUBE_APISERVER="https://192.168.159.143:6443"

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-credentials kube-scheduler \
  --client-certificate=./kube-scheduler.pem \
  --client-key=./kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-scheduler \
  --kubeconfig=${KUBE_CONFIG}

kubectl config use-context default --kubeconfig=${KUBE_CONFIG}
```



###### 3.6.3 systemd管理scheduler

```shell
cat > /usr/lib/systemd/system/kube-scheduler.service << EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-scheduler.conf
ExecStart=/opt/kubernetes/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

###### 3.6.4 启动并设置开机启动

```shell
systemctl daemon-reload
systemctl start kube-scheduler
systemctl enable kube-scheduler
```



###### 3.6.5 查看集群状态


生成kubeconfig文件 ：

```shell
mkdir /root/.kube
cd TLS/k8s/

KUBE_CONFIG="/root/.kube/config"
KUBE_APISERVER="https://192.168.159.143:6443"

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-credentials cluster-admin \
  --client-certificate=./admin.pem \
  --client-key=./admin-key.pem \
  --embed-certs=true \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-context default \
  --cluster=kubernetes \
  --user=cluster-admin \
  --kubeconfig=${KUBE_CONFIG}

kubectl config use-context default --kubeconfig=${KUBE_CONFIG}
```


通过kubectl工具查看当前集群组件状态 ：

```shell
kubectl get cs
```

​										Warning: v1 ComponentStatus is deprecated in v1.19+
​										NAME                 STATUS    MESSAGE             ERROR
​										scheduler            Healthy   ok                  
​										controller-manager   Healthy   ok                  
​										etcd-2               Healthy   {"health":"true"}   
​										etcd-0               Healthy   {"health":"true"}   
​										etcd-1               Healthy   {"health":"true"}

如上说明Master节点组件运行正常。

###### 3.6.6 授权kubelet-bootstrap用户允许请求证书

```shell
kubectl create clusterrolebinding kubelet-bootstrap \
--clusterrole=system:node-bootstrapper \
--user=kubelet-bootstrap
```

#### 4、部署Work Node

下面还是在master node上面操作,即当Master节点,也当Work Node节点

##### 4.1 创建工作目录并拷贝二进制文件

注: 在所有work node创建工作目录

```shell
mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs} 
```


从master节点k8s-server软件包中拷贝到所有work节点:

```shell
#进入到k8s-server软件包目录
cd /opt/kubernetes/server/bin/


for i in {4..5}
do
scp kubelet  kube-proxy root@192.168.159.14$i:/opt/kubernetes/bin/
done
```

##### 4.2 部署kubelet

###### 4.2.1 创建配置文件

```shell
cat > /opt/kubernetes/cfg/kubelet.conf << EOF
KUBELET_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--hostname-override=k8s-master \\
--network-plugin=cni \\
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \\
--config=/opt/kubernetes/cfg/kubelet-config.yml \\
--cert-dir=/opt/kubernetes/ssl \\
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
EOF
```

--hostname-override ：显示名称,集群唯一(不可重复)。
--network-plugin ：启用CNI。
--kubeconfig ： 空路径,会自动生成,后面用于连接apiserver。
--bootstrap-kubeconfig ：首次启动向apiserver申请证书。
--config ：配置文件参数。
--cert-dir ：kubelet证书目录。
--pod-infra-container-image ：管理Pod网络容器的镜像 init container



###### 4.2.2 配置文件

```shell
cat > /opt/kubernetes/cfg/kubelet-config.yml << EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS:
- 10.0.0.2
clusterDomain: cluster.local 
failSwapOn: false
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /opt/kubernetes/ssl/ca.pem 
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
maxOpenFiles: 1000000
maxPods: 110
EOF

```



###### 4.2.3 生成kubelet初次加入集群引导kubeconfig文件

```shell
KUBE_CONFIG="/opt/kubernetes/cfg/bootstrap.kubeconfig"
KUBE_APISERVER="https://192.168.242.51:6443" # apiserver IP:PORT
TOKEN="4136692876ad4b01bb9dd0988480ebba" # 与token.csv里保持一致  /opt/kubernetes/cfg/token.csv 

# 生成 kubelet bootstrap kubeconfig 配置文件
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${KUBE_CONFIG}
  
kubectl config set-credentials "kubelet-bootstrap" \
  --token=${TOKEN} \
  --kubeconfig=${KUBE_CONFIG}
  
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kubelet-bootstrap" \
  --kubeconfig=${KUBE_CONFIG}
  
kubectl config use-context default --kubeconfig=${KUBE_CONFIG}

```

###### 4.2.4 systemd管理kubelet

```shell
cat > /usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kubelet.conf
ExecStart=/opt/kubernetes/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

###### 4.2.5 启动并设置开机启动

```shell
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
```

###### 4.2.6 允许kubelet证书申请并加入集群

```shell
#查看kubelet证书请求
kubectl get csr
```


NAME                                                   AGE    SIGNERNAME                                    REQUESTOR           CONDITION
node-csr-KbHieprZUMOvTFMHGQ1RNTZEhsSlT5X6wsh2lzfUry4   107s   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   Pending

```shell
#允许kubelet节点申请
kubectl certificate approve  node-csr-KbHieprZUMOvTFMHGQ1RNTZEhsSlT5X6wsh2lzfUry4
```



```shell
#查看节点
kubectl get nodes
```

​					NAME          STATUS     ROLES    AGE     VERSION
​					k8s-master1   NotReady   <none>   2m11s   v1.20.10


说明：
由于网络插件还没有部署,节点会没有准备就绪NotReady

##### 4.3 部署kube-proxy

##### 4.3.1 创建配置文件

```shell
cat > /opt/kubernetes/cfg/kube-proxy.conf << EOF
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=2 \\
--hostname-override=k8s-master \\
--log-dir=/opt/kubernetes/logs \\
--config=/opt/kubernetes/cfg/kube-proxy-config.yml"
EOF
```

###### 4.3.2 配置参数文件

```shell
cat > /opt/kubernetes/cfg/kube-proxy-config.yml << EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
metricsBindAddress: 0.0.0.0:10249
clientConnection:
  kubeconfig: /opt/kubernetes/cfg/kube-proxy.kubeconfig
hostnameOverride: k8s-master
clusterCIDR: 10.244.0.0/16
EOF
```

###### 4.3.3 生成kube-proxy.kubeconfig文件

```shell
cd TLS/k8s

KUBE_CONFIG="/opt/kubernetes/cfg/kube-proxy.kubeconfig"
KUBE_APISERVER="https://192.168.159.143:6443"

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-credentials kube-proxy \
  --client-certificate=./kube-proxy.pem \
  --client-key=./kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=${KUBE_CONFIG}

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=${KUBE_CONFIG}

kubectl config use-context default --kubeconfig=${KUBE_CONFIG}
```

###### 4.3.4 systemd管理kube-proxy

```shell
cat > /usr/lib/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-proxy.conf
ExecStart=/opt/kubernetes/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```



###### 4.3.5 启动并设置开机自启

```shell
systemctl daemon-reload
systemctl start kube-proxy
systemctl enable kube-proxy
```



##### 4.4 部署网络组件(Calico)

Calico是一个纯三层的数据中心网络方案，是目前Kubernetes主流的网络方案。

```shell
kubectl apply -f calico.yaml
kubectl get pods -n kube-system
```


等Calico Pod都Running,节点也会准备就绪。

```shell
kubectl get pods -n kube-system
```

NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-97769f7c7-zcz5d   1/1     Running   0          3m11s
calico-node-5tnll                         1/1     Running   0          3m11s

```shell
kubectl get nodes
```

NAME          STATUS   ROLES    AGE   VERSION
k8s-master1   Ready    <none>   21m   v1.20.10

##### 4.5 授权apiserver访问kubelet

应用场景：如kubectl logs

```shell
cat > apiserver-to-kubelet-rbac.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
      - pods/log
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

kubectl apply -f apiserver-to-kubelet-rbac.yaml

```

#### 5、新增加Work Node

##### 5.1 拷贝以部署好的相关文件到新节点

在Master节点将Work Node涉及文件拷贝到新节点 242.52/242.53

```shell
for i in {4..5}; do scp -r /opt/kubernetes root@192.168.159.14$i:/opt/; done

for i in {4..5}; do scp -r /usr/lib/systemd/system/{kubelet,kube-proxy}.service root@192.168.159.14$i:/usr/lib/systemd/system; done

for i in {4..5}; do scp -r /opt/kubernetes/ssl/ca.pem root@192.168.159.14$i:/opt/kubernetes/ssl/; done
```

##### 5.2 删除kubelet证书和kubeconfig文件

```shell
rm -f /opt/kubernetes/cfg/kubelet.kubeconfig 
rm -f /opt/kubernetes/ssl/kubelet*
```


说明:
这几个文件是证书申请审批后自动生成的,每个Node不同,必须删除。

##### 5.3 修改主机名

```shell
vi /opt/kubernetes/cfg/kubelet.conf
--hostname-override=k8s-node1

vi /opt/kubernetes/cfg/kube-proxy-config.yml
hostnameOverride: k8s-node1
```

##### 5.4 启动并设置开机自启

```shell
systemctl daemon-reload
systemctl start kubelet kube-proxy
systemctl enable kubelet kube-proxy
```

##### 5.5 在Master上同意新的Node kubelet证书申请

```shell
#查看证书请求
kubectl get csr
```

NAME                                                   AGE   SIGNERNAME                                    REQUESTOR           CONDITION
node-csr-2vKShQc_wlqPrTPAwT5MHpdRWIX-oyr9NyBXu1XNwxg   12s   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   Pending
node-csr-KbHieprZUMOvTFMHGQ1RNTZEhsSlT5X6wsh2lzfUry4   47h   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   Approved,Issued



```shell
#同意
kubectl certificate approve node-csr-2vKShQc_wlqPrTPAwT5MHpdRWIX-oyr9NyBXu1XNwxg
kubectl certificate approve node-csr-KbHieprZUMOvTFMHGQ1RNTZEhsSlT5X6wsh2lzfUry4
```

certificatesigningrequest.certificates.k8s.io/node-csr-2vKShQc_wlqPrTPAwT5MHpdRWIX-oyr9NyBXu1XNwxg approved

##### 5.6 查看Node状态(要稍等会才会变成ready,会下载一些初始化镜像)

```shell
kubectl get nodes
```

NAME          STATUS   ROLES    AGE   VERSION
k8s-master1   Ready    <none>   46h   v1.20.10
k8s-node1     Ready    <none>   77s   v1.20.10

说明:
其他节点同上





 

 



 




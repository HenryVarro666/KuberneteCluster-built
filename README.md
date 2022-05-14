# 							Kubernates

## 一、K8S概述

​	官网： https://kubernetes.io

​	是一个开源的容器编排框架工具（生态丰富），可以解决docker的若干痛点。

### 	(一)、Kubernetes的优势：

​		·  服务发现和负载均衡
​		·  集中化配置管理和密钥管理
​		·  存储编排
​		·  任务批处理运行
​		·  自动发布（默认滚动发布模式）和回滚
​		·  自动装箱，水平扩展，自我修复
​		·  任务批处理运行

## 二、K8S快速入门

### 	(一)、四组基本概念

​		·  Pod/Pod控制器
​		·  Name/Namespace
 	   ·  Label/Label选择器
​		**·  Service/Ingress**

### 	(二)、Pod/Pod控制器

​		· Pod

​			·    Pod是K8S里能够被运行的最小的逻辑单元（原子单元）

​			·    1个Pod里面可以运行多个容器，它们共享UTS+NET+IPC名称空间

​			·	可以把Pod理解成豌豆荚，而同一Pod内的每个容器是一颗颗豌豆

​			·	一个Pod里运行多个容器，又叫:  边车(SideCar）模式

​		· Pod控制器

​			· Pod控制器是Pod启动的一种模板，用来保证在K8S里启动的Pod应始终按照人们的预期运行（副本数、生命周期、健康状态检查..)
​			· K8S内提供了众多的Pod控制器，常用的有以下几种:

​			·	**Deployment**
​			·    **DaemonSet**
​			·    ReplicaSet
​			·    StatefulSet
​			·    Job
​			·    Cronjob

​		**注意：Pod可以单独启动在k8s中，可以不用任何Pod控制器，但是还是推荐使用Pod控制器。**

### 	(三)、Name/Namespace

​		·	Name

​			·	由于K8S内部，使用“资源”来定义每一种逻辑概念（功能）

​				 故每种“资源”，都应该有自己的“名称”
​				 ·    “资源”有api版本( apiVersion）类别(kind )、元数据( metadata )、定义清单( spec)、状态( status）			     等配置信息
​				 的“元数据”信息里

​				·	“名称”通常定义在“资源”的“元数据”信息里。

​		·    Namespace

​			·	随着项目增多、人员增加、集群规模的扩大，需要一种能够隔离K8S内各种“资源”的方法，这就是名称空间
​			·	名称空间可以理解为K8S内部的虚拟集群组
​			·	不同名称空间内的“资源”，名称可以相同，相同名称空间内的同种“资源”，“名称”不能相同
​			·	合理的使用K8S的名称空间，使得集群管理员能够更好的对交付到K8S里的服务进行分类管理和浏览
​			·    K8S里默认存在的名称空间有:default、kube-system、kube-public

​			·	查询K8S里特定“资源”要带上相应的名称空间

### 	(四)、Lable/Lable选择器

​		·	Label

​			·	标签是k8s特色的管理方式，便于分类管理资源对象。

​			·	—个标签可以对应多个资源，一个资源也可以有多个标签，它们是多对多的关系。
​			·	—个资原拥有多个标签，可以实现不同维度的管理。

​			·	标签的组成:key=value	

​			·	与标签类似的，还有一种“注解”( annotations )
​		·	Label选择器

​			·	给资源打上标签后，可以使用标签选择器过滤指定的标签
​			·	标签选择器目前有两个:基于等值关系（等于、不等于）和基于集合关系（属于、不属于、存在）
​			·	许多资源支持内嵌标签选择器字段

​				·    matchLabels

​				·	matchExpressions

### 	(五)、Service/Ingress

​		·    Service（四层）

​			·	在K8S的世界里，虽然每个Pod都会被分配一个单独的IP地址，但这个IP地址会随着Pod的销毁而消失
​			·    Service（服务）就是用来解决这个问题的核心概念
​			·	一个Service可以看作一组提供相同服务的Pod的对外访问接口
​			·    Service作用于哪些Pod是通过标签选择器来定义的

​			**·    Ingress      很重要，很有用**

​			**·    Ingress是K8S集群里工作在OSI网络参考模型下，第7层的应用，对外暴露的接口**

​			**·    Service只能进行L4流量调度，表现形式是ip+port**
​			**·    Ingress则可以调度不同业务域、不同URL访问路径的业务流量**

​			

​			**在访问一个域名时，请求会由Ingress转发给Service，Service再找到相应的Pod。**

### 	(六)、核心组件

​		·	配置存储中心→etcd服务			（可以先简单想象为mysql，用于存储数据的）
​		·	主控(master）节点
​			·    kube-apiserver服务   			 k8s中整个集群的大脑

​			·	kube-controller-manager服务			由一系列的控制器组成

​			·    kube-scheduler服务			接受调度pod到适合的运算节点上		有两种方法，预算策略和优选策略
​		·	运算(node）节点
​			·    kube-kubelet服务				最脏最累的活由它来干，给api-server提供一个依据
​			·    Kube-proxy服务					建立了pod网络和集群网络的关系(clusterip->podip)		常用三种流量调度模式：Userspace（废弃）  Iptables（快被废弃）  Ipvs（推荐）
​		·	CLI客户端
​			· kubectl

### 	(七)、核心附件

​		·	服务发现用插件→coredns

​		·	CNI网络插件→flannel/calico
​		·	服务暴露用插件→traefik
​		·	GUI管理插件→Dashboard

## PS：master节点和node节点只是逻辑上的概念，完全可以将两个节点融合在一起，互不干扰。




## 三、k8s的安装部署

### 	(一)使用minikube（很小，仅供学习用，不是用于生产）

​		可以在官网上下载使用

### (二)、使用kubeadmin安装部署(版本可依据个人情况)

kubeadm是官方社区推出的一个用于快速部署kubernetes集群的工具。

这个工具能通过两条指令完成一个kubernetes集群的部署：

```shell
# 创建一个 Master 节点
$ kubeadm init

# 将一个 Node 节点加入到当前集群中
$ kubeadm join <Master节点的IP和端口 >
```

#### 1. 安装要求

在开始之前，部署Kubernetes集群机器需要满足以下几个条件：

- 一台或多台机器，操作系统 CentOS7.x-86_x64
- 硬件配置：2GB或更多RAM，2个CPU或更多CPU，硬盘30GB或更多
- 集群中所有机器之间网络互通
- 可以访问外网，需要拉取镜像
- 禁止swap分区

#### 2. 准备环境

 ![kubernetesæ¶æå¾](https://blog-1252881505.cos.ap-beijing.myqcloud.com/k8s/single-master.jpg) 

| 角色       | IP              |
| ---------- | --------------- |
| k8s-master | 192.168.159.143 |
| k8s-node1  | 192.168.159.144 |
| k8s-node2  | 192.168.159.145 |

​	升级centos内核：

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
192.168.159.143 k8s-master1
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

​	配置静态ipd地址

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
IPADDR="192.168.159.63"    #从这一行开始都是要添加的，这里添加上述查看到的ip地址
PREFIX="24"
GATEWAY="192.168.159.2"
DNS1="202.119.248.66"   #我这里是我学校的DNS，你可以自己选择一个公有DNS
```

​	重启网络服务

```shell
systemctl restart network
ping www.baidu.com
```



#### 3. 安装Docker/kubeadm/kubelet【所有节点】

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。

##### 3.1 安装Docker（注意版本与Kubernetes版本的兼容性）

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

##### 3.2 添加阿里云YUM软件源，为了能够下载kubeadm、kubelet和kubectl

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

##### 3.3 安装kubeadm，kubelet和kubectl

由于版本更新频繁，这里可以指定版本号部署：（不指定即下载最新版本），这里使用的是1.20版本

```shell
yum install -y kubelet-1.20.0 kubeadm-1.20.0 kubectl-1.20.0


systemctl enable kubelet
```

#### 4. 部署Kubernetes Master

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

#### 5. 加入Kubernetes Node

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



#### 6. 部署容器网络（CNI）

 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network 

注意：只需要部署下面其中一个，推荐Calico。

##### 6.1 Calico（推荐）

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



##### 6.2 Flannel

Flannel是CoreOS维护的一个网络组件，Flannel为每个Pod提供全局唯一的IP，Flannel使用ETCD来存储Pod子网与Node IP之间的关系。flanneld守护进程在每台主机上运行，并负责维护ETCD信息和路由数据包。

```
$ wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
$ sed -i -r "s#quay.io/coreos/flannel:.*-amd64#lizhenliang/flannel:v0.11.0-amd64#g" kube-flannel.yml
$ kubectl apply -f kube-flannel.yml
```

修改国内镜像仓库。



#### 7. 测试kubernetes集群

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




















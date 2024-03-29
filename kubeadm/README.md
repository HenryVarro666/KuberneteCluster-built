# kubeadm安装(版本可依据个人情况，本文使用的是1.20.0)

kubeadm是官方社区推出的一个用于快速部署kubernetes集群的工具。

这个工具能通过两条指令完成一个kubernetes集群的部署：

```shell
# 创建一个 Master 节点
$ kubeadm init

# 将一个 Node 节点加入到当前集群中
$ kubeadm join <Master节点的IP和端口 >
```

## 1. 安装Docker/kubeadm/kubelet【所有节点】

Kubernetes默认CRI（容器运行时）为Docker，因此先安装Docker。不过在Kubernetes1.24中，已经正式弃用Docker，而使用containerd作为CRI。

### 1.1 安装Docker（注意版本与Kubernetes版本的兼容性）

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

  

**PS：可能会出现It seems like the kubelet isn't running or healthy的错误，此时可以参考这三篇博客：**

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
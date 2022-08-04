# 一、安装KubeSphere前置环境

**以下安装均在Kubernetes v1.20环境下执行**

## 1、nfs文件系统

### 1、安装nfs-server

```shell
# 在任意一个k8s集群节点上。
yum install -y nfs-utils
yum install -y rpcbind

systemctl start rpcbind    #先启动rpc服务
systemctl enable rpcbind   #设置开机启动

systemctl start nfs-server    
systemctl enable nfs-server



echo "/nfs/data/ *(insecure,rw,sync,no_root_squash)" > /etc/exports


# 执行以下命令，启动 nfs 服务;创建共享目录
mkdir -p /nfs/data


# 使配置生效
systemctl reload nfs 

```

## 2、配置storageclass资源

配置动态供应的默认存储类

```shell
#需要修改deployment-nfs.yaml中的内容，指定nfs-server的IP地址

kubectl apply -f storageclass/clusterrole.yaml
kubectl apply -f storageclass/clusterrolebinding.yaml
kubectl apply -f storageclass/serviceaccount.yaml
kubectl apply -f storageclass/deployment-nfs.yaml
kubectl apply -f storageclass/nfs-class.yaml

#确认配置是否生效
kubectl get sc
```

​	经测试，在1.20版本下该nfs-provisioer无法正常运行，通过log查看日志后显示报错信息“selfLink was empty”（也可能是其他的），这是由于selfLink在1.16版本以后已经弃用，在1.20版本停用。

​	而由于nfs-provisioner的实现是基于selfLink功能（同时也会影响其他用到selfLink这个功能的第三方软件），需要等nfs-provisioner的制作方重新提供新的解决方案。目前可用的临时方案是：

```shell
vim /etc/kubernetes/manifests/kube-apiserver.yaml #文件，找到如下内容后，在最后添加一项参数

spec:
  containers:
  - command:
    - kube-apiserver    
    - --advertise-address=192.168.210.20    
    - --.......　　#省略多行内容    
    - --feature-gates=RemoveSelfLink=false　　#添加此行
    

#如果是高可用的k8s集群，则需要在所有master节点上进行此操作。
#稍等片刻后kube-apiserver的pod会自动重启。也可以自己手动删除pod

```



## 3、metrics-server

集群指标监控组件，如HPA、VPA等

```shell
kubectl apply -f metrics-server/components.yaml
```

------

# 二、安装KubeSphere

https://kubesphere.com.cn/

## 1、下载核心文件

如果下载不到，可使用本目录中的yaml文件（此处使用的是v3.3.0版本）

```bash
wget https://github.com/kubesphere/ks-installer/releases/download/v3.3.0/kubesphere-installer.yaml

wget https://github.com/kubesphere/ks-installer/releases/download/v3.3.0/cluster-configuration.yaml
```

## 2、修改cluster-configuration

在 cluster-configuration.yaml中指定我们需要开启的功能，如Prometheus监控、日志、istio微服务治理等等。

参照官网“启用可插拔组件” 

https://kubesphere.com.cn/docs/pluggable-components/overview/

## 3、执行安装

```bash
kubectl apply -f kubesphere-installer.yaml

kubectl apply -f cluster-configuration.yaml
```

## 4、查看安装进度

```shell
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l app=ks-install -o jsonpath='{.items[0].metadata.name}') -f
```

访问任意机器的 30880端口

账号 ： admin

密码 ： P@88w0rd



------

处于containercreating状态可能是因为还在pull image，稍等片刻即可

解决Prometheus pod中etcd监控证书找不到问题

```bash
kubectl -n kubesphere-monitoring-system create secret generic kube-etcd-client-certs  --from-file=etcd-client-ca.crt=/etc/kubernetes/pki/etcd/ca.crt  --from-file=etcd-client.crt=/etc/kubernetes/pki/apiserver-etcd-client.crt  --from-file=etcd-client.key=/etc/kubernetes/pki/apiserver-etcd-client.key
```

## 
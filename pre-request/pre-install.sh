#! /bin/bash

#configure yum source and epel source：
yum install -y wget vim
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
yum -y install epel-release

#close firewalld：
systemctl stop firewalld
systemctl disable firewalld



#close selinux：
sed -i 's/enforcing/disabled/' /etc/selinux/config  # close forever
setenforce 0  # close temporarily


#close swap：
swapoff -a  # close temporarily
sed -i '$d' /etc/fstab   # close forever


# set hostname
hostnamectl set-hostname $1


#在master添加hosts：
yum install -y net-tools
local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"​`
cat >> /etc/hosts << EOF
${local_ip} $1
EOF


#将桥接的IPv4流量传递到iptables的链：
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system  # 生效


#时间同步：    必须要同步才行
yum install ntpdate -y
ntpdate time.windows.com



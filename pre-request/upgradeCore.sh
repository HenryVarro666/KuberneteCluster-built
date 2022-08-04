#! /bin/bash

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org  #导入ELRepo仓库的公共密钥

rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm  #安装ELRepo仓库的yum源

yum --disablerepo="*" --enablerepo="elrepo-kernel" list available  #查看可用的系统内核包

yum --enablerepo=elrepo-kernel install -y kernel-ml  #安装最新版本内核

grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg  #生成 grub 配置文件并重启


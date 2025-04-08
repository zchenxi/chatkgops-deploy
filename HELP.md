# 部署指南

## 0. 机器信息

| 主机名     | IP             | 操作系统                                         |
| ---------- | -------------- | ------------------------------------------------ |
| k8s-master | 10.176.122.154 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |
| k8s-node1  | 10.176.122.151 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |
| k8s-node2  | 10.176.122.152 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |
| k8s-node3  | 10.176.122.153 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |
| k8s-node4  | 10.176.122.161 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |
| k8s-node5  | 10.176.122.162 | Ubuntu 20.10 (GNU/Linux 5.8.0-48-generic x86_64) |

## 1. 机器设置

### a. Ubuntu换源

清华大学开源软件镜像站：[Ubuntu软件仓库](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/)

版本选择：`Ubuntu 20.04 LTS (focal)`

Ubuntu 的软件源配置文件位于 `/etc/apt/sources.list`

换源后记得更新Ubuntu软件包列表

```she
apt update
```

### b. 配置时区 & 同步时钟

配置时区

```shell
timedatectl set-timezone Asia/Shanghai
```

同步时钟

```shell
apt install ntp
systemctl enable ntp
```

配置 `/etc/ntp.conf`

```shell
# 注视掉默认提供的，添加最下面7个阿里云ntp
# Use servers from the NTP Pool Project. Approved by Ubuntu Technical Board
# on 2011-02-08 (LP: #104525). See http://www.pool.ntp.org/join.html for
# more information.
# pool 0.ubuntu.pool.ntp.org iburst
# pool 1.ubuntu.pool.ntp.org iburst
# pool 2.ubuntu.pool.ntp.org iburst
# pool 3.ubuntu.pool.ntp.org iburst
pool ntp1.aliyun.com iburst
pool ntp2.aliyun.com iburst
pool ntp3.aliyun.com iburst
pool ntp4.aliyun.com iburst
pool ntp5.aliyun.com iburst
pool ntp6.aliyun.com iburst
pool ntp7.aliyun.com iburst
```

配置完成以后重启ntp服务

```shell
systemctl restart ntp
```

查看 NTP 服务器的同步详情

```shell
ntpq -p
```

### c. 关闭防火墙

确保防火墙处于关闭状态：

```shell
ufw status
# Status: inactive
```

### d. 关闭selinux

```shell
apt install policycoreutils
```

确保selinux处于关闭状态

```shell
sestatus
# SELinux status:                 disabled
```

### e. 禁用swap

临时禁用

```shell
swapoff -a
```

永久禁用

```shell
# 注释掉与swap有关的行
sed -i.bak '/swap/s/^/#/' /etc/fstab
```

### f. 内核参数修改

加载 `br_netfilter` 模块

```shell
modprobe br_netfilter
```

确保在系统启动时自动加载模块

```
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
```

创建`/etc/sysctl.d/k8s.conf`，写入：

```shell
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
```

生效内核参数

```shell
sysctl -p /etc/sysctl.d/k8s.conf
```

### e. 主机设置检查

`b.时钟`

```shell
root@fdjw:~# timedatectl status
               Local time: Fri 2023-12-15 16:11:23 CST
           Universal time: Fri 2023-12-15 08:11:23 UTC
                 RTC time: Fri 2023-12-15 08:11:23    
                Time zone: Asia/Shanghai (CST, +0800) 
System clock synchronized: no                         
              NTP service: n/a                        
          RTC in local TZ: no                         
root@fdjw:~# systemctl status ntp
● ntp.service - Network Time Service
     Loaded: loaded (/lib/systemd/system/ntp.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-12-15 16:06:42 CST; 4min 57s ago
       Docs: man:ntpd(8)
    Process: 982 ExecStart=/usr/lib/ntp/ntp-systemd-wrapper (code=exited, status=0/SUCCESS)
   Main PID: 1034 (ntpd)
      Tasks: 2 (limit: 38424)
     Memory: 3.5M
     CGroup: /system.slice/ntp.service
             └─1034 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 113:117

Dec 15 16:07:51 fdjw ntpd[1034]: Soliciting pool server 203.107.6.88
Dec 15 16:07:57 fdjw ntpd[1034]: Soliciting pool server 185.125.190.56
Dec 15 16:07:58 fdjw ntpd[1034]: Soliciting pool server 185.125.190.57
Dec 15 16:07:59 fdjw ntpd[1034]: Soliciting pool server 185.125.190.58
Dec 15 16:08:54 fdjw ntpd[1034]: Soliciting pool server 120.25.115.20
Dec 15 16:09:06 fdjw ntpd[1034]: Soliciting pool server 2620:2d:4000:1::41
Dec 15 16:09:58 fdjw ntpd[1034]: Soliciting pool server 120.25.115.20
Dec 15 16:10:13 fdjw ntpd[1034]: Soliciting pool server 2620:2d:4000:1::3f
Dec 15 16:11:02 fdjw ntpd[1034]: Soliciting pool server 120.25.115.20
Dec 15 16:11:21 fdjw ntpd[1034]: Soliciting pool server 2620:2d:4000:1::40
root@fdjw:~# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
 ntp1.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp2.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp3.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp4.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp5.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp6.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp7.aliyun.com .POOL.          16 p    -   64    0    0.000    0.000   0.000
 ntp.ubuntu.com  .POOL.          16 p    -   64    0    0.000    0.000   0.000
*203.107.6.88    100.107.25.114   2 u   61   64    3   25.161    4.355   3.764
 185.125.190.56  194.121.207.249  2 u   29   64   17  308.664    4.487   3.547
 185.125.190.57  201.68.88.106    2 u   31   64    1  308.082    4.733   0.000
```

`c.防火墙`

```shell
root@fdjw:~# ufw status
Status: inactive
```

`d.selinux`

```shell
root@fdjw:~# sestatus
SELinux status:                 disabled
```

`e.swap`

```shell
root@fdjw:~# free -h
              total        used        free      shared  buff/cache   available
Mem:           31Gi       267Mi        30Gi       1.0Mi       308Mi        30Gi
Swap:            0B          0B          0B
```

`f.内核参数`

```shell
root@fdjw:~# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
root@fdjw:~# sysctl net.bridge.bridge-nf-call-iptables
net.bridge.bridge-nf-call-iptables = 1
root@fdjw:~# sysctl net.bridge.bridge-nf-call-ip6tables
net.bridge.bridge-nf-call-ip6tables = 1
```

## 2. Docker

### a. 安装

安装Docker版本为`20.10.7`

参考官方文档：https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

1. Set up Docker's `apt` repository.

```shell
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

2. To install a specific version of Docker Engine, start by listing the available versions in the repository:

```shell
root@fdjw:~# apt-cache madison docker-ce | awk '{ print $3 }'
5:20.10.8~3-0~ubuntu-groovy
5:20.10.7~3-0~ubuntu-groovy
5:20.10.6~3-0~ubuntu-groovy
5:20.10.5~3-0~ubuntu-groovy
5:20.10.4~3-0~ubuntu-groovy
5:20.10.3~3-0~ubuntu-groovy
5:20.10.2~3-0~ubuntu-groovy
5:20.10.1~3-0~ubuntu-groovy
5:20.10.0~3-0~ubuntu-groovy
```

3. Select the desired version and install:

```shell
VERSION_STRING=5:20.10.7~3-0~ubuntu-groovy
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io
```

4. Start docker

```
systemctl start docker
systemctl enable docker.service
```

5. Verify docker version

```shell
root@fdjw:~# docker --version
Docker version 20.10.7, build f0df350
```

### b. 配置

docker配置文件为`/etc/docker/daemon.json`

```json
{
  "registry-mirrors": ["https://docker.nju.edu.cn/"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-opts": {
    "max-size": "100m"
  }
}
```

配置完成后

```shell
systemctl restart docker.service
```

`docker info`

```bash
root@fdjw:~# docker info
Client:
 Context:    default
 Debug Mode: false
 Plugins:
  app: Docker App (Docker Inc., v0.9.1-beta3)
  buildx: Build with BuildKit (Docker Inc., v0.5.1-docker)
  scan: Docker Scan (Docker Inc., v0.8.0)

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 20.10.7
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 1
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 io.containerd.runtime.v1.linux runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: e25210fe30a0a703442421b0f60afac609f950a3
 runc version: v1.0.1-0-g4144b63
 init version: de40ad0
 Security Options:
  apparmor
  seccomp
   Profile: default
 Kernel Version: 5.8.0-48-generic
 Operating System: Ubuntu 20.10
 OSType: linux
 Architecture: x86_64
 CPUs: 16
 Total Memory: 31.36GiB
 Name: fdjw
 ID: N2BE:MWID:7DRX:YMJZ:H7NE:USAR:GVAJ:ACPI:PMOC:WDP5:CDKP:SFWY
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Labels:
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Registry Mirrors:
  https://docker.nju.edu.cn/
 Live Restore Enabled: false
```

### c. 镜像仓库

南京大学：https://doc.nju.edu.cn/books/35f4a

## 3. K8S

### a. 修改主机名

分别设置6台主机的主机名为`k8s-master` `k8s-node1` `k8s-node2` `k8s-node3` `k8s-node4` `k8s-node5`

```shell
hostnamectl set-hostname k8s-master
more /etc/hostname
```

### b. 修改hosts

```shell
cat >> /etc/hosts << EOF
10.176.122.154   k8s-master
10.176.122.151   k8s-node1
10.176.122.152   k8s-node2
10.176.122.153   k8s-node3
10.176.122.161   k8s-node4
10.176.122.162   k8s-node5
EOF
```

### c. 添加阿里云k8s源

```shell
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main"
sudo apt-get update
```

### d. kubelet & kubeadm & kubectl

6台机器都安装`kubelet` `kubeadm` `kubectl` 的 `1.21.2-00` 版本。

可以用自己的笔记本作为“窗口机”，只需要装`kubectl`

查看可用版本

```
apt-cache madison kubelet
apt-cache madison kubeadm
apt-cache madison kubectl
```

安装

```shell
VERSION_STRING=1.21.2-00
sudo apt install kubeadm=$VERSION_STRING kubectl=$VERSION_STRING kubelet=$VERSION_STRING
```

```shell
root@k8s-master:~# kubelet --version
Kubernetes v1.21.2
root@k8s-master:~# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.2", GitCommit:"092fbfbf53427de67cac1e9fa54aaa09a28371d7", GitTreeState:"clean", BuildDate:"2021-06-16T12:57:56Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"linux/amd64"}
root@k8s-master:~# kubectl version
Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.2", GitCommit:"092fbfbf53427de67cac1e9fa54aaa09a28371d7", GitTreeState:"clean", BuildDate:"2021-06-16T12:59:11Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"linux/amd64"}
```

启动`kubelet`，并设置开机自动启动

```shell
systemctl enable kubelet && systemctl start kubelet
```

### e. 拉镜像

拉镜像脚本（6台机器都需要拉镜像）

```shell
#!/bin/bash
url=registry.cn-hangzhou.aliyuncs.com/google_containers
# 安装指定的kubectl版本
version=v1.21.2
# 上面查出来的coredns版本号
coredns=1.8.0
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $2}'`)
for imagename in ${images[@]} ; do
   if [ $imagename = "coredns" ]
   then
      docker pull $url/coredns:$coredns
      docker tag $url/coredns:$coredns k8s.gcr.io/coredns/coredns:v1.8.0
      docker rmi -f $url/coredns:$coredns
   else
      docker pull $url/$imagename
      docker tag $url/$imagename k8s.gcr.io/$imagename
      docker rmi -f $url/$imagename
  fi
done
```

`docker images`查看镜像

```
root@k8s-master:~# docker images
REPOSITORY                           TAG        IMAGE ID       CREATED       SIZE
k8s.gcr.io/kube-apiserver            v1.21.2    106ff58d4308   2 years ago   126MB
k8s.gcr.io/kube-proxy                v1.21.2    a6ebd1c1ad98   2 years ago   131MB
k8s.gcr.io/kube-controller-manager   v1.21.2    ae24db9aa2cc   2 years ago   120MB
k8s.gcr.io/kube-scheduler            v1.21.2    f917b8c8f55b   2 years ago   50.6MB
k8s.gcr.io/pause                     3.4.1      0f8457a4c2ec   2 years ago   683kB
k8s.gcr.io/coredns/coredns           v1.8.0     296a6d5035e2   3 years ago   42.5MB
k8s.gcr.io/etcd                      3.4.13-0   0369cf4303ff   3 years ago   253MB
```

### f. 初始化k8s集群

在`k8s-master`上执行：

```shell
kubeadm init --kubernetes-version=1.21.2 --apiserver-advertise-address=10.176.122.154 --pod-network-cidr=10.244.0.0/16
```

初始化成功：

```shell
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.176.122.154:6443 --token u62nz7.6pofslcoe6z1rahp \
	--discovery-token-ca-cert-hash sha256:2a5cd32aea7f10688496273f2d0a8b9dc5634d18050d8e83614269aed39d68ac 
```

执行：

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### g. 加入其他节点到k8s集群

在其他节点上执行

```shell
kubeadm join 10.176.122.154:6443 --token u62nz7.6pofslcoe6z1rahp \
	--discovery-token-ca-cert-hash sha256:2a5cd32aea7f10688496273f2d0a8b9dc5634d18050d8e83614269aed39d68ac 
```

结果：

```
root@k8s-master:~# kubectl get nodes
NAME         STATUS     ROLES                  AGE     VERSION
k8s-master   NotReady   control-plane,master   4m16s   v1.21.2
k8s-node1    NotReady   <none>                 28s     v1.21.2
k8s-node2    NotReady   <none>                 25s     v1.21.2
k8s-node3    NotReady   <none>                 18s     v1.21.2
k8s-node4    NotReady   <none>                 21s     v1.21.2
k8s-node5    NotReady   <none>                 19s     v1.21.2
```

### h. 安装网络插件

flannel: https://github.com/flannel-io/flannel

```
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

```shell
root@k8s-master:~# kubectl get nodes
NAME         STATUS   ROLES                  AGE   VERSION
k8s-master   Ready    control-plane,master   42m   v1.21.2
k8s-node1    Ready    <none>                 38m   v1.21.2
k8s-node2    Ready    <none>                 38m   v1.21.2
k8s-node3    Ready    <none>                 38m   v1.21.2
k8s-node4    Ready    <none>                 38m   v1.21.2
k8s-node5    Ready    <none>                 38m   v1.21.2
```

```shell
root@k8s-master:~# kubectl get pods -owide -A
NAMESPACE      NAME                                 READY   STATUS    RESTARTS   AGE     IP               NODE         NOMINATED NODE   READINESS GATES
kube-flannel   kube-flannel-ds-2km2c                1/1     Running   0          2m31s   10.176.122.162   k8s-node5    <none>           <none>
kube-flannel   kube-flannel-ds-6zgn6                1/1     Running   0          2m31s   10.176.122.151   k8s-node1    <none>           <none>
kube-flannel   kube-flannel-ds-j8xlm                1/1     Running   0          2m31s   10.176.122.153   k8s-node3    <none>           <none>
kube-flannel   kube-flannel-ds-n5zd8                1/1     Running   0          2m31s   10.176.122.161   k8s-node4    <none>           <none>
kube-flannel   kube-flannel-ds-nn7xq                1/1     Running   0          2m31s   10.176.122.154   k8s-master   <none>           <none>
kube-flannel   kube-flannel-ds-zblf5                1/1     Running   0          2m31s   10.176.122.152   k8s-node2    <none>           <none>
kube-system    coredns-558bd4d5db-blf7l             1/1     Running   0          33m     10.244.2.2       k8s-node2    <none>           <none>
kube-system    coredns-558bd4d5db-qw6j2             1/1     Running   0          33m     10.244.3.2       k8s-node4    <none>           <none>
kube-system    etcd-k8s-master                      1/1     Running   0          33m     10.176.122.154   k8s-master   <none>           <none>
kube-system    kube-apiserver-k8s-master            1/1     Running   0          33m     10.176.122.154   k8s-master   <none>           <none>
kube-system    kube-controller-manager-k8s-master   1/1     Running   0          33m     10.176.122.154   k8s-master   <none>           <none>
kube-system    kube-proxy-277dm                     1/1     Running   0          29m     10.176.122.151   k8s-node1    <none>           <none>
kube-system    kube-proxy-5g4mz                     1/1     Running   0          33m     10.176.122.154   k8s-master   <none>           <none>
kube-system    kube-proxy-crfd5                     1/1     Running   0          29m     10.176.122.162   k8s-node5    <none>           <none>
kube-system    kube-proxy-hxs5h                     1/1     Running   0          29m     10.176.122.152   k8s-node2    <none>           <none>
kube-system    kube-proxy-xv697                     1/1     Running   0          29m     10.176.122.153   k8s-node3    <none>           <none>
kube-system    kube-proxy-z7dx5                     1/1     Running   0          29m     10.176.122.161   k8s-node4    <none>           <none>
kube-system    kube-scheduler-k8s-master            1/1     Running   0          33m     10.176.122.154   k8s-master   <none>           <none>
```

### i. 配置“窗口机”

不想在集群里面放自己的git仓库，部署需要的代码都在自己的电脑上，因此需要将自己的电脑变成“窗口机”。

1. 安装`kubectl`和`helm`
2. `scp k8s-master:~/.kube/config ~/.kube/config`
3. `chmod 600 ~/.kube/config`

## 4. 可观测配置

```
kubectl create ns obs
```

### a. Trace

1. 配置`Opentelemetry Instrumentation`

```bash
kubectl apply -f ./opentelemetry/cert-manager.yaml
kubectl apply -f ./opentelemetry/opentelemetry-operator.yaml
kubectl apply -f ./opentelemetry/instrumentation.yaml -n obs
```

2. 安装`Opentelemetry Collector`

```bash
helm install otelcol ./opentelemetry/opentelemetry-collector -n obs
```

3. 安装`tempo`

```bash
helm install tempo ./tempo -n obs
```

### b. Log

```bash
helm install loki ./loki-stack -n obs
```

需要注意的是，如果docker配置文件中手动修改了docker数据文件存储的位置，则需要相应修改`loki-stack`中的`volume`的路径。默认情况下不需要修改。

### c. Metrics

```bash
helm install prometheus ./kube-prometheus-stack -n obs
```

```bash
$ kubectl get pods -n obs
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          80m
loki-0                                                   1/1     Running   0          81m
loki-promtail-65jkx                                      1/1     Running   0          35s
loki-promtail-6q6vq                                      1/1     Running   0          39s
loki-promtail-8qzfk                                      1/1     Running   0          32s
loki-promtail-gqjcz                                      1/1     Running   0          34s
loki-promtail-tk46m                                      1/1     Running   0          38s
loki-promtail-wnbw6                                      1/1     Running   0          38s
otelcol-opentelemetry-collector-84d9789ddb-2s6tt         1/1     Running   0          88m
otelcol-opentelemetry-collector-84d9789ddb-8ghcp         1/1     Running   0          88m
otelcol-opentelemetry-collector-84d9789ddb-bx8vq         1/1     Running   0          88m
otelcol-opentelemetry-collector-84d9789ddb-dh77j         1/1     Running   0          88m
otelcol-opentelemetry-collector-84d9789ddb-hgdq5         1/1     Running   0          88m
otelcol-opentelemetry-collector-84d9789ddb-phrkl         1/1     Running   0          88m
prometheus-kube-prometheus-operator-bbb4b878f-kjqld      1/1     Running   0          80m
prometheus-kube-state-metrics-6dd9d4d94f-c2bmq           1/1     Running   0          80m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          80m
prometheus-prometheus-node-exporter-57dhd                1/1     Running   0          80m
prometheus-prometheus-node-exporter-5qbcz                1/1     Running   0          80m
prometheus-prometheus-node-exporter-c59r5                1/1     Running   0          80m
prometheus-prometheus-node-exporter-hxgjh                1/1     Running   0          80m
prometheus-prometheus-node-exporter-rxcsn                1/1     Running   0          80m
prometheus-prometheus-node-exporter-xxh5q                1/1     Running   0          80m
tempo-0                                                  2/2     Running   0          83m
```

## 5. TrainTicket

```
cd ts-deploy
make deploy
```

## 6. Grafana

```shell
brew update
brew install grafana
brew services start grafana
```

数据源:

```
Loki: http://10.176.122.154:30001
Prometheus: http://10.176.122.154:30002
Tempo: http://10.176.122.154:30003
```

## 7. Clear & Reinstall

Clear (`otelcol`不需要删除)

```bash
cd ts-deploy
make reset-deploy
helm uninstall tsdb
helm uninstall prometheus -n obs
helm uninstall loki -n obs
helm uninstall tempo -n obs
```

Reinstall

```bash
helm install tempo ./tempo -n obs
helm install loki ./loki-stack -n obs
helm install prometheus ./kube-prometheus-stack -n obs
cd ts-deploy
make deploy
```

## 8. Neo4j

```bash
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key |sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable 4.1" | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt update
sudo apt install neo4j
sudo systemctl enable neo4j.service
sudo systemctl start neo4j.service
sudo systemctl status neo4j.service
```

修改配置

```shell
# With default configuration Neo4j only accepts local connections.
# To accept non-local connections, uncomment this line:
dbms.default_listen_address=0.0.0.0
```

neo4j import 目录：（未来可以将数据目录符号链接到这个目录下面）

```bash
# This setting constrains all `LOAD CSV` import files to be under the `import` directory. Remove or comment it out to
# allow files to be loaded from anywhere in the filesystem; this introduces possible security problems. See the
# `LOAD CSV` section of the manual for details.
dbms.directories.import=/var/lib/neo4j/import
```

`ln -s /root/chatkgops-data /var/lib/neo4j/import/chatkgops-data`

访问：

http://10.176.122.154:7474/browser/

neo4j://10.176.122.154:7687

初始用户名：neo4j

初始密码：neo4j   (-> chatkgops)

## 9. Chromadb

https://docs.trychroma.com/deployment

## 10. ES

```
docker run -d --name es --net elastic -p 9200:9200 -p 9300:9300 -v /root/es/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml -m 3GB docker.elastic.co/elasticsearch/elasticsearch:8.11.0
```

`/root/es/elasticsearch.yml`

```
xpack.security.enabled: false
http.host: 0.0.0.0
```


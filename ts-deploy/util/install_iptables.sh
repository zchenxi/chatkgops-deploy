#!/bin/bash

nodes=`kubectl get nodes | grep k8s- | awk '{print $1}'`
echo "check net connect..."
for node in $nodes
do
    ssh $node ping www.baidu.com -c 2
done

ts_services=`kubectl get pods | grep ts- | awk '{print $1}'`

for ts_svc in $ts_services
do
    echo ${ts_svc} ': apt-get update'
    kubectl exec $ts_svc -- apt-get update &> /dev/null &
done
echo 'wait for apt-get update'
wait

for ts_svc in $ts_services
do
    echo ${ts_svc} ': apt-get install iptables'
    kubectl exec $ts_svc -- apt-get install -y iptables &> /dev/null &
done
echo 'wait for apt-get install iptables'
wait

RED='\e[0;41m'
GREEN='\e[1;32m'
NC='\e[0m'
for ts_svc in $ts_services
do
    kubectl exec $ts_svc -- iptables -V &> /dev/null
    if [ $? = 0 ]
    then
        echo -e ${GREEN} [done] $ts_svc "iptables" ${NC}
    else
        echo -e ${RED} [error] $ts_svc "iptables" ${NC}
    fi
done

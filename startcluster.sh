#!/bin/bash
logfile=/var/log/startcluster.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function startcluster
{
  print_log "========Start cluster service for namespaces:$1========"
  rm -rf ~/.ssh/known_hosts
  masterIP=$(kubectl get pod --namespace=$1 -o wide|grep master|awk {{'print $6'}})
  slave1IP=$(kubectl get pod --namespace=$1 -o wide|grep slave1|awk {{'print $6'}})
  slave2IP=$(kubectl get pod --namespace=$1 -o wide|grep slave2|awk {{'print $6'}})
  slave3IP=$(kubectl get pod --namespace=$1 -o wide|grep slave3|awk {{'print $6'}})
  clientIP=$(kubectl get pod --namespace=$1 -o wide|grep client|awk {{'print $6'}})
  
  # remove target public key
  user="root"
  passwd="root"
 
  unreachable=`ping $masterIP -c 3 -W 3 | grep -c "100% packet loss"`
  if [ $unreachable -eq 1 ]; then
    print_log "host $masterIP is unreachable"
    exit 1
  fi
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "echo 'StrictHostKeyChecking no
  UserKnownHostsFile /dev/null'>> /etc/ssh/ssh_config" 

  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cd /usr/cstor/hadoop && bin/hdfs namenode -format -force"
  print_log "Initial format hdfs on master: $masterIP successfully"
  if [ $? != 0 ]; then
	print_log "Initial format hdfs on master: $masterIP failed"
	exit 1
  fi
  
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cd /usr/cstor/hadoop && sbin/stop-dfs.sh"
  print_log "Stop hdfs on master: $masterIP successfully"
  if [ $? != 0 ]; then
        print_log "Stop hdfs on master: $masterIP failed"
        exit 1
  fi
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cd /usr/cstor/hadoop && sbin/start-dfs.sh"
  print_log "Start hdfs on master: $masterIP successfully"
  if [ $? != 0 ]; then
	print_log "Start hdfs on master: $masterIP failed"
	exit 1
  fi

  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cd /usr/cstor/hadoop && sbin/stop-yarn.sh"
  print_log "Stop yarn on master: $masterIP successfully"
  if [ $? != 0 ]; then
        print_log "Stop yarn on master: $masterIP failed"
        exit 1
  fi
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cd /usr/cstor/hadoop && sbin/start-yarn.sh"
  print_log "Start yarn on master: $masterIP successfully"
  if [ $? != 0 ]; then
	print_log "Start yarn on master: $masterIP failed"
	exit 1
  fi

  print_log "startcluster ok!"
}

startcluster $1 $2


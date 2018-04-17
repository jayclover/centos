#!/bin/bash
logfile=/var/log/updateconfig.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function updateconfig
{
  print_log "========Update cluster configuration file for namespaces:$1========"
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
    print_log "Master node $masterIP is unreachable"
    exit 1
  fi
 
  IPs=($masterIP $slave1IP $slave2IP $slave3IP $clientIP)
  for IP in ${IPs[@]} ; do
    #Update config file for HDFS
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hadoop/core-site.xml /usr/cstor/hadoop/etc/hadoop/"
	if [ $? != 0 ]; then
	  print_log "Updating HDFS config file core-site.xml on $IP failed"
	  exit 1
	fi
	sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hadoop/slaves /usr/cstor/hadoop/etc/hadoop/"
	if [ $? != 0 ]; then
	  print_log "Updating HDFS config file slaves on $IP failed"
	  exit 1
	fi
	sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hadoop/hadoop-env.sh /usr/cstor/hadoop/etc/hadoop/"
	if [ $? != 0 ]; then
	  print_log "Updating HDFS config file hadoop-env.sh on $IP failed"
	  exit 1
	fi
	
    #Update config file for HBase
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hbase/hbase-site.xml /usr/cstor/hbase/conf/"
	if [ $? != 0 ]; then
	  print_log "Updating HBase config file hbase-site.xml on $IP failed"
	  exit 1
	fi
	sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hbase/regionservers /usr/cstor/hbase/conf/"
	if [ $? != 0 ]; then
	  print_log "Updating HBase config file regionservers on $IP failed"
	  exit 1
	fi	
	
    #Update config file for Spark
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/spark/slaves /usr/cstor/spark/conf/"
	if [ $? != 0 ]; then
	  print_log "Updating Spark config file slaves on $IP failed"
	  exit 1
	fi
	sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/spark/spark-env.sh /usr/cstor/spark/conf/"
	if [ $? != 0 ]; then
	  print_log "Updating Spark config file spark-env.sh on $IP failed"
	  exit 1
	fi	
	
    #Update config file for Storm
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/storm/storm.yaml /usr/cstor/storm/conf/"
	if [ $? != 0 ]; then
	  print_log "Updating Storm config file storm.yaml on $IP failed"
	  exit 1
	fi
	
    #Update config file for YARN
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/hadoop/yarn-site.xml /usr/cstor/hadoop/etc/hadoop/"
	if [ $? != 0 ]; then
	  print_log "Updating YARN config file yarn-site.xml on $IP failed"
	  exit 1
	fi
	
    #Update config file for Zookeeper
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "cp -rf /usr/cstor/cluster/zookeeper/zoo.cfg /usr/cstor/zookeeper/conf"
	if [ $? != 0 ]; then
	  print_log "Updating Zookeeper config file zoo.cfg on $IP failed"
	  exit 1
	fi
	print_log "Updated configure file on $IP successfully"
  done
  
  #Update myid file for Zookeeper
  if [ ! -n "$slave1IP" ]; then
    print_log "We don't have machine slave1"
  else
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $slave1IP "cp -rf /usr/cstor/cluster/zookeeper/slave1/myid /usr/cstor/zookeeper/data/"
    if [ $? != 0 ]; then
	  print_log "Updating Zookeeper config file myid on $slave1IP failed"
	  exit 1
    fi
  fi
  if [ ! -n "$slave2IP" ]; then
    print_log "We don't have machine slave2"
  else
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $slave2IP "cp -rf /usr/cstor/cluster/zookeeper/slave1/myid /usr/cstor/zookeeper/data/"
    if [ $? != 0 ]; then
	  print_log "Updating Zookeeper config file myid on $slave1IP failed"
	  exit 1
    fi
  fi
  if [ ! -n "$slave3IP" ]; then
    print_log "We don't have machine slave3"
  else
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $slave3IP "cp -rf /usr/cstor/cluster/zookeeper/slave1/myid /usr/cstor/zookeeper/data/"
    if [ $? != 0 ]; then
	  print_log "Updating Zookeeper config file myid on $slave1IP failed"
	  exit 1
    fi
  fi
  print_log "Updated myid file on slave machines successfully"
  
  #Update myid file for Hive
  if [ ! -n "$clientIP" ]; then
    print_log "We don't have machine client"
  else
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $slave1IP "cp -rf /usr/cstor/cluster/hive/hive-env.sh /usr/cstor/hive/conf/"
    if [ $? != 0 ]; then
	  print_log "Updating Zookeeper config file myid on $slave1IP failed"
	  exit 1
    fi
	print_log "Updated hive file on client:$clientIP successfully"
  fi
  

  print_log "========updateconfig ok! for namespaces:$1========"
}

updateconfig $1

#!/bin/bash
logfile=/var/log/newcredential.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function newcredential
{
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
 
  
  #Modify the hosts with latest info
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "echo ''>/etc/hosts"
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$masterIP   master
$slave1IP   slave1
$slave2IP   slave2
$slave3IP   slave3
$clientIP   client'>> /etc/hosts"
  print_log "Generate host file on master node"
  
  #generate new ssh key on master
  iddsaFile="/root/.ssh/id_dsa"
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cat $iddsaFile"
  if [  $? != 0 ]; then
   sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
  else
   sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa -y"
  fi
  sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $masterIP "cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys"
  
  #Copy the master's ~/.ssh to other hosts
  IPs=($slave1IP $slave2IP $slave3IP $clientIP)   
  for IP in ${IPs[@]} ; do
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "sshpass -p $passwd scp -o 'StrictHostKeyChecking no' root@$masterIP:/etc/hosts /etc"
	print_log "Copying hosts from master node to $IP successfully"
	if [ $? != 0 ]; then
	  print_log "Copying hosts from master node to $IP failed"
	  exit 1
	fi
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "rm -r -f ~/.ssh"
	print_log "Clear ~/.ssh on $IP successfully"
	if [ $? != 0 ]; then
	  print_log "renewing ~/.ssh on $IP failed"
	  exit 1
	fi
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "mkdir ~/.ssh"
	print_log "Generate new ~/.ssh on $IP successfully"
	if [ $? != 0 ]; then
	  print_log "renewing ~/.ssh 2 on $IP failed"
	  exit 1
	fi
    sshpass -p $passwd ssh -o "StrictHostKeyChecking no" $IP "sshpass -p $passwd scp -o 'StrictHostKeyChecking no' root@$masterIP:~/.ssh/* ~/.ssh/"
	print_log "Copy ssh folder from master to $IP successfully"
	if [ $? != 0 ]; then
	  print_log "Copying ~/.ssh from master node to $IP failed"
	  exit 1
	fi
  done

  print_log "newcredential ok!"
}

newcredential $1

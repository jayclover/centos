#!/bin/bash
logfile=/var/log/startwebsvc.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function startwebsvc
{
  print_log "========Start web service ========"
  
  sh /opt/stopwebsvc.sh
  
  kubectl create deployment nginx --image=172.16.0.46:5000/jawen/centosimage:4.2
  deploymentNew=$(kubectl -n default get deployment -o wide | grep nginx |awk {{'print $1'}})
  if [ $deploymentNew != nginx ]; then
    print_log "Failed to create deployment, please run this script again"
  fi
  
  kubectl create -f /opt/nginx-svc.yaml
  serviceNew=$(kubectl -n default get svc -o wide | grep nginx |awk {{'print $1'}})
  if [ $serviceNew != nginx ]; then
    print_log "Failed to create service, please run this script again"
  fi
  
  pod=$(kubectl -n default get po -o wide | grep nginx |awk {{'print $7'}})
  print_log "Web service is deployed on node ‘$pod'"
  print_log "You can open the web through http://114.116.9.186:30090"
  print_log "========Start web service successfully========"
}

startwebsvc

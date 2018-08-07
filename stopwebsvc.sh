#!/bin/bash
logfile=/var/log/stopwebsvc.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function stopwebsvc
{
  print_log "========Stop web service ========"
  
  deployment=$(kubectl -n default get deployment -o wide | grep nginx |awk {{'print $1'}})
  if [ "$deployment" == nginx ]; then
    kubectl -n default delete deployment nginx
    print_log "Deployment 'nginx' is deleted successfully"
  else 
    print_log "No deployment is running for nginx"
  fi

  service=$(kubectl -n default get svc -o wide | grep nginx |awk {{'print $1'}})
  if [ "$service" == nginx ]; then
    kubectl -n default delete svc nginx
    print_log "Service 'nginx' is deleted successfully"
  else
    print_log "No service is running for nginx"
  fi

  print_log "========Stop web service successfully========"
}

stopwebsvc

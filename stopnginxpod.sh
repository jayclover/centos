#!/bin/bash
logfile=/var/log/stopnginxpod.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function stopnginxpod
{
  print_log "========Start the script to stop nginx container========"
  ip="172.16.0.46"
  passwd="yy_721521"
  sshpass -p $passwd ssh -p 6111 -o "StrictHostKeyChecking no" $ip "sh /opt/stopwebsvc.sh"
  print_log "========Stop the nginx containter succssfully========"
}

stopnginxpod

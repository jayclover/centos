#!/bin/bash
logfile=/var/log/clearImages.log

function print_log
{
   local promt="$1"
   echo -e "$promt"
   echo -e "`date -d today +"%Y-%m-%d %H:%M:%S"`  $promt" >> $logfile
}

#non-password login
function clearImages
{
  print_log "========Start clearing the images in local========"
	docker rmi $(docker images | grep "172.16.0.46:5000/master" | awk ' { print $3} ')
	docker rmi $(docker images | grep "172.16.0.46:5000/slave" | awk ' { print $3} ')
	docker rmi $(docker images | grep "172.16.0.46:5000/client" | awk ' { print $3} ')
  print_log "========Finish the clearing in local========"
}

clearImages 


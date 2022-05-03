#!/bin/bash

#VARS
targets=""
targets_up=0
targets_down=0
targets_total=0

#COLOR
R='\033[0;31m'
G='\033[0;32m'
O='\033[0;33m'
NC='\033[0m' # No Color

#FUNCTIONS
banner () {
 cat $(pwd)/banner.txt
}

check_args() {
 echo -e "$O[!] Parsing command line arguments...$NC"
 sleep 0.1
 #arg1 = targets file
 if [ "$#" -gt 0 ];then
  echo -e "$G[OK] targets file arg ok!$NC"
  #check file exists
  if [ -f "$1" ]; then
   echo -e "$G[OK] targets file exists!$NC"
   targets=$1
   #DEBUG: echo $targets
  else
   echo -e "$R[NO] targets file not exists, leaving...$NC"
   exit -1
  fi
 else
  echo -e "$R[NO] targets file arg missing, leaving...$NC"
  exit -1
 fi
}

check_nmap() {
 echo -e "$O[!] Check if nmap is installed...$NC"
 which nmap 1>/dev/null
 sleep 0.1
 if [ "$?" -eq 0 ]; then
  echo -e "$G[OK] nmap is installed!$NC"
 else
  echo -e "$R[NO] nmap is not installed, leaving...$NC"
  exit -2
 fi
}

do_nmap(){
 #PING SCAN
 echo -e "$O[!] Check if hosts are reachable...$NC"
 $(which nmap) -vv -sn -iL $targets 1>/dev/null -oA nmap_ping_$targets
 targets_up=$(cat nmap_ping_$targets.gnmap | grep "Status: Up" | wc -l)
 targets_down=$(cat nmap_ping_$targets.gnmap | grep "Status: Down" | wc -l)
 targets_total=$(($targets_up + $targets_down))
 if [ "$targets_up" -gt 0 ]; then
  echo -e "$G[OK] $targets_up/$targets_total hosts reachable!$NC"
 else
  echo -e "$R[NO] No hosts reachable, leaving...$NC"
  exit -3
 fi
 #TCP SCAN
 for target in $(cat nmap_ping_$targets.gnmap | grep "Status: Up" | cut -d " " -f 2)
 do
  echo -e "$O[!] Starting quick TCP Scan for $target...$NC"
  mkdir -p ./$target/
  $(which sudo) $(which nmap) -sS -T5 -p- $target 1>/dev/null -oA ./$target/nmap_tcp_quick_fullport
  if [ "$?" -eq 0 ]; then
   echo -e "$G[OK] Quick TCP Scan for $target completed!$NC"
   echo -e "$O[!] Starting TCP Service Discovery Scan for $target...$NC"
   ports=$(cat ./$target/nmap_tcp_quick_fullport.nmap | grep open |  cut -d"/" -f1 |  tr "\n" ",")
   ports=${ports::-1}
   $(which sudo) $(which nmap) -sTV -T4 -p$ports $target 1>/dev/null -oA ./$target/nmap_tcp_discovery_openport
   if [ "$?" -eq 0 ]; then
    echo -e "$G[OK] TCP Service Discovery Scan for $target completed!$NC"  
   else
    echo -e "$R[NO] TCP Service Discovery Scan for  $target failed!$NC"
    exit -5
   fi
  else
   echo -e "$R[NO] Quick TCP Scan for $target failed!$NC"
   exit -4
  fi 
 done 
 #UDP SCAN TOP 30
 
}


#MAIN
banner
check_args $@
check_nmap
do_nmap

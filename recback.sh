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
  $(which sudo) $(which nmap) -sA -T5 $target 1>/dev/null -oA nmap_tcp_quick_$target
  if [ "$?" -eq 0 ]; then
   echo -e "$G[OK] Quick TCP Scan for $target completed!$NC"
  else
   echo -e "$R[NO] Quick TCP Scan for $target failed!$NC"
   exit -4
  fi 
 done 
 #UDP SCANcat
 
}

banner
check_args $@
check_nmap
do_nmap

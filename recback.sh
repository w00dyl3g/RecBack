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
 echo ""
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
 echo ""
}

check_tool() {
 echo -e "$O[!] Check if $1 is installed...$NC"
 which $1 1>/dev/null
 sleep 0.1
 if [ "$?" -eq 0 ]; then
  echo -e "$G[OK] $1 is installed!$NC"
 else
  echo -e "$R[NO] $1 is not installed, leaving...$NC"
  exit -2
 fi
 echo ""
}

ping_nmap(){
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
}

tcp_nmap(){
 #TCP SCAN
 for target in $(cat nmap_ping_$targets.gnmap | grep "Status: Up" | cut -d " " -f 2)
 do
  echo -e "\n$O[!] TCP Scan for $target...$NC"
  mkdir -p ./$target/
  $(which sudo) $(which nmap) -sS -T5 -p- $target 1>/dev/null -oA ./$target/nmap_tcp_quick_fullport
  if [ "$?" -eq 0 ]; then
   echo -e "$G[OK] Quick TCP Scan for $target completed!$NC"
   ports=$(cat ./$target/nmap_tcp_quick_fullport.nmap | grep open |  cut -d"/" -f1 |  tr "\n" ",")
   if [ "$ports" = "" ];then
    echo -e "$R[NO] TCP Service Discovery Scan for $target completed, but no open port found!$NC"
   else
    ports=${ports::-1}
    $(which sudo) $(which nmap) -sTV -T4 -p$ports $target 1>/dev/null -oA ./$target/nmap_tcp_discovery_openport
    if [ "$?" -eq 0 ]; then
     echo -e "$G[OK] TCP Service Discovery Scan for $target completed!$NC"  
    else
     echo -e "$R[NO] TCP Service Discovery Scan for  $target failed!$NC"
     exit -5
    fi
   fi
  else
   echo -e "$R[NO] Quick TCP Scan for $target failed!$NC"
   exit -4
  fi 
 done
 echo ""
}

udp_nmap(){
 #UDP SCAN TOP 30
 for target in $(cat nmap_ping_$targets.gnmap | grep "Status: Up" | cut -d " " -f 2)
 do
  echo -e "\n$O[!] UDP Scan for $target...$NC"
  mkdir -p ./$target/
  $(which sudo) $(which nmap) -sU -T5 $target 1>/dev/null -oA ./$target/nmap_udp_quick_defaultport
  if [ "$?" -eq 0 ]; then
   echo -e "$G[OK] Quick UDP Scan for $target completed!$NC"
   ports=$(cat ./$target/nmap_udp_quick_defaultport.nmap | grep open |  cut -d"/" -f1 |  tr "\n" ",")
   if [ "$ports" = "" ];then
    echo -e "$R[NO] UDP Service Discovery Scan for $target completed, but no open port found!$NC"
   else
    ports=${ports::-1}
    $(which sudo) $(which nmap) -sUV -T4 -p$ports $target 1>/dev/null -oA ./$target/nmap_udp_discovery_openport
    if [ "$?" -eq 0 ]; then
     echo -e "$G[OK] UDP Service Discovery Scan for $target completed!$NC"  
    else
     echo -e "$R[NO] UDP Service Discovery Scan for  $target failed!$NC"
     exit -5
    fi
   fi
  else
   echo -e "$R[NO] Quick UDP Scan for $target failed!$NC"
   exit -4
  fi 
 done
 echo ""
}


http_scan(){
 #get hosts
 for target in $(cat nmap_ping_$targets.gnmap | grep "Status: Up" | cut -d " " -f 2)
 do
  for service in $(cat $target/nmap_tcp_discovery_openport.nmap | grep http | grep open | grep tcp | cut -d"/" -f1 )
  do
   service_detail=$(cat ./$target/nmap_tcp_discovery_openport.nmap | grep $service | grep open | grep http)
   if [[ "ssl/http" == *"$service_detail"* ]];
   then
    url="https://$target:$service/"
    echo -e "$O[!] Starting nikto for $url...$NC"
    yes | nikto -host $url -nointeractive -ssl -output $target/nikto-$service.txt 1>/dev/null
    echo -e "$G[!] Nikto ended for $url!$NC\n"
   else
    url="http://$target:$service/"
    echo -e "$O[!] Starting nikto for $url...$NC"
    yes | nikto -host $url -nointeractive -output $target/nikto-$service.txt 1>/dev/null
    echo -e "$G[!] Nikto ended for $url!$NC\n"
   fi
   echo -e "$O[!] Starting dirsearch for $url...$NC"
   sudo dirsearch -u $url -o $(pwd)/$target/dirsearch-$service.txt --full-url --max-time=300 -r 1>/dev/null
   echo -e "$G[!] Dirsearch ended for $url!$NC\n"
  done
 done
} 


#MAIN
banner
check_args $@
check_tool nmap
ping_nmap
tcp_nmap
udp_nmap
check_tool dirsearch
check_tool nikto
check_tool whatweb
http_scan
#TBC




#!/bin/bash

#VARS
targets=""
tools=("nmap" "gobuster" "nikto" "nuclei" "sslscan" "whatweb" "dirsearch" "wfuzz" "sqlmap" "nonexist")
web_tools=("gobuster" "dirsearch" "wfuzz" "ffuf")


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
   echo $targets
  else
   echo -e "$R[NO] targets file not exists, leaving...$NC"
   return -1
  fi
 else
  echo -e "$R[NO] targets file arg missing, leaving...$NC"
  return -1
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
  return -2
 fi
}

do_nmap(){
 sleep 0.1
}

banner
check_args $@
check_nmap
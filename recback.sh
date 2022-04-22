#!/bin/bash

tools=("nmap" "gobuster" "nikto" "nuclei" "sslscan" "whatweb" "dirsearch" "wfuzz" "sqlmap" "nonexist")

banner () {
 cat $(pwd)/banner.txt
}

for tool in ${tools[@]}; do
  which $tool
  if [ "$?" -eq 0 ]; then
    echo ok
  fi
done

#!/bin/bash
 
TMP=`sudo mysqladmin -u root status 2>&1 | head -n 1 | cut -f1 -d:`
case ${TMP} in
Uptime)
        echo "MySQL is running."
        echo "You are good"
;;
*)
        sudo mysqld
;;
esac
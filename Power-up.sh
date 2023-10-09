#!/bin/sh
#Script to start backup server over IPMI
ipmitool -I lanplus -H 192.168.10.82 -U Adminole -P Adminole power up
echo "Backup server startet"

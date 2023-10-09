#!/bin/sh
##################################
#Exit codes                      #
#0 = all good                    #
#3 = not in timerange for backups#
#4 = timeout waiting for backups #
##################################

echo "$(date +"%Y-%m-%d_%T") || The holy script's been summoned!"
# Check if we're roughly in time for the automated backups
currenttime=$(date +%H:%M)
   if [[ "$currenttime" > "03:30" ]] && [[ "$currenttime" < "04:30" ]]; then
         echo "$(date +"%Y-%m-%d_%T") || We're in time!"
   else
         echo "$(date +"%Y-%m-%d_%T") || No time for backups, going back to bed :("
     exit 3
   fi

#Wait for replication to begin
echo "$(date +"%Y-%m-%d_%T") || Waiting for replication to begin."
timeout=0
procsalive=0
while [[ $procsalive -eq 0 ]]; do
        procsalive=$(ps -U root -axwwo lstart,command | grep 'python3 -u /tmp/zettarepl' | grep -v grep | grep -v middlewared | wc -l | awk '{print $1}')
        timeout=$((timeout+1))
        echo "$(date +"%Y-%m-%d_%T") || No job found so far (waited for: ${timeout}s)"
        if [[ $timeout -ge 3600 ]]; then
                echo "$(date +"%Y-%m-%d_%T") || No job started within an hour, I'm going back to bed."
                exit 4
        fi
        sleep 1
done
echo "$(date +"%Y-%m-%d_%T") || Yay, a replication job started! I'll wait for it to finish now."

# Wait for replication to finish
unset procsalive
proccount=0
zettacount=0
until [[ $proccount -ge 60 ]] && [[ $zettacount -eq 1 ]]; do
        procsalive=$(ps -U root -axwwo lstart,command | grep 'python3 -u /tmp/zettarepl' | grep -v grep | grep -v middlewared | wc -l | awk '{print $1}')
        if [[ $procsalive -eq 0 ]]; then
                proccount=$((proccount+1))
        else
                proccount=0
        fi
        zettaresult=$(tail -n 1  /var/log/zettarepl.log | grep '\[retention\]' | wc -l | awk '{print $1}')
        if [[ $zettaresult -eq 1 ]]; then
                zettacount=1
        else
                zettacount=0
        fi
        sleep 1
done
echo "$(date +"%Y-%m-%d_%T") || Seems as if all replication jobs finished! Let's shut this bad boy down again."

shutdown -p +180s "Backups have been finished, shutting down."
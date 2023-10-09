#!/bin/bash


#Script to turn off a "cold storage" TrueNAS server after a replication is done. This is a bad replacement for repl.pid.
#This script should run on the server to be turned off and requires root.
#This script will shut off a server if it detects <1 kb of transfers over 10 seconds on the selected interface.
#Since interfaces are rarely completely quiet, it tends to fail randomly now and then. You can coarsely tune the sensitivity
#by choosing ratelimit 0-4, where 0 is < 1 kb, 1 is < 1 Mb, 2 is < 1 Gb and 3 is anything that is not those. 0 and 1 are sane.

#The script also checks if your main NAS is running, and will not shut down the back-up NAS if the main NAS is down,
#thus providing access to the back-up NAS in case of hardware failure.

#Uncomment echo lines for verbose operation/testing.
#Configurations:
ratelimit=0
#Modify to match your main NAS IP or set 127.0.0.1 to disable
mainNAS="192.168.10.210"
interface="igb0"

while :
do


#	Ping main NAS to see if it's up.  -quiet, -count 1, -timeout 1 second.
	ping -q -c 1 -t 1 $mainNAS > /dev/null

#	The following line checks if the exit status of the ping command equals 0. 
#	If ping returns 0, we know that the main NAS is up, so we want to shut down the backup NAS once it's done replicating.

	if [[ $? -eq 0 ]]
	then


#The following function checks if there is traffic on interface. $traffic will contain the bitrate
#of the interface as reported by iftop. Awk parses the iftop output and returns the
#1-second average on $6, 10-second average on $7 and 40-second average on $8.
#Iftop is fairly slow and potentially resource intensive, so I choose to run it for 10 seconds by using -s 10
#and check $7 for the 10-second average. I do not recommend using the 1-second average, as
#replication sometimes will not be transferring data, so this might cause premature shutdowns.


		traffic=$( iftop -i $interface -t -s 10 -n -N 2>/dev/null | awk '/send and receive/ {print ($7)}' )

		echo "Traffic is:"
		echo $traffic


#The following if clause parses the data returned from iftop and awk and determines how much data is being moved.
#The rate variable contains the result. I have no idea what a value of 3 means. Gb?


		if [[ "$traffic" == *"Mb"* ]]
		then
			rate=2
		elif [[ "$traffic" == *"Kb"* ]]
		then
			rate=1
		elif [[ "$traffic" == *"b"* ]]
		then
			rate=0
		else
			rate=3
		fi
		
#The following if clause checks if the transfer rate is below the threshold specified up top, and shuts the server down
#if it's below the threshold. A 5-minute grace period is inserted before shutdown, just in case.
#If traffic is above the threshold, the server is not shut down, and the script waits for 10 minutes before starting over.


		if (( $rate <= $ratelimit ))
		then
			echo "Main NAS pingable, traffic below limit. Replication should be done, shutting down in 5 minutes."
			echo "Traffic is:"
			echo $traffic
			sleep 300
			shutdown -p now
			break

		else
			echo "Traffic on network, not shutting down. Re-check in 10 minutes. Rate:"
			echo $traffic
			sleep 600
		fi
	

#If ping returns other than 0, the main NAS is not up, and we want the backup NAS to remain on and accessible.
#The script will turn the backup NAS off as soon as the main NAS becomes pingable again.

	else
		echo "Ping not ok, main NAS is not available. Backup NAS remains on. Re-check in 10 minutes."
		sleep 600
fi
done


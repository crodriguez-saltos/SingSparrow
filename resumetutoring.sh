#!/usr/bin/env bash

# This utility restarts singsparrow, as it appears in the crontab. It is useful when restarting the program after an unexpected shutdown. It is recommended to use it as a cron job every 10 minutes.

wd="/home/pi/SingSparrow"
cd $wd

proclist=$1

on=1

for i in $(seq 1 $(cat $proclist | wc -l)); do
	proc=$(sed -n "$i"p $proclist)
	pid=$(ps -eaf | grep "$proc" | grep -v "grep" | awk '{print $2}')
	if [ "$pid" == "" ]; then
		on=0
		break
	fi
done

if [ "$on" == "0" ]; then
	./shutsparrow.sh $proclist
	singsp=$(crontab -l | grep "$wd" | grep -v "shutsparrow" | awk '{print $7}')
	$singsp
else
	echo "All processes running."
fi



#!/usr/bin/env bash

# Get PIDs from a text file and kill corresponding processes
proclist=$1

echo "Closing SingSparrow soon..."
sleep 1

for i in $(seq 1 $(cat $proclist | wc -l)); do
	proc=$(sed -n "$i"p $proclist)
	pid=$(ps -eaf | grep "$proc" | grep -v "grep" | awk '{print $2}')
	echo Closing PID $pid
	kill $pid
done

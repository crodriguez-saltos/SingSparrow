#!/usr/bin/env bash

# Get PIDs from a text file and kill corresponding processes

echo "Closing SingSparrow soon..."
sleep 5

for i in $(seq 1 $(cat processes | wc -l)); do
	proc=$(sed -n "$i"p processes)
	pid=$(ps -eaf | grep "$proc" | grep -v "grep" | awk '{print $2}')
	echo $pid
	kill $pid
done

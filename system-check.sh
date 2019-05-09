#!/usr/bin/env bash

# Get info on current bird.
bird=$(cat /home/pi/SingSparrow_data/parameters_opyok.txt | grep "bird = " | sed "s/bird = \(.*\)/\1/")
printf "Bird is $bird\n"

printf "Opening most recent welcome message...press q when finishing reading it.\n"
sleep 1
less welcome.txt
printf "\n"

cd "/home/pi/SingSparrow_data/output/$bird"

# Is there an output file for today
today=$(date +%Y%b%d)
todayfile=$(ls *$today*$bird*txt)

if [ "$(echo $todayfile | wc -l)"  == "1" ]; then
	printf "There is an output file for today.\n"
	printf "The file will be loaded. Press q when finishing checking it.\n"
	sleep 1
	less $todayfile
fi

# When was the last time that each key was pressed?
printf "This is the last record of key 1 being pressed:\n"
cat * | grep "^1" | sort | tail -n 1

printf "\nThis is the last record of key 2 being pressed:\n"
cat * | grep "^2" | sort | tail -n 1

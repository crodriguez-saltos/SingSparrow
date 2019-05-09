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

# How many playbacks have been made?
printf "\nToday, song 1 has been played "
cat $todayfile | cut -d "," -f 2 | grep "1" | wc -l
printf " times and song 2 has been played "
cat $todayfile | cut -d "," -f 2 | grep "2" | wc -l

day=$(echo $todayfile | sed "s/.*day-\([0-9]*\).*/\1/")
printf "\nIt is day $day of the experiment, and song 1 has been played "
cat * | cut -d "," -f 2 | grep "1" | wc -l
printf "times in total and song 2 "
cat * | cut -d "," -f 2 | grep "2" | wc -l
printf "times in total.\n"

model=$(echo $todayfile | sed "s/.*Model-\([^_]*\).*/\1/")
printf "\nIn the same amount of time, the model bird, $model, played father song "
modelpbs=$(mktemp)
for i in $(seq 1 $day); do
	file=$(ls /home/pi/SingSparrow/models/$model\_modelpb/*day$(printf "%03d" $i)*)
	cat $file >> $modelpbs
done

cat $modelpbs | cut -d "," -f 1 | grep "foster" | wc -l
printf " times and neighbor song "
cat $modelpbs | cut -d "," -f 1 | grep "alien" | wc -l
printf " times (if type of control is reverse, then the count for father corresponds to that of song 2, and of neighbor song to that of song 1).\n"



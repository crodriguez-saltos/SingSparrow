#!/usr/bin/env bash

# Prompt
printf "Welcome to the key press simulator from SingSparrow\n"
printf "This program was written by Carlos Antonio Rodriguez-Saltos, 2018\n\n"

printf "Press the 'a' key to simulate presses on the left key\n"
printf "Press the 'z' key to simulate presses on the right key\n"
printf "The program will note if no press was made within the last 0.5 seconds'\n\n"

printf "To exit, type Ctrl+C\n"

# Start the simulated matrix of key presses
file="./sim-presses.txt"

if [ -f $file ]; then
    rm $file
fi

for i in $(seq 0 1); do
    printf "0 0\n" >> $file
done

# Scan for presses
nextline=1
while :; do    
    # Responses when keys are pressed
    read -n 1 -t 0.5 -s char
    if [ "$char" == "a" ]; then
	echo "Left key was pressed."
	sed -i "${nextline}s/.*/1 0/" $file
    elif [ "$char" == "z" ]; then
	echo "Right key was pressed."
	sed -i "${nextline}s/.*/0 1/" $file
    else
	# Record no press
	sed -i "${nextline}s/.*/0 0/" $file
    fi
    nextline=$(($nextline % 2 + 1))
done

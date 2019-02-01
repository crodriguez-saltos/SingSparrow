#!/usr/bin/env bash

# Load variables
file=$1
channel=$2
pause=$3

# Prompt
printf "Welcome to the key press simulator from SingSparrow\n"
printf "This program was written by Carlos Antonio Rodriguez-Saltos, 2018\n\n"

printf "Press the \'$channel\' key to simulate a keypress"
printf "The program will note if no press was made within the last $pause seconds'\n\n"

printf "To exit, type Ctrl+C\n"

# Scan for presses
while :; do    
    # Responses when keys are pressed
    read -n 1 -t $pause -s char
    if [ "$char" == "$channel" ]; then
	#echo "Key was pressed."
	echo 1
	printf "1\n" > $file
    else
	# Record no press
	echo 0
	printf "0\n" > $file
    fi
    #sleep 0.1
    #printf "0 0\n" > $file
done

#!/usr/bin/env bash

# Load variables
file=$1
channel=$2
pause=$3

# Prompt
printf "Welcome to the GPIO capture module\n"
printf "Written by Carlos Antonio Rodriguez=Saltos, 2019. bio.carodrgz@gmail.com"

printf "Press the $channel key to send signal"

# Set the keys
if [ "$channel" == "1" ]; then
	bcm=23
	wiringpi=4
elif [ "$channel" == "2" ]; then
	bcm=25
	wiringpi=6
fi

python gpio_setup.py $bcm
gpio mode $wiringpi in

# Scan the key
while :; do
	scan=$(gpio read $wiringpi)
	if [ "$scan"  == "0" ]; then
		echo 1
		printf "1\n" > $file
	else
		# Record no press
		echo 0
		printf "0\n" > $file
	fi
	sleep $3
done

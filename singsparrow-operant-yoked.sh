#!/usr/bin/env bash

# Should the playlist position be reset?
while getopts "r" option
do
	case "${option}"
	in
		r) reset=1;;
	esac
done

# This utility launches singsparrow in operant-yoked mode. It is most useful in combination with cron.
program="/home/pi/SingSparrow/singsparrow.sh -s rpi -k gpio -p /home/pi/SingSparrow_data/parameters_opyok.txt"

if [ "$reset" == "1" ]; then
	$program -r
else
	$program
fi

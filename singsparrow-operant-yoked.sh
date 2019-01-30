#!/usr/bin/env bash

# This utility launches singsparrow in operant-yoked mode. It is most useful in combination with cron.
/home/pi/SingSparrow/singsparrow.sh -s rpi -k gpio -r -p /home/pi/SingSparrow/parameters.txt

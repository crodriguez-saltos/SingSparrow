#!/usr/bin/env bash

# This utility launches singsparrow in operant-yoked mode. It is most useful in combination with cron.
/home/pi/SingSparrow/singsparrow.sh -s rpi -k gpio -p /home/pi/SingSparrow_data/parameters_opyok.txt

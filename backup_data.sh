#!/usr/bin/env bash

# Back up data from SingSparrow

# Go to data folder
cd /home/pi/SingSparrow_data

# Git Pi's booth id
booth=$(cat parameters_opyok.txt | grep "booth = " | sed "s/booth = \(.*\)/\1/")

# Git push
printf "For this back-up to proceed, you must have authorized access to the backup repository.\n"
printf "Back-up will start now. You will be asked to enter your GitHub login credentials.\n"
printf "For info on back-up repository check the file /home/pi/SingSparrow_data/backup.conf.\n"

sleep 0.3

git add *
git commit -m "Back-up data from booth $booth"
git push

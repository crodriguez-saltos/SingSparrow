#!/usr/bin/env bash

echo "This is the installation utility for SingSparrow Operant Yoked mode"

# Apparently, the Raspberry Pi does not have system sounds, so no need to deactivate them.

# Schedule Rpi to run on a daily basis
echo "00 08 * * * DISPLAY=:0 /home/pi/SingSparrow/singsparrow-operant-yoked.sh" > mycron
echo "00 19 * * * /home/pi/SingSparrow/shutsparrow.sh /home/pi/SingSparrow/processes" >> mycron
crontab mycron
rm mycron

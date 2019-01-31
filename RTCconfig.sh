#!/usr/bin/env bash

echo "Run this script as superuser (ie. sudo)"

# Remove onboard sound
sed -i "s/^dtparam=audio=on$/#dtparam=audio=on/" /boot/config.txt

# The following is text that should be written in /boot/config.txt in order to install the Real Time Clock from HiFi Berry.

printf "\n#HiFi Berry\n" >> /boot/config.txt
echo "dtoverlay=i2c-rtc,ds1307" >> /boot/config.txt
echo "dtoverlay=hifiberry-dac" >> /boot/config.txt
echo "dtparam=i2c_arm=on" >> /boot/config.txt

# The following must be written to /etc/modules
echo "i2c-bcm2835" >> /etc/modules
echo "i2c-dev" >> /etc/modules
echo "rtc-ds1307" >> /etc/modules

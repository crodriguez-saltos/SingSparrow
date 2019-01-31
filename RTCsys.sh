#!/usr/bin/env bash

echo "Run this script logged in as su"

echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device

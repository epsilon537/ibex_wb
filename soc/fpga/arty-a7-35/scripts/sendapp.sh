#!/bin/sh
# Script for sending image to Ibex bootloader.
filename=$1
imagesize=$(wc -c < $filename)
echo $imagesize > /dev/ttyUSB1
cat $filename > /dev/ttyUSB1
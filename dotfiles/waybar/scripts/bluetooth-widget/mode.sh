#!/bin/bash

INPUT=`cat current`

if [[ "$INPUT" == "0" ]]; then
	bluetoothctl power off
	echo "1" > ./current
else
	bluetoothctl power on
	echo "0" > ./current
fi




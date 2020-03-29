#!/bin/bash

# display status with tput (man tput) - see move_cursor.sh
echo "Abort with [Ctrl]+[C]"

while :; do
	echo "Status 1: $RANDOM"
	echo "Status 2: $RANDOM"
	echo "Status 3: $RANDOM"
	sleep 0.2
	tput cuu1 # move cursor up by one line
	tput el # clear the line
	tput cuu1; tput el
	tput cuu1; tput el
done

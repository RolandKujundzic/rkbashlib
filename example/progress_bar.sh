#!/bin/bash

#--
#
#--
function createProgressSequence {
	for n in $(seq 1 100); do 
		sleep 0.02

		if test "$1" = "1"; then
			echo -e "XXX\n$n\nMessage 1\nMessage 2\nXXX"
		else
			echo -e "XXX\n$n\nLabel\n\nMessage 1\nMessage 2\nXXX"
		fi
	done
}


#--
#
#--
function readProgressPipe {
	trap "rm -f $1" EXIT
	test -p "$1" || mkfifo "$1"

	local line
	while true; do
		if read line <"$1"; then
			test "$line" = 'done.' && break
			echo "$line"
		fi
	done
}


#--
#
#--
function writeProgressPipe {
	test -p "$1" || { echo -e "\nERROR: no such pipe $1\n"; exit 1; }

	for n in $(seq 1 100); do 
		sleep 0.1

		if test "$2" = "1"; then
			echo -e "XXX\n$n\nMessage 1\nMessage 2\nXXX" > "$1" &
		elif test "$2" = "2"; then
			echo "$n" > "$1" &
		else
			echo -e "XXX\n$n\nLabel\n\nMessage 1\nMessage 2\nXXX" > "$1" &
		fi
	done
	
	echo "done." > "$1"
}


#--
#
#--
function fifo_test {
	local FIFO="/dev/shm/rkscript.example.progress_bar"
	readProgressPipe "$FIFO" | dialog --gauge "" 10 70 0 &
	writeProgressPipe "$FIFO" &
	exit 0
}


#--
# M A I N
#--

#fifo_test

createProgressSequence | dialog --gauge "" 10 70 0

# use --gauge "\n\n" to reserve 2 infolines
createProgressSequence 1 | whiptail --title Label --gauge "\n\n" 10 70 0


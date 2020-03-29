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
function createProgressPipe {
	test -p "$1" || mkfifo "$1"
	# test -f "$1" && rm $1

	for n in $(seq 1 100); do 
		echo -e "\rcreateProgressPipe: n=$n"
		sleep 0.1

		if test "$2" = "1"; then
			echo -e "XXX\n$n\nMessage 1\nMessage 2\nXXX" >> $1 &
		elif test "$2" = "2"; then
			echo "$n" >> $1 &
		else
			echo -e "XXX\n$n\nLabel\n\nMessage 1\nMessage 2\nXXX" >> $1 &
		fi
	done
}


#--
#
#--
function fifo_test {
	createProgressPipe /dev/shm/progress_bar 2 &
#	cat /dev/shm/progress_bar | dialog --gauge "" 10 70 0
}


#--
# M A I N
#--

# fifo_test

createProgressSequence | dialog --gauge "" 10 70 0

# use --gauge "\n\n" to reserve 2 infolines
createProgressSequence 1 | whiptail --title Label --gauge "\n\n" 10 70 0


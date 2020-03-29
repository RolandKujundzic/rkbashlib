#!/bin/bash

function createProgressSequence {
	for n in $(seq 1 100); do 
		echo "n=$n"
		sleep 0.02

		if test "$1" = "1"; then
			echo -e "XXX\n$n\nMessage 1\nMessage 2\nXXX"
		elif ! test -z "$1" && test -p "$1"; then
			echo -e "XXX\n$n\nLabel\n\nMessage 1\nMessage 2\nXXX" > $1
		else
			echo -e "XXX\n$n\nLabel\n\nMessage 1\nMessage 2\nXXX"
		fi
	done
}


function fifo_test {
	FIFO=/dev/shm/progress_bar
	test -p $FIFO && rm $FIFO
	mkfifo $FIFO

	createProgressSequence $FIFO &
#	cat $FIFO | pv
}


#--
# M A I N
#--

#fifo_test

createProgressSequence | dialog --gauge "" 10 70 0

# use --gauge "\n\n" to reserve 2 infolines
createProgressSequence 1 | whiptail --title Label --gauge "\n\n" 10 70 0


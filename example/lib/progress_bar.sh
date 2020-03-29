#!/bin/bash

. lib/rkscript.sh || { echo "ERROR: . lib/rkscript.sh"; exit 1; }


#--
#
#--
function testProgressFile {
	_PROGRESS_FILE="/dev/shm/rkscript.progress_bar"
	_PROGRESS_MAX=100

	PROGRESS=0
	echo $PROGRESS > $_PROGRESS_FILE

	while [[ $PROGRESS -lt $_PROGRESS_MAX ]]; do
		RND=`shuf -i 1-10 -n 1`
		let PROGRESS=($PROGRESS+$RND)
		echo -n $PROGRESS > $_PROGRESS_FILE
		_progress_bar
	done
}


#--
# M A I N
#--

for n in $(seq 1 100); do sleep 0.02; _progress_bar $n; done
for n in $(seq 1 50); do sleep 0.1; _progress_bar $n 50 "2;Style 2;with Message"; done

for a in 3 d31 d32 d33 d34 d35 d36 l31 l32 l33 l34 l35 l36; do
	for n in $(seq 1 20); do sleep 0.1; _progress_bar $n 20 "$a;Bar;Color $a"; done
done

testProgressFile

exit 1

# echo "use dialog for progress bar"
for i in $(seq 0 2 30) ; do sleep 0.2; _progress_bar $i 30 "dialog;Please wait;Some Message"; done

echo "use whiptail for progress bar"
for i in $(seq 1 100)
do
    sleep 0.1 
    echo $i
done | whiptail --title 'Test script' --gauge 'Running...' 6 60 0

echo "show progress messages with whiptail"
phases=( 
    'Locating Jebediah Kerman...'
    'Motivating Kerbals...'
    'Treating Kessler Syndrome...'
    'Recruiting Kerbals...'
)   


for i in $(seq 1 100); do  
    sleep 0.1

    if [ $i -eq 100 ]; then
        echo -e "XXX\n100\nDone!\nXXX"
    elif [ $(($i % 25)) -eq 0 ]; then
        let "phase = $i / 25"
        echo -e "XXX\n$i\n${phases[phase]}\nXXX"
    else
        echo $i
    fi 
done | whiptail --title 'Kerbal Space Program' --gauge "${phases[0]}" 6 60 0


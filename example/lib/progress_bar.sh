#!/bin/bash

. lib/rkscript.sh || { echo "ERROR: . lib/rkscript.sh"; exit 1; }


#--
# M A I N
#--

for n in $(seq 1 100); do sleep 0.01; _progress_bar $n 100 "Style 1:1"; done
for n in $(seq 1 100); do sleep 0.01; _progress_bar $n 100 "Style 2:2"; done
for n in $(seq 1 100); do sleep 0.01; _progress_bar $n 100 "Style 3:3"; done

_PROGRESS_FILE="/dev/shm/rkscript.progress_bar"
_PROGRESS_MAX=1000

echo $PROGRESS > $_PROGRESS_FILE
PROGRESS=0

while [[ $PROGRESS -le $_PROGRESS_MAX ]]; do
	RND=`shuf -i 1-10 -n 1`
	let PROGRESS=($PROGRESS+$RND)
	echo -n $PROGRESS > $_PROGRESS_FILE
	_progress_bar
done


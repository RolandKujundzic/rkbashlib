#!/bin/bash

function show {
	echo "ARR: (${ARR[@]})"
	for ((i = 0; i < ${#ARR[@]}; i++)); do
		echo "$i: [${ARR[$i]}]"
	done 
}

ARR=()
ARR[${#ARR[@]}]=27
ARR[${#ARR[@]}]="test"
show

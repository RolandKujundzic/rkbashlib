#!/bin/bash

#--
# Show progress bar. Set _PROGRESS_FILE to load $1 (use /dev/shm/...). 
# Overwrite $2 and $3 with _PROGRESS_MAX and _PROGRESS_LABEL. Styles:
#
# 1: |----
# 3: [###---]
# 3: ▇▇▇
#
# @example for n in $(seq 1 100); do sleep 0.01; _progress_bar $n; done
#
# @global _PROGRESS_FILE _PROGRESS_MAX
# @param value (<= end)
# @param end (default = 100)
# @param label (default = Progress:1 = Lable:Style)
#--
function _progress_bar {
	local val=0
	local end=100
	local label_style="Progress:1"

	test -z "$_PROGRESS_FILE" || val=`cat "$_PROGRESS_FILE"`
	test -z "$_PROGRESS_MAX" || end="$_PROGRESS_MAX"
	test -z "$_PROGRESS_LABEL" || label_style="$_PROGRESS_LABEL"

	test -z "$1" || val=$1
	test -z "$2" || end=$2
	test -z "$3" || label_style="$3"

	let local progress=($val*100/$end*100)/100
	let local done=($progress*4)/10
	let local left=40-$done

	local fill=$(printf "%${done}s")
	local empty=$(printf "%${left}s")

	local label="${label_style:0: -2}"
	local style=${label_style: -1}

	case $style in
		1)
			printf "\r$label: |${fill// /-}${empty// / } ${progress}%%    "
			;;
		2)
			printf "\r$label: [${fill// /\#}${empty// /-}] ${progress}%%    "
			;;
		3)
			printf "\r$label: ${fill// /▇}${empty// / } ${progress}%%    "
			;;
	esac
}


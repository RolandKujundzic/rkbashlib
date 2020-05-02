#!/bin/bash

#--
# Show progress bar. Third parameter is Style;Label;Mesage (default = '1;Progress;').
# Use $_PROGRESS_FILE to load progress value from file (use /dev/shm/...).
# Use $_PROGRESS_MAX|STYLE|LABEL|MSG instead of $2 and $3. Styles:
#
# 1: |----
# 2: [###---]
# 3: ▇▇▇
# d31,d32,d33,d34,d35,d36: same as 3 but in dark  red|green|yellow|blue|purple|cyan
# l31,l32,l33,l34,l35,l36: same as 3 but in light red|green|yellow|blue|purple|cyan
# dialog: use dialog
# whiptail: use whiptail
#
# @example for n in $(seq 1 100); do sleep 0.01; _progress_bar $n; done
#
# @global _PROGRESS_FILE _PROGRESS_MAX
# @param value (<= end)
# @param end (default = 100)
# @param label (default = Progress:1 = Lable:Style)
#--
function _progress_bar {
	local label style msg max slm progress pg
	label="${_PROGRESS_LABEL:-Progress}"
	style="${_PROGRESS_STYLE:-1}"
	msg="${_PROGRESS_MESSAGES}"
	max=${2:$_PROGRESS_MAX}
	slm="$style;$label;$msg"
	progress=0

	test -z "$_PROGRESS_FILE" || progress=$(cat "$_PROGRESS_FILE")
	test -z "$1" || progress=$1
	test -z "$max" && max=100
	test -z "$3" || slm="$3"

	IFS=";" read -ra pg <<< "$progress;$max;$slm"

	case ${pg[2]} in
		1|2|3|d31|d32|d33|d34|d35|d36|l31|l32|l33|l34|l35|l36)
			_progress_bar_printf "$progress;$max;$slm"
			;;
		dialog)
			progress=$(( (progress*100) / max ))
			echo -e "XXX\n$progress\n$label\n\n$msg\nXXX" | dialog --gauge "" 10 70 0
			;;
		whiptail)
			echo "ToDo ... whiptail"
			;;
	esac
}


#--
# Create custom progress bar with printf and \r.
# @param progress;max;style;label;message
#--
function _progress_bar_printf {
	local pg progress finished left fill empty
	IFS=";" read -ra pg <<< "$1"

	progress=$(( (pg[0] * 100) / pg[1] ))
	finished=$(( (progress * 4) / 10 ))
	left=$(( 40 - finished ))
	fill=$(printf "%${finished}s")
	empty=$(printf "%${left}s")

	local color="${pg[2]}"
	if [ "${color:0:2}" = "d3" ]; then
		color="0;${color:1}m"
		pg[2]="color_bar"
	elif [ "${color:0:2}" = "l3" ]; then
		color="1;${color:1}m"
		pg[2]="color_bar"
	fi

	local label="${pg[3]}"
	let ccol=${#label}+1

	printf "\n\e[A\e[K"

	case ${pg[2]} in
		1)
			printf "$label:  |${fill// /-}${empty// / } ${progress}%%"
			;;
		2)
			printf "$label:  [${fill// /\#}${empty// /-}] ${progress}%%"
			;;
		3)
			printf "$label:  ${fill// /▇}${empty// / } ${progress}%%"
			;;
		color_bar)
			printf "$label:  \e[${color}${fill// /▇}${empty// / }\e[0m ${progress}%%"
			;;
	esac

	local msg="${pg[4]}"
	local msg_len="${#msg}"
	printf "\n\e[K%s\e[A\e[%sD\e[%sC" "$msg" "$msg_len" "$ccol"
}


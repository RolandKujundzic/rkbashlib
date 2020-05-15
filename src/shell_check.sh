#!/bin/bash

#--
# Run shellcheck for *.sh files in directory $1 and subdirectories
# @param directory
# shellcheck disable=SC2034
#--
function _shell_check {
	_require_dir "$1"
	local sh_files file
	sh_files=( $(find "$1" -name '*.sh' 2>/dev/null) )

	PROGRESS_MAX=${#sh_files[@]}
	PROGRESS_LABEL="shellcheck"
	for ((PROGRESS_VALUE=0; PROGRESS_VALUE < ${#sh_files[@]}; PROGRESS_VALUE++)); do
		file="${sh_files[$PROGRESS_VALUE]}"
		PROGRESS_MSG="$file"
		_progress_bar "$PROGRESS_VALUE"
		shellcheck "$file" &>/dev/null || _abort "shellcheck $file"
	done
}


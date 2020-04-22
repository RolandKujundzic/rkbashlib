#!/bin/bash

#--
# Create tgz archive $1 with files from file/directory list $2.
# If existing archive changed ask otherwise keep.
#
# @param tgz_file
# @param directory/file list
#--
function _create_tgz {
	test -z "$1" && _abort "Empty archive path"

	local a
	for a in $2; do
		if ! test -f $a && ! test -d $a; then
			_abort "No such file or directory $a"
		fi
	done

	# compare existing archive
	if test -s "$1"; then	
		if tar -d --file="$1" $2 >/dev/null 2>/dev/null; then
			return
		else
			_confirm "Update archive $1?" 1
			test "$CONFIRM" = "y" || _abort "user abort"
		fi
	fi

  _msg "create archive $1"
  SECONDS=0
  tar -czf "$1" $2 >/dev/null 2>/dev/null || _abort "tar -czf '$1' $2 failed"
  _msg "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "invalid archive '$1'" 
}


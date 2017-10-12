#!/bin/bash

#------------------------------------------------------------------------------
# Create tgz archive $1 with files from file/directory list $2.
#
# @param tgz_file
# @param directory/file list
# @require _abort
#------------------------------------------------------------------------------
function _create_tgz {

	for a in $2
	do
		if ! test -f $a && ! test -d $a
		then
			_abort "No such file or directory $a"
		fi
	done

	if test -z "$1"; then
		_abort "Empty archive path"
	fi

  echo "create archive $1"
  SECONDS=0
  tar -czf $1 $2 || _abort "tar -czf $1 $2 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 
}


#!/bin/bash

#------------------------------------------------------------------------------
# Abort with error message.
#
# @param abort message
#------------------------------------------------------------------------------
function _abort {
  echo -e "\nABORT: $1\n\n" 1>&2
  exit 1
}


#------------------------------------------------------------------------------
# Check if @require in file contains all functions from use_function
#
# @param string file
# @param string use_function
#------------------------------------------------------------------------------
function _check_require {
	local REQUIRE=`grep @require $1`" "
	local FOUND=

	echo "$1 requires: $2"

	for a in $2; do
		FOUND=`echo "$REQUIRE" | grep "$a "`
		if test -z "$FOUND"; then
			_abort "missing $a in @require of $1"
		fi
	done
}


#------------------------------------------------------------------------------
# Scan src/* directory.
#------------------------------------------------------------------------------
function _scan_src {
	FUNCTIONS=

	for a in src/*.sh; do
		F="_"${a:4:-3}
		FUNCTIONS="$F $FUNCTIONS"
	done

	for a in src/*.sh; do
		USE=
		F="_"${a:4:-3}

		for b in $FUNCTIONS; do
			c=`cat $a | sed -e "s/function .*//" | grep "$b "`
			if ! test -z "$c" && test "$F" != "$b"; then
				USE="$b $USE"
			fi
		done

		_check_require $a "$USE"
	done
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

_scan_src

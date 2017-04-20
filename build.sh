#!/bin/bash
MERGE2RUN="abort md5 cp build"


#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#


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
# Print md5sum of file.
#
# @param file
# @require abort
# @print md5sum
#------------------------------------------------------------------------------
function _md5 {

	if test -z "$1" || ! test -f "$1"
	then
		_abort "No such file [$1]"
	fi

	local has_md5=`which md5`
	local md5=

	if test -z "$has_md5"
	then
		# on Linux
		md5=($(md5sum "$1"))
	else
		# on OSX
		md5=`md5 -q "$1"`
	fi

	echo $md5
}


#------------------------------------------------------------------------------
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @require abort, md5
#------------------------------------------------------------------------------
function _cp {

	local TARGET=`dirname "$2"`

	if ! test -d "$TARGET"; then
		_abort "no such directory [$TARGET]"
	fi

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
	  local MD1=`_md5 "$1"`
		local MD2=`_md5 "$2"`

		if test "$MD1" = "$MD2"; then
			echo "Do not overwrite $2 with $1 (same content)"
		else
			echo "Copy file $1 to $2 (update)"
			cp "$1" "$2" || _abort "cp '$1' '$2'"
		fi

		return
  fi

  if test -f "$1"; then
    echo "Copy file $1 to $2"
		cp "$1" "$2" || _abort "cp '$1' '$2'"
	elif test -d "$1"; then
		echo "Copy directory $1 to $2"
		cp -r "$1" "$2" || _abort "cp -r '$1' '$2'"
	else
		_abort "No such file or directory [$1]"
  fi
}


#------------------------------------------------------------------------------
function _build {
	local BIN="bin/$1"".sh"

	./merge2run.sh "copyright $2 $1"
	chmod 755 run.sh
	_cp run.sh "$BIN" md5
	rm run.sh
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

test -d bin || mkdir bin

_build rks-mysql_backup "abort cd cp create_tgz mysql_dump mysql_backup rm"
_build rks-mysql_restore "abort extract_tgz cd cp rm mkdir mysql_load"

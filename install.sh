#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Roland Kujundzic <roland@kujundzic.de>
#
# shellcheck disable=SC1090,SC2016,SC2034
#


#--
# Build lib/rkscript.sh.
# shellcheck disable=SC2012,SC2086
#--
function do_build {
	local lib_tmp
	echo "Build lib/rkscript.sh"

	_mkdir "lib"
	_mkdir "$RKSCRIPT_DIR" > /dev/null

	lib_tmp="$RKSCRIPT_DIR/rkscript.sh"

	{ 
	echo '#!/bin/bash' 
	echo -e "\ntest -z \"\$RKSCRIPT_SH\" || return\nRKSCRIPT_SH=1\n"
	echo 'test -z "$APP" && APP="$0"'
	echo 'test -z "$APP_PID" && export APP_PID="$$"'
	echo 'test -z "$CURR" && CURR="$PWD"'
	echo
	} > "$lib_tmp"

	echo "append $SCRIPT_SRC/*.sh to $lib_tmp"
	for a in $(ls $SCRIPT_SRC/*.sh | sort); do
		tail -n+2 "$a" >> "$lib_tmp"
	done

	_add_abort_linenum "$lib_tmp"
	_chmod 644 "$lib_tmp"

	_cp "$lib_tmp" lib/rkscript.sh md5
}


#--
# Install lib/rkscript.sh in $1 (= /usr/local/lib/rkscript.sh).
#--
function do_install {

	if test -z "$1"; then
		_confirm "Install lib/rkscript.sh to /usr/local/lib/rkscript.sh?"

		if test "$CONFIRM" = "y"; then
			_cp "lib/rkscript.sh" "/usr/local/lib/rkscript.sh" md5
		else
			_syntax "install [localhost=ask=/usr/local/lib/rkscript.sh|install/path|dockername|user@domain.tld]"
		fi

		return
	fi

	if test "$1" = "localhost"; then
		_cp lib/rkscript.sh /usr/local/lib/rkscript.sh md5
	elif ! test -z "$(docker ps 2> /dev/null | grep "$1")"; then
		echo "docker cp lib/rkscript.sh $1:/usr/local/lib/"
		docker cp lib/rkscript.sh "$1:/usr/local/lib/"
	elif test -d "$1"; then
		_cp lib/rkscript.sh "$1/rkscript.sh" md5
	else
		echo "scp lib/rkscript.sh $1:/usr/local/lib/"
		scp lib/rkscript.sh "$1:/usr/local/lib/"
	fi
}


#--
# M A I N
#--

APP=$0
CWD="$PWD"
export APP_PID="$APP_PID $$"

APP_DESC="install to /usr/local/lib/rkscript.sh"

command -v realpath > /dev/null 2>&1 && APP=$(realpath "$0")

SCRIPT_SRC=$(dirname "$APP")"/src"
INCLUDE_FUNC="abort.sh osx.sh mkdir.sh cp.sh md5.sh log.sh chmod.sh sudo.sh confirm.sh syntax.sh require_program.sh msg.sh add_abort_linenum.sh"

for a in $INCLUDE_FUNC; do
	source "$SCRIPT_SRC/$a"
done

echo
do_build
do_install "$1"
echo -e "done.\n"


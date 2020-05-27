#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Roland Kujundzic <roland@kujundzic.de>
#
# shellcheck disable=SC1090,SC2016,SC2034
#


#--
# Build lib/rkbash.lib.sh.
# shellcheck disable=SC2012,SC2086
# @global RKBASH_SRC RKBASH_DIR
#--
function do_build {
	local lib_tmp
	echo "Build lib/rkbash.lib.sh"

	_require_global RKBASH_SRC RKBASH_DIR
	_require_dir "$RKBASH_SRC"
	_mkdir "lib"
	_mkdir "$RKBASH_DIR" > /dev/null

	lib_tmp="$RKBASH_DIR/rkbash.lib.sh"

	{ 
	echo '#!/bin/bash' 
	echo -e "\ntest -z \"\$RKBASH_VERSION\" || return\nRKBASH_VERSION=0.3\n"
	echo 'test -z "$APP" && APP="$0"'
	echo 'test -z "$APP_DIR" && APP_DIR=$( cd "$( dirname "$APP" )" >/dev/null 2>&1 && pwd )'
	echo 'test -z "$APP_PID" && export APP_PID="$$"'
	echo 'test -z "$CURR" && CURR="$PWD"'
	echo
	} > "$lib_tmp"

	echo "append $RKBASH_SRC/*.sh to $lib_tmp"
	for a in $(ls $RKBASH_SRC/*.sh | sort); do
		tail -n+2 "$a" >> "$lib_tmp"
	done

	_add_abort_linenum "$lib_tmp"
	_chmod 644 "$lib_tmp"

	_cp "$lib_tmp" lib/rkbash.lib.sh md5
}


#--
# Install lib/rkbash.lib.sh in $1 (= /usr/local/lib/rkbash.lib.sh).
#--
function do_install {

	if test -z "$1"; then
		_confirm "Install lib/rkbash.lib.sh to /usr/local/lib/rkbash.lib.sh?"

		if test "$CONFIRM" = "y"; then
			_cp "lib/rkbash.lib.sh" "/usr/local/lib/rkbash.lib.sh" md5
		else
			_syntax "install [localhost=ask=/usr/local/lib/rkbash.lib.sh|install/path|dockername|user@domain.tld]"
		fi

		return
	fi

	if test "$1" = "localhost"; then
		_cp lib/rkbash.lib.sh /usr/local/lib/rkbash.lib.sh md5
	elif ! test -z "$(docker ps 2> /dev/null | grep "$1")"; then
		echo "docker cp lib/rkbash.lib.sh $1:/usr/local/lib/"
		docker cp lib/rkbash.lib.sh "$1:/usr/local/lib/"
	elif test -d "$1"; then
		_cp lib/rkbash.lib.sh "$1/rkbash.lib.sh" md5
	else
		echo "scp lib/rkbash.lib.sh $1:/usr/local/lib/"
		scp lib/rkbash.lib.sh "$1:/usr/local/lib/"
	fi
}


#--
# M A I N
#--

APP=$0
CWD="$PWD"
export APP_PID="$APP_PID $$"

APP_DESC="install to /usr/local/lib/rkbash.lib.sh"

command -v realpath > /dev/null 2>&1 && APP=$(realpath "$0")

RKBASH_SRC=$(dirname "$APP")"/src"
INCLUDE_FUNC="abort.sh osx.sh mkdir.sh cp.sh md5.sh log.sh chmod.sh 
	sudo.sh confirm.sh syntax.sh require_program.sh msg.sh add_abort_linenum.sh
	require_global.sh require_dir.sh"

for a in $INCLUDE_FUNC; do
	source "$RKBASH_SRC/$a"
done

echo
do_build
do_install "$1"
echo -e "done.\n"


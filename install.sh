#!/bin/bash
#
# Copyright (c) 2019 Roland Kujundzic <roland@kujundzic.de>
#


#------------------------------------------------------------------------------
# Build lib/rkscript.sh.
#------------------------------------------------------------------------------
function _build {
	echo "Build lib/rkscript.sh"

	_mkdir "lib"
	_mkdir "$HOME/.rkscript"

	local LIB_TMP="$HOME/.rkscript/rkscript.sh"

	echo '#!/bin/bash' > $LIB_TMP
	_chmod 644 "$LIB_TMP"

	echo -e "\ntest -z \"\$RKSCRIPT_SH\" || return\nRKSCRIPT_SH=1\n" >> $LIB_TMP
	echo 'test -z "$APP" && APP="$0"' >> $LIB_TMP
	echo 'test -z "$APP_PID" && export APP_PID="$APP_PID $$"' >> $LIB_TMP
	echo 'test -z "$CURR" && CURR="$PWD"' >> $LIB_TMP
	echo >> $LIB_TMP

	echo "append $SCRIPT_SRC/*.sh to $LIB_TMP"
	for a in $SCRIPT_SRC/*.sh
	do
		tail -n+2 $a >> $LIB_TMP
	done

	_cp $LIB_TMP lib/rkscript.sh md5
}


#------------------------------------------------------------------------------
# Install lib/rkscript.sh in $1 (= /usr/local/lib/rkscript.sh).
#------------------------------------------------------------------------------
function _install {

	if test -z "$1"; then
		_confirm "Install lib/rkscript.sh to [/usr/local/lib/rkscript.sh] ?"

		if test "$CONFIRM" = "y"; then
			_cp "lib/rkscript.sh" "/usr/local/lib/rkscript.sh" md5
		else
			_syntax "install [localhost=ask=/usr/local/lib/rkscript.sh|install/path|dockername|user@domain.tld]"
		fi

		return
	fi

	local HAS_DOCKER=`docker ps 2> /dev/null | grep "$1"`

	if test "$1" = "localhost"; then
		_cp lib/rkscript.sh /usr/local/lib/rkscript.sh md5
	elif ! test -z "$HAS_DOCKER"; then
		echo "docker cp lib/rkscript.sh $1:/usr/local/lib/"
		docker cp lib/rkscript.sh $1:/usr/local/lib/
	elif test -d "$1"; then
		_cp lib/rkscript.sh "$1/rkscript.sh" md5
	else
		echo "scp lib/rkscript.sh $1:/usr/local/lib/"
		scp lib/rkscript.sh $1:/usr/local/lib/
	fi
}



#
# M A I N
#

APP=$0

command -v realpath > /dev/null 2>&1 && APP=`realpath "$0"`

export APP_PID="$APP_PID $$"

SCRIPT_SRC=`dirname "$APP"`"/src"

. "$SCRIPT_SRC/abort.sh"
. "$SCRIPT_SRC/osx.sh"
. "$SCRIPT_SRC/mkdir.sh"
. "$SCRIPT_SRC/cp.sh"
. "$SCRIPT_SRC/md5.sh"
. "$SCRIPT_SRC/log.sh"
. "$SCRIPT_SRC/chmod.sh"
. "$SCRIPT_SRC/sudo.sh"
. "$SCRIPT_SRC/confirm.sh"
. "$SCRIPT_SRC/syntax.sh"
. "$SCRIPT_SRC/require_program.sh"

echo
_build
_install "$1"
echo -e "done.\n"


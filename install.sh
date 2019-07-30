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

	local LIB_TMP=".rkscript/rkscript.sh"

	echo '#!/bin/bash' > $LIB_TMP
        _chmod 644 lib/rkscript.sh

	for a in $SCRIPT_SRC/*.sh
	do
		tail -n+2 $a >> $LIB_TMP
	done

	_cp $LIB_TMP lib/rkscript md5
}


#------------------------------------------------------------------------------
# Install lib/rkscript.sh in $1 (= /usr/local/lib/rkscript.sh).
#------------------------------------------------------------------------------
function _install {
	local HAS_DOCKER=`docker ps 2> /dev/null | grep "$1"`

	if test "$1" = "localhost"; then
		_cp lib/rkscript.sh /usr/local/lib/rkscript.sh md5
	elif ! test -z "$HAS_DOCKER"; then
		echo "docker cp lib/rkscript.sh $1:/usr/local/lib/"
		docker cp lib/rkscript.sh $1:/usr/local/lib/
	elif test -d "$1"; then
		_cp lib/rkscript.sh "$1/rkscript.sh" md5
	elif ! test -z "$1"; then
		echo "copy lib/rkscript.sh to $1:/usr/local/lib/"
		echo "scp lib/rkscript.sh '$1:/usr/local/lib/'"
		scp lib/rkscript.sh "$1:/usr/local/lib/"
	else
		_confirm "Install lib/rkscript.sh to [/usr/local/lib/rkscript.sh] ?"
		if test "$CONFIRM" = "y"; then
			_cp "lib/rkscript.sh" "$INSTALL_DIR/rkscript.sh" md5
		else
			_syntax "install [localhost=ask=/usr/local/lib/rkscript.sh|install/path|dockername|user@domain.tld]"
		fi
	fi
}



#
# M A I N
#

APP=$0

command -v realpath > /dev/null 2>&1 && APP=`realpath "$0"`

SCRIPT_SRC=`dirname "$APP"`"/src"

. "$SCRIPT_SRC/abort.sh"
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


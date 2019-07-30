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

	echo '#!/bin/bash' > lib/rkscript.sh
	for a in $SCRIPT_SRC/*.sh
	do
		tail -n+2 $a >> lib/rkscript.sh
	done

        _chmod 644 lib/rkscript.sh
}


#------------------------------------------------------------------------------
# Install lib/rkscript.sh in $1 (= /usr/local/lib/rkscript.sh).
#------------------------------------------------------------------------------
function _install {
	local INSTALL_DIR="$1"

	test -z "$INSTALL_DIR" && INSTALL_DIR=/usr/local/lib

	_confirm "Install lib/rkscript.sh [$INSTALL_DIR] ?"
	if test "$CONFIRM" = "y"; then
		_cp "lib/rkscript.sh" "$INSTALL_DIR/"
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

echo
_build
_install "$1"
echo -e "done.\n"


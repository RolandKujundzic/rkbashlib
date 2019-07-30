#!/bin/bash

#------------------------------------------------------------------------------
# Rsync $1 to $2. Log to .rsync/RSYNC_COUNT.[sh|log|err].
#
# @param source path e.g. user@host:/path/to/source
# @param target path default=[.]
# @global RSYNC_EXCLUDE RSYNC_PARAM
# @export RSYNC_COUNT
# @require _abort _mkdir
#------------------------------------------------------------------------------
function _rsync {
	local TARGET="$2"

	if test -z "$TARGET"; then
		TARGET="."
	fi

	if test -z "$1"; then
		_abort "Empty rsync source"
	fi

	RSYNC_COUNT=$((RSYNC_COUNT + 1))

	_mkdir .rsync

	local CMD=".cmd/$COMMAND_COUNT"

  if test -d "$DIR"; then
    echo "rsync $1"
    rsync -av --exclude settings.php --exclude phplib \
      -e ssh blumgmbh@druckdienste24.de:/webhome/druckdienste24_de/$1 . > rsync.$DIR.log 2> rsync.$DIR.err
  else
    _abort "No such directory [$DIR]  ($1)"
  fi
}


	local TARGET=`dirname "$2"`

	if ! test -d "$TARGET"; then
		_abort "no such directory [$TARGET]"
	fi

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
	  local MD1=`_md5 "$1"`
		local MD2=`_md5 "$2"`

		if test "$MD1" = "$MD2"; then
			echo "_cp: keep $2 (same as $1)"
		else
			echo "Copy file $1 to $2 (update)"
			_sudo "cp '$1' '$2'" 1
		fi

		return
  fi

  if test -f "$1"; then
    echo "Copy file $1 to $2"
		_sudo "cp '$1' '$2'" 1
	elif test -d "$1"; then
		if test -d "$2"; then
			local PDIR=`dirname $2`"/"
			echo "Copy directory $1 to $PDIR"
			_sudo "cp -r '$1' '$PDIR'" 1
		else
			echo "Copy directory $1 to $2"
			_sudo "cp -r '$1' '$2'" 1
		fi
	else
		_abort "No such file or directory [$1]"
  fi
}


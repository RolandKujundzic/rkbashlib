#!/bin/bash

#--
# Create LICENCSE file for "gpl-3.0" (keep existing).
#
# @see https://help.github.com/en/articles/licensing-a-repository 
# @param license name (default "gpl-3.0")
# @export LICENSE
#--
function _license {
	if ! test -z "$1" && test "$1" != "gpl-3.0"; then
		_abort "unknown license [$1] use [gpl-3.0]"
	fi

	LICENSE=$1
	if test -z "$LICENSE"; then
		LICENSE="gpl-3.0"
	fi

	local LFILE="./LICENSE"

	if test -s "$LFILE"; then
		local IS_GPL3=`head -n 2 "$LFILE" | tr '\n' ' ' | sed -E 's/\s+/ /g' | grep 'GNU GENERAL PUBLIC LICENSE Version 3'`

		if ! test -z "$IS_GPL3"; then
			echo "keep existing gpl-3.0 LICENSE ($LFILE)"
			return
		fi

		_confirm "overwrite existing $LFILE file with $LICENSE"
		if test "$CONFIRM" != "y"; then
			echo "keep existing $LFILE file"
			return
		fi
	fi

	_wget "http://www.gnu.org/licenses/gpl-3.0.txt" "$LFILE"
}

#!/bin/bash

#------------------------------------------------------------------------------
# Export required rkscript/src/* functions as $REQUIRED_RKSCRIPT.
# Call scan_rkscript_src first.
#
# @param string shell script
# @param boolean resolve recursive
# @export REQUIRED_RKSCRIPT
# @global RKSCRIPT_FUNCTIONS
# @require _require_global
#------------------------------------------------------------------------------
function _required_rkscript {
	local BASE=`basename "$1"`
	local FUNC="_"${BASE::-3}

	_require_global RKSCRIPT_FUNCTIONS

	local LIST=
	local b=	
	local a=; for a in $RKSCRIPT_FUNCTIONS; do
		b=`cat "$1" | sed -e "s/function .*//" | grep "$a "`

		if ! test -z "$b" && test "$FUNC" != "$a"; then
			LIST="$a $LIST"
		fi
	done

	if ! test -z "$2"; then		
		local RESULT="$LIST"

		for a in $LIST; do
			b="$RKSCRIPT_PATH/src/"${a:1}".sh"
			_required_rkscript $b $2
			RESULT=`echo "$RESULT $REQUIRED_RKSCRIPT" | sed -e "s/ /\n/g" | sort -u | xargs`
		done

		LIST="$RESULT"
	fi

	REQUIRED_RKSCRIPT="$LIST"
}


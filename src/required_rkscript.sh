#!/bin/bash

#------------------------------------------------------------------------------
# Export required rkscript/src/* functions as $REQUIRED_RKSCRIPT.
# Call scan_rkscript_src first.
#
# @param string shell script
# @param boolean resolve recursive
# @export REQUIRED_RKSCRIPT REQUIRED_RKSCRIPT_INCLUDE
# @global RKSCRIPT_FUNCTIONS
# @require _require_global
#------------------------------------------------------------------------------
function _required_rkscript {
	local BASE=`basename "$1"`
	# negative offset doesn't work in OSX bash replace ${BASE::-3} with ${BASE:0:${#BASE}-3}
	local FUNC="_"${BASE:0:${#BASE}-3}

	_require_global RKSCRIPT_FUNCTIONS

	if [ -z ${REQUIRED_RKSCRIPT+x} ]; then
		REQUIRED_RKSCRIPT_INCLUDE=
	fi

	if [[ "$REQUIRED_RKSCRIPT_INCLUDE" =~ " $FUNC" ]]; then
		# skip already included
		return
	fi

	REQUIRED_RKSCRIPT_INCLUDE="$REQUIRED_RKSCRIPT_INCLUDE $FUNC"

	local LIST=; local b=; local a=; local n=0
	for a in $RKSCRIPT_FUNCTIONS; do
		b=`cat "$1" | sed -e "s/function .*//" | grep "$a "`

		if test -z "$b"; then
			b=`cat "$1" | sed -e "s/function .*//" | grep "^\s*$a\s*$"`
		fi

		if ! test -z "$b" && test "$FUNC" != "$a"; then
			LIST="$a $LIST"
			n=$((n + 1))
		fi
	done

	echo "include $FUNC (use $n functions)"

	if ! test -z "$2"; then		
		local RESULT="$LIST"

		for a in $LIST; do
			b="$RKSCRIPT_PATH/src/"${a:1}".sh"
			_required_rkscript $b $2
			# OSX workaround: use [sed -e 's/ /\'$'\n/g'] instead of [sed -e "s/ /\n/g"]
			RESULT=`echo "$RESULT $REQUIRED_RKSCRIPT" | sed -e 's/ /\'$'\n/g' | sort -u | xargs`
		done

		LIST="$RESULT"
	fi

	REQUIRED_RKSCRIPT="$LIST"
}


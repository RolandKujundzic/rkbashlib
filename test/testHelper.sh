#!/bin/bash

declare -A TEST_OUT

test -z "$TEST_HELPER_SH" || return
TEST_HELPER_SH=1


#------------------------------------------------------------------------------
# Add [find out -type f -printf "%u %g '%f'\n"] output to TEST_OUT
#------------------------------------------------------------------------------
function _ls_out {
	_require_dir out
	TEST_OUT[${#TEST_OUT[@]}]=`find out -type f -printf "%u %g '%f'\n"`
}


#------------------------------------------------------------------------------
# Compare TEST_OUT with ok/$APP.ok.N.txt
# @global APP
#------------------------------------------------------------------------------
function _compare_ok {
	_require_global APP
	echo -e "\n$APP: ${#TEST_OUT[@]} tests\n------------------------------"

	local a=; local i=; local n=; local ok=; local out=; local err=0;

	for ((i = 0; i < ${#TEST_OUT[@]}; i++)); do
		out="${TEST_OUT[$i]}"
		n=$((i + 1))
		_require_file "ok/$APP.ok.$n.txt"
		ok=`cat "ok/$APP.ok.$n.txt"`

		if test "$ok" != "$out"; then
			echo "$out" > "ok/$APP.out.$n.txt"
			echo "  $n / ${#TEST_OUT[@]} ... ERROR (ok/$APP.out.$n.txt != ok/$APP.ok.$n.txt)"
			err=$((err + 1))
		else
			echo "  $n / ${#TEST_OUT[@]} ... OK"
		fi
	done

	if test $err -gt 0; then
		_abort "$APP test failed - fix $err error(s)"
	else
		echo -e "------------------------------\n$n test(s) succeded\n"
	fi
}


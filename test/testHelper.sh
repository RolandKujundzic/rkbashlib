#!/bin/bash

declare -A TEST_OUT

test -z "$TEST_HELPER_SH" || return
TEST_HELPER_SH=1

declare -A TEST_CALL=( [total]=0 [ok]=0 [err]=0 )


#------------------------------------------------------------------------------
# Run inc/$1 and compare output with ok/$1.txt.
#
# @param test script
#------------------------------------------------------------------------------
function test_call {
	_require_dir out
	local base=`echo "$1" | sed -E 's/\.sh$//'`
	test -f "ok/$1.txt" || _abort "missing ok/$1.txt"

	echo -n "_$base ... "
	. call/$1 >"out/$1.txt" 2>"out/$1.err"

	local diff=`diff -u "out/$1.txt" "ok/$1.txt"`	
	if test -z "$diff" && ! test -s "out/$1.err"; then
		TEST_CALL[ok]=$((TEST_CALL[ok] + 1))
		echo "ok"
	else
		TEST_CALL[err]=$((TEST_CALL[err] + 1))
		echo "error"
	fi
}


#------------------------------------------------------------------------------
# Add [find out -type f -printf "%u %g '%f'\n"] output to TEST_OUT
#------------------------------------------------------------------------------
function ls_out {
	_require_dir out
	TEST_OUT[${#TEST_OUT[@]}]=`find out -type f -printf "%u %g %M '%p'\n"`
}


#------------------------------------------------------------------------------
# Print test header
#
# @param string
#------------------------------------------------------------------------------
function test_start {
	_rm out >/dev/null
	_mkdir out >/dev/null

	TEST_OUT=()

	test -z "$1" || echo -e "\n$1\n------------------------------"
}


#------------------------------------------------------------------------------
# Print test footer
#
# @param int #success
# @param int #error
#------------------------------------------------------------------------------
function test_done {
	if test "$2" -gt 0; then
		_abort "$2 test(s) failed"
	else
		echo -e "------------------------------\n$1 test(s) succeded\n"
	fi
}


#------------------------------------------------------------------------------
# Compare TEST_OUT with ok/$APP.ok.N.txt
# @param script name
#------------------------------------------------------------------------------
function compare_ok {
	local APP=$1
	test -z "$1" || echo -e "\n$APP: ${#TEST_OUT[@]}\n------------------------------"

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

	test_done $n $err
}


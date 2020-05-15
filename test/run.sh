#!/bin/bash
#
# shellcheck disable=SC1090,SC1091,SC2012,SC2154,SC2034
#


#--
# M A I N
#--

source ../lib/rkscript.sh || { echo "failed to load ../lib/rkscript.sh"; exit 1; }

_shell_check ../src

source testHelper.sh || { echo "failed to load testHelper.sh"; exit 1; }

TEST_CALL[total]=$(ls call/*.sh | wc -l)

test -d out && _rm out
_mysql_drop_db rkscript

LOG_NO_ECHO=1  # because PID changes in ~/.rkscript/PID/...

test_start "call/*sh: run ${TEST_CALL[total]} test(s)"
for a in call/*.sh; do
	test_call "$(basename "$a")"
done

test_done "${TEST_CALL[ok]}" "${TEST_CALL[err]}" 

for a in inc/*.sh; do
	test_start
	source "$a"
	ls_out
	compare_ok "$(basename "$a")"
done

rm ok/*.out.* 2>/dev/null


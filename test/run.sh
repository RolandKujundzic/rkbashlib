#!/bin/bash

. ../lib/rkscript.sh || { echo "failed to load ../lib/rkscript.sh"; exit 1; }
. testHelper.sh || { echo "failed to load testHelper.sh"; exit 1; }

APP="$0"

TEST_CALL[total]=`ls inc/*.sh | wc -l`

test_start "call/*sh: run ${TEST_CALL[total]} test(s)"
for a in call/*.sh; do
	test_call `basename $a`
done

test_done ${TEST_CALL[ok]} ${TEST_CALL[err]} 

for a in inc/*.sh; do
	test_start
	. $a
	ls_out
	compare_ok `basename $a`
done

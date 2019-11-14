#!/bin/bash

. ../lib/rkscript.sh || exit 1
. testHelper.sh || exit 1

APP="$0"

_rm out
_mkdir out

echo "a" > out/a.txt
echo "b c" > out/b\ c.txt

_ls_out
_chown out rk www-data 
_ls_out

_compare_ok


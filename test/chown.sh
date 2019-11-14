#!/bin/bash

. ../lib/rkscript.sh || exit 1

_mkdir out

echo "a" > out/a.txt
echo "b c" > out/b\ c.txt


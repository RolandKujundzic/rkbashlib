#!/bin/bash

test="land.of.linux"

echo "strip '*.' from '$test'"

echo "shortest match from front (#): "${test#*.}
echo "longest match from front (##): "${test##*.}

echo "shortest match from back (%): "${test%.*}
echo "longest match from back (%%): "${test%%.*}

echo "replace '.' once with ';' (/): ".${test/./;}
echo "replace '.' always with ';' (//): ".${test//./;}

#!/bin/bash

test="land.of.linux"

echo "strip '*.' from \$test='$test'"

echo 'shortest match from front (#): ${test#*.}='${test#*.}
echo 'longest match from front (##): ${test##*.}='${test##*.}

echo 'shortest match from back (%): ${test%.*}='${test%.*}
echo 'longest match from back (%%): ${test%%.*}='${test%%.*}

echo "replace '.' once with ';' (/): "'${test/./;}='.${test/./;}
echo "replace '.' always with ';' (//): "'${test//./;}='.${test//./;}

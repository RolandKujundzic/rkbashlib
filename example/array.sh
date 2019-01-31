#!/bin/bash


function test {
	echo -e "\ntest: \$1=[$1]"

	local ARRAY=( $1 )
	echo "1:1=[${ARRAY[@]:1:1}] 0:2=[${ARRAY[@]:0:2}] :3=[${ARRAY[@]:3}]"
	# the space before -3|-2 is IMPORTANT!
	echo "-3:1=[${ARRAY[@]: -3:1}] -2:2=[${ARRAY[@]: -2:2}]"
	echo
}


LIST="xyzuvw aa bb cc dd ee fghi"

test $LIST
test "$LIST"

STRING="abcdefgh"

echo "STRING[0]=[${STRING:0}] STRING[0:1]=[${STRING:0:1}] STRING[0:3]=[${STRING:0:3}] STRING[3]=[${STRING:3}] STRING[-2]=[${STRING: -2}]"

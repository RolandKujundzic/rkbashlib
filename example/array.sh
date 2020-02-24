#!/bin/bash

function array_set {
	GLOBAL_ARRAY[$1]="$2"
	GLOBAL_HASH[$1]="$2"
	echo -e "\narray_set($1, $2):\nGLOBAL_HASH=[${GLOBAL_HASH[@]}] GLOBAL_ARRAY=[${GLOBAL_ARRAY[@]}]"
}


function hash_test {
	local A=( $1 )
	echo -ne "\nhash_test($1):\nA[0]=[${A[0]}] A[1]=[${A[1]}] A=[${A[@]}] "
	# important: space before -n otherwise is means default value
	echo "A[1:1]=[${A[@]:1:1}] A[0:2]=[${A[@]:0:2}] A[-2]=[${A[@]:-2}] A[ -2:]=[${A[@]: -2}] A[ -2:1]=[${A[@]: -2:1}]"
}


function sub() {
	echo "sub A: ${A[@]} ${!A[@]}"
}


#
# M A I N
#

LIST="xyzuvw aa bb cc dd ee fghi"
hash_test $LIST
hash_test "$LIST"
sub
echo "main A: ${A[@]} ${!A[@]}"

declare -A GLOBAL_HASH=([test]='hello')
declare -A GLOBAL_HASH2
GLOBAL_ARRAY=('a' 'b')
GLOBAL_ARRAY2=()

echo -e "\nCount(GLOBAL_HASH)=[${#GLOBAL_HASH[@]}] Keys: GLOBAL_HASH=[${!GLOBAL_HASH[@]}] GLOBAL_HASH2=[${!GLOBAL_HASH2[@]}] \
GLOBAL_ARRAY=[${!GLOBAL_ARRAY[@]}] GLOBAL_ARRAY2=[${!GLOBAL_ARRAY2[@]}]"

array_set 7 abc
array_set 8 uvw
array_set "8" xyz

S="abcdefgh"
# important: space before -n otherwise it means default value
echo -e "\nS=[$S] S[0]=[${S:0}] S[0:1]=[${S:0:1}] S[0:3]=[${S:0:3}] S[3]=[${S:3}] S[ -2]=[${S: -2}]\n"

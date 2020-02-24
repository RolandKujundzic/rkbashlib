#!/bin/bash

function a() {
	echo "in a: H=${H[x]} ${H[y]} LIST=${LIST[@]} ${!LIST[@]} V=$V G=$G - why is H, LIST and V defined?"
}


function b() {
	# -g will make declare global
	declare -A H=( [x]="yalla yalla" [y]="yuck yuck" )
	declare -a local LIST=( "a" "b b" "c" )
	local V="vvv"
	G="global"
	echo "in b: H=${H[x]} ${H[y]} LIST=${LIST[@]} ${!LIST[@]} V=$V G=$G"
	a
}

b
echo "in main: H=${H[x]} ${H[y]} LIST=${LIST[@]} ${!LIST[@]} V=$V G=$G"

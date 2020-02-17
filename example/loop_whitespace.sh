#!/bin/bash


function test_1 {
	OLD_IFS="$IFS"
	IFS=$'\n'

	echo "FOR + IFS"
	for a in $1; do
		echo "[$a]"
	done

	IFS="$OLD_IFS"
}

function test_2 {
	echo "WHILE + READ + <<<"
	while read a; do
		echo "[$a]"
	done <<< `echo "$1"`
}

function test_3 {
	echo "WHILE + READ + PIPE"
	echo "$1" |	while read a; do
		echo "[$a]"
	done
}



LIST="abc
a b c
aa bb"

test_1 "$LIST"
test_2 "$LIST"
test_3 "$LIST"

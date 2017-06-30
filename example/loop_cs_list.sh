#!/bin/bash

LIST="a b,b;b c
d
e	f"

echo "Word Expansion is space, linebreak and tab"
for a in $LIST
do
	echo $a
done


echo -e "\nAdd comma [,] and semicolon [;] to word expansion via IFS"

IFS=$IFS',;'

LIST="a b,b;b	c
d"

for a in $LIST
do
	echo $a
done

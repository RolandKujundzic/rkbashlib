#!/bin/bash

echo -e "\e[0;34m blue=0;34m\n\e[0;31m red=0;31m\n\e[1;31m light red=1;31m\n\e[1;37m white=1;37m\n\e[0m no color=0m\n\n"

k=1
for n in 0 1; do
	for a in 1 2 3 4 5 7 8 9 21 30 31 32 33 34 35 36 37 40 41 42 43 44 45 46 47; do
		let b=$k%5
		echo -en "[ \e[$n;${a}m$n;$a=yalla\e[0m ]\t\t"
		test "$b" = "0" && echo -e "\n"
		let k=$k+1
	done
done


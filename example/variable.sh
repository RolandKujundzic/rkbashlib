#!/bin/bash

function test {
	local L1="local variable 1"
	local v="L2"
	# declare -g = declare global (only if bash version >= 4.2)
	declare "$v"="local variable 2"
	echo "L1=$L1 L2=$L2"
}


#
# M A I N
#

echo -e "\nB is variable reference (variable pointer)"

A="Hello World"
B=A
#error: B="something else"

echo "A=$A | A=${A} (different syntax) | B=$B | B=${!B} (value of B)"

echo -e "\nUse parameter in variable assignment"

test

printf -v "TEST" '%s' "Hello"
echo "TEST=$TEST L1=$L1 L2=$L2"

declare "G"="global variable"
eval "TEST2='eval is evil'"
echo "G=$G TEST2=$TEST2"

V="Hello"
X="V"

echo "\$V=[$V] \${V}=[${V}] indirect variable reference (\$X=[$X]): {\$!X}=[${!X}]"

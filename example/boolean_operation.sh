#!/bin/bash

function boolean_operation {
	local A=$1
	local B=$2

	echo "A && B = $((A && B)), !A && B = $((!A && B)), A && !B = $((A && !B)), !A && !B = $((!A && !B)) - A=[$A] B=[$B]"
	echo "A || B = $((A || B)), !A || B = $((!A || B)), A || !B = $((A || !B)), !A || !B = $((!A || !B)) - A=[$A] B=[$B]"
	echo
}

function tf {
	local A=$1
	local B=$2
	local A_AND_B=
	local A_OR_B=	

	if ((A && B)); then A_AND_B=1; else A_AND_B=0; fi
	if ((A || B)); then A_OR_B=1; else A_OR_B=0; fi

	echo "A=[$A] B=[$B]: '$A' && '$B' = $((A && B)), '$A' || '$B' = $((A || B)), if (A && B) = $A_AND_B, if (A || B) = $A_OR_B"
}


for A in 0 1; do
	for B in 0 1; do
		boolean_operation "$A" "$B"
	done
done

for A in "" "1"; do
	for B in "" "1"; do
		boolean_operation "$A" "$B"
	done
done

A="x"; B="y";
echo "Only number or empty string allowed:"
tf "x" "y"
tf "" 1
tf 1 ""


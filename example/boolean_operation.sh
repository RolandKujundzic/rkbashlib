#!/bin/bash

function boolean_operation {
	local A=$1
	local B=$2

	echo "A && B = $((A && B)), !A && B = $((!A && B)), A && !B = $((A && !B)), !A && !B = $((!A && !B)) - A=[$A] B=[$B]"
	echo "A || B = $((A || B)), !A || B = $((!A || B)), A || !B = $((A || !B)), !A || !B = $((!A || !B)) - A=[$A] B=[$B]"
	echo
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
echo "'$A' && '$B' = $((A && B))"
echo "'$A' || '$B' = $((A || B))"
A="1"; B="";
echo "'$A' || '$B' = $((A || B))"

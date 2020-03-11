#!/bin/bash

function a {
	echo "function a exists"
}

b() {
	echo "function b exists"
}


if declare -F a >/dev/null && declare -F b >/dev/null; then
	a && b
fi


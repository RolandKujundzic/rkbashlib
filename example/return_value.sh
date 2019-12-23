#!/bin/bash

function test {
	echo "enter"
	echo "return value is either empty or int"
	echo "function call was success: return value = 0 or empty"
	echo "function call was error: return value != 0 (= error code)"
	return
	echo "exit"
}

function x {
	echo -n "function x will return $1 ... "
	return $1
}

test
x 0 && echo "ok" || echo "error"
x 1 && echo "ok" || echo "error"
x -13 && echo "ok" || echo "error"

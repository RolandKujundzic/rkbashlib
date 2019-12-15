#!/bin/bash
# enable auto abort
set -e

function _abort {
	echo -e "\nERROR: $1\n$ERROR\n\n"
	exit 1
}


#--
# If result is non-zero call _abort
#--
function _error1 {
	cd no_such_directory || _abort "no such directory"
}


#--
# Catch error message in ERROR
#--
function _error2 {
	ERROR=$(cd no_such_directory 2>&1) || _abort "no such directory"
}


#--
# Disable auto abort (set -e) with leading :
#--
function _error3 {
	: cd no_such_directory
}


#--
# Auto abort (set -e)
#--
function _error4 {
	cd no_such_directory
}



#--
# M A I N
#--

echo -e "\nError handling examples"

echo -n "Run Test 1 2 3 4  "
read -n1 -t 5 TEST_NUM
RUN="_error$TEST_NUM"
echo " ... execute $RUN"
$RUN
echo -e "done."

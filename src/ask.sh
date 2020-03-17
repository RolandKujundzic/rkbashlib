#!/bin/bash

#--
# Ask question.
#
# @param string label
#--
function _ask {
	echo -n "$1  "
	read ANSWER
}

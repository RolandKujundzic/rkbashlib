#!/bin/bash

#--
# Sort (unique) whitespace list. No whitespace in list elements allowed.
# @param $@ list elements
#--
function _sort {
	echo "$@" | xargs -n1 | sort -u | xargs
}


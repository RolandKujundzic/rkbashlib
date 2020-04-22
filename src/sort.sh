#!/bin/bash

#--
# Sort (unique) whitespace list.
# @param $@ list elements
#--
function _sort {
	echo "$@" | xargs -n1 | sort -u | xargs
}


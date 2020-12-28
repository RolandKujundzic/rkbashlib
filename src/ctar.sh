#!/bin/bash

#--
# Create tar.gz archive. Flags:
# 1 = 2^0: --absolute-names
# 2 = 2^1: --to-stdout
#
# @param flag (use 0 for default -czf)
# @param archive
# @param * (other options, sources)
# shellcheck disable=SC2086,SC2048
#--
function _ctar {
	local flag opt
	flag=$(($1 + 0))
	shift
	opt='-czf'

	test $((flag & 1)) = 1 && opt="--absolute-names $opt" 
	test $((flag & 2)) = 2 && opt="$opt -" 

	tar $opt $* || _abort "tar $opt $*"
}

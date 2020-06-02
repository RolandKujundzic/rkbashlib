#!/bin/bash

#--
# Apply (perl) regular expression replace s/$2/$3/g on file $1
# @param regular expression
# @param file
#--
function _frx_replace {
	[[ -z "$2" ]] && _abort "invalid regular expression s/$2/$3/g"
	_require_program perl
	_require_file "$1"

	perl -i -pe "s/$2/$3/g" "$1"
}


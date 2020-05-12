#!/bin/bash

#--
# Show where php string function needs to change to mb_* version.
# shellcheck disable=SC2034
#--
function _mb_check {
	_require_dir src
	local a mb_func

	echo -e "\nSearch all *.php files in src/ - output filename if string function\nmight need to be replaced with mb_* version.\n"
	echo -e "Type any key to continue or wait 5 sec.\n"
	read -r -n1 -t 5 ignore_keypress

	# do not use ereg*
	mb_func="parse_str split stripos stristr strlen strpos strrchr strrichr 
		strripos strrpos strstr strtolower strtoupper strwidth substr_count substr"

	for a in $mb_func; do
		grep -d skip -r --include=*.php "$a(" src | grep -v "mb_$a("
	done
}


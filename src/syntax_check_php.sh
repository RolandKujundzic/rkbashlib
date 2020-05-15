#!/bin/bash

#--
# Create php file with includes from source directory.
#
# @param source directory
# @param output file
# @global PATH_RKPHPLIB
# shellcheck disable=SC2028
#--
function _syntax_check_php {
	local a php_files php_bin
	php_files=$(find "$1" -type f -name '*.php')
	php_bin=$(grep -R -E '^#\!/usr/bin/php' "bin" | grep -v 'php -c skip_syntax_check' | sed -E 's/\:\#\!.+//')

	_require_global PATH_RKPHPLIB

	{
		echo -e "<?php\n\ndefine('APP_HELP', 'quiet');\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');\n"
		echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;"
		echo -n '  print "ok\n";'
		echo -e "\n}\n"
	} >"$2"

	for a in $php_files $php_bin
	do
		if test -z "$(head -1 "$a" | grep 'php -c skip_syntax_check')"; then
			echo "_syntax_test('$a');" >> "$2"
		fi
	done
}


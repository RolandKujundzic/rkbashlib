#!/bin/bash

#--
# Create php file with includes from source directory.
#
# @param source directory
# @param output file
# @global PATH_RKPHPLIB
#--
function _syntax_check_php {
	local PHP_FILES=`find "$1" -type f -name '*.php'`
	local PHP_BIN=`grep -R -E '^#\!/usr/bin/php' "bin" | grep -v 'php -c skip_syntax_check' | sed -E 's/\:\#\!.+//'`

	_require_global PATH_RKPHPLIB

	echo -e "<?php\n\ndefine('APP_HELP', 'quiet');\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');\n" > "$2"
	echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;" >> "$2"
	echo -n '  print "ok\n";' >> "$2"
	echo -e "\n}\n" >> "$2"

	for a in $PHP_FILES $PHP_BIN
	do
		local SKIP=`head -1 "$a" | grep 'php -c skip_syntax_check'`
	
		if test -z "$SKIP"; then
			echo "_syntax_test('$a');" >> "$2"
		fi
	done
}


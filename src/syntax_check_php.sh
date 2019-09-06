#!/bin/bash

#------------------------------------------------------------------------------
# Create php file with includes from source directory.
#
# @param source directory
# @param output file
# @global PATH_RKPHPLIB
# @require _require_global
#------------------------------------------------------------------------------
function _syntax_check_php {
	local PHP_FILES=`find "$1" -type f -name '*.php'`

	_require_global PATH_RKPHPLIB

	echo -e "<?php\n\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');\n" > "$2"
	echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;" >> "$2"
	echo -n '  print "ok\n";' >> "$2"
	echo -e "\n}\n" >> "$2"

	for a in $PHP_FILES
	do
		echo "_syntax_test('$a');" >> "$2"
	done
}


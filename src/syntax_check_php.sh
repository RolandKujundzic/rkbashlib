#!/bin/bash

#--
# Create php file with includes from source directory.
# If source directory is test execute test/run.sh
#
# @param source directory
# @param output file
# @param optional (1 = run check)
# @global PATH_RKPHPLIB
# shellcheck disable=SC2028
#--
function _syntax_check_php {
	local a php_files php_bin

	if test "$1" = 'test'; then
		_require_file 'test/run.sh'
		_cd test
		_msg "Running test/run.sh ... " -n
		if ! ./run.sh >/dev/null; then
			_abort 'test failed - see test/run.log'
		fi
		_msg "OK"
		return
	fi

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

	if test "$3" = '1'; then
		php "$2" || _abort "php $2"
		_rm "$2"
	fi
}


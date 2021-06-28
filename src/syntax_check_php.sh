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
	local a php_files fnum

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

	php_files=$(grep -R -E '^#\!/usr/bin/php' "$1" | sed -E 's/\:\#\!.+//')
	fnum=$(echo "$php_files" | xargs -n1 | wc -l)
	_msg "Syntax check $fnum executable php files in $1"
	for a in $php_files
	do
		if ! php -l "$a" >/dev/null; then
			_abort "syntax error in $a"
		fi
	done

	_require_global PATH_RKPHPLIB

	{
		echo -e "<?php\n\ndefine('APP_HELP', 'quiet');\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');"
		echo -e "define('DOCROOT', getcwd());\n"
		echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;"
		echo -n '  print "ok\n";'
		echo -e "\n}\n"
	} >"$2"

	php_files=$(find "$1" -type f -name '*.php')
	fnum=$(echo "$php_files" | xargs -n1 | wc -l)
	_msg "Syntax check $fnum php files in $1"
	for a in $php_files
	do
		if ! php -l "$a" >/dev/null; then
			_abort "syntax error in $a"
		fi

		if test -z "$(head -1 "$a" | grep -E '^#\!/usr/bin/php')"; then
			echo "_syntax_test('$a');" >> "$2"
		fi
	done

	if test "$3" = '1'; then
		_msg "Execute $2"
		php "$2" > "$2.log" || _abort "php $2  # see $2.log"
		_rm "$2"
		_rm "$2.log"
	fi
}


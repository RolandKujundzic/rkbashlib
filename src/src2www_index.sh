#!/bin/bash

#------------------------------------------------------------------------------
# Update www/index.html. Concat files from www_src directory in this order:
#
# - header.html, app_header.html?, main.html, app_footer.html?, *.inc.html
# - if main.js exists append hidden div#app_main with main.html and script block
#		with main.js
#	- footer.html
#------------------------------------------------------------------------------
function _src2www_index {

	cp www_src/header.html www/index.html

	if test -f www_src/app_header.html; then
		cat www_src/app_header.html >> www/index.html
	fi

  cat www_src/main.html >> www/index.html

	if test -f www_src/app_footer.html; then
		cat www_src/app_footer.html >> www/index.html
	fi

	for a in www_src/*.inc.html; do
		cat $a >> www/index.html
	done

	if test -f www_src/main.js; then
		echo '<div id="app_main" style="display:none">' >> www/index.html
		cat www_src/main.html >> www/index.html
		echo '</div><script>' >> www/index.html
		cat www_src/main.js >> www/index.html
		echo '</script>' >> www/index.html
	fi

	cat www_src/footer.html >> www/index.html
}


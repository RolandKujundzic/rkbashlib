#!/bin/bash

#--
# Update www/index.html. Concat files from www_src directory in this order:
#
# - header.html, app_header.html?, main.html, app_footer.html?, *.inc.html
# - if main.js exists append hidden div#app_main with main.html and script block
#		with main.js
#	- footer.html
#
#--
function _src2www_index {
	_cp www_src/header.html www/index.html

	test -f www_src/app_header.html && cat www_src/app_header.html >>www/index.html
	cat www_src/main.html >>www/index.html
	test -f www_src/app_footer.html && cat www_src/app_footer.html >>www/index.html

	local a

	for a in www_src/*.inc.html; do
		cat "$a" >> www/index.html
	done

	if test -f www_src/main.js; then
		{
			echo '<div id="app_main" style="display:none">'
			cat www_src/main.html
			echo '</div><script>'
			cat www_src/main.js
			echo '</script>'
		} >>www/index.html
	fi

	cat www_src/footer.html >> www/index.html
}


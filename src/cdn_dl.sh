#!/bin/bash

#--
# Download source url to target path. 
# Export CDN_HTML to save <script ... and <link ... to ./CDN_HTML 
#
# @global CDN_HTML
# @param string source url
# @param string target path
# shellcheck disable=SC2046
#--
function _cdn_dl {
	_wget "$1" "$2"

	if test -n "$CDN_HTML"; then
		if grep -q "\"$2\"" -- *.html; then
			:
		elif [[ ! "$CDN_HTML" =~ \.html$ ]]; then
			_abort "invalid CDN_HTML=$CDN_HTML"
		elif [[ "$2" =~ \.css$ ]]; then
			echo "<link rel=\"stylesheet\" href=\"$2\" />" >> "$CDN_HTML"
		elif [[ "$2" =~ \.js$ ]]; then
			echo "<script src=\"$2\"><\/script>" >> "$CDN_HTML"
		fi
	fi
}


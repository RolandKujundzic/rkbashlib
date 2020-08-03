#!/bin/bash

#--
# Return program version nn[.mm.kk]
# If $1 is not version number '$1 --version' must be supported
# If $2=1 convert nn.mm.kk into nnmmkk (with leading zeros) e.g. 3.10.8 = 031008, 14.22.72 = 142272 
# 
# @param program name or version number (nn.mm.kk)
# @param optional (1=convert to number) 
# @print int
# shellcheck disable=SC2183,SC2046
#--
function _version {
	local version

	if [[ "$1" =~ ^v?[0-9\.]+$ ]]; then
		version="$1"
	elif command -v "$1" &>/dev/null; then
		version=$({ $1 --version || _abort "$1 --version"; } | head -1 | grep -E -o 'v?[0-9]+\.[0-9\.]+')
	fi

	version="${version/v/}"

	[[ "$version" =~ ^[0-9\.]+$ ]] || _abort "version detection failed ($1)"

	if test "$2" = 1; then
		if [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%02d%02d" $(echo "$version" | tr '.' ' ')
		elif [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%02d%02d%02d" $(echo "$version" | tr '.' ' ')
		else
			_abort "failed to convert $version to number"
		fi
	else
		echo -n "$version"
	fi
}


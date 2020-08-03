#!/bin/bash

#--
# Return program version nn[.mm.kk]
# If $1 is not version number '$1 --version' must be supported
# If $2=1 convert nn.mm.kk into number e.g. 3.0.8 = 30008, 14.22.72 = 142272 
# If $2=2 return main version (nn)
# If $2=4 return main.sub version (nn.mm)
#
# @param program name or version number (nn.mm.kk)
# @param optional flag
# @print int
# shellcheck disable=SC2183,SC2046
#--
function _version {
	local flag version
	flag=$(($2 + 0))

	if [[ "$1" =~ ^v?[0-9\.]+$ ]]; then
		version="$1"
	elif command -v "$1" &>/dev/null; then
		version=$({ $1 --version || _abort "$1 --version"; } | head -1 | grep -E -o 'v?[0-9]+\.[0-9\.]+')
	fi

	version="${version/v/}"

	[[ "$version" =~ ^[0-9\.]+$ ]] || _abort "version detection failed ($1)"

	if [[ $((flag & 1)) = 1 ]]; then
		if [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%d%02d" $(echo "$version" | tr '.' ' ')
		elif [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%d%02d%02d" $(echo "$version" | tr '.' ' ')
		else
			_abort "failed to convert $version to number"
		fi
	elif [[ $((flag & 2)) ]]; then
		echo -n "${version%%.*}"
	elif [[ $((flag & 4)) ]]; then
		echo -n "${version%.*}"
	else
		echo -n "$version"
	fi
}


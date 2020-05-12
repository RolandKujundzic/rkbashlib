#!/bin/bash

#--
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
#--
function _dl_unpack {
	if test -d "$1"; then
		_msg "Use existing unpacked directory $1"
		return
	fi

	local archive
	archive=$(basename "$2")

	if ! test -f "$archive"; then
		_msg "Download $2"
		_wget "$2"
	fi

	test -f "$archive" || _abort "missing $archive - $2 download failed"

	if test "${archive##*.}" = "zip"; then
		_msg "Unpack zip: unzip '$archive'"

		if test -z "$(unzip -l "$archive" | grep "$1\$")"; then
			_mkdir "$1"
			_cd "$1"
			unzip "../$archive" || _abort "unzip '../$archive'"
			_cd ..
		else
			unzip "$archive"
		fi
	else
		_msg "Unpack tar: tar -xf '$archive'"
		tar -xf "$archive" || _abort "tar -xf '$archive'"
	fi

	test -d "$1" || _mv "${archive%.*}" "$1"
}


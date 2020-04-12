#!/bin/bash

#--
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
# @require _abort _msg _mv _mkdir _wget _cd
#--
function _dl_unpack {
	if test -d "$1"; then
		_msg "Use existing unpacked directory $1"
		return
	fi

	local archive=`basename $2`
	if ! test -f "$archive"; then
		_msg "Download $2"
		_wget "$2"
	fi

	test -f "$archive" || _abort "missing $archive - $2 download failed"

	local extension="${archive##*.}"
	if test "$extension" = "zip"; then
		_msg "Unpack zip: unzip '$archive'"

		local has_dir=`unzip -l "$archive" | grep "$1\$"`
		if test -z "$has_dir"; then
			_mkdir "$1"
			_cd "$1"
			unzip "../$archive" || _abort "unzip '../$archive'"
			_cd ..
		else
			unzip "$archive"
		fi
	else
		_msg "Unpack tar: tar -xf '$archive'"
		tar -xf "$archive" 2>/dev/null >/dev/null || _abort "tar -xf '$archive'"
	fi

	test -d "$1" || _mv "${archive%.*}" "$1"
}


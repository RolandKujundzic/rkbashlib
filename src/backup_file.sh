#!/bin/bash

#--
# Backup (realpath) $1 as RKBASH_DIR/backup/$1
# Keep last n backups.
#
# @global RKBASH_DIR
# @param path
# @param keep (default = 5)
#--
function _backup_file {
	local i n path dir base backup backup_dir
	path="$(realpath "$1")"
	test -z "$path" && _abort "no such file '$1'"

	dir="$(dirname "$path")"
	base="$(basename "$path")"
	backup_dir="$(dirname "$RKBASH_DIR")/backup/$dir"
	backup="$backup_dir/$base"
	n="${2:-5}"

	_msg "backup $path"
	_mkdir "$backup_dir"

	test -f "$backup" && _cp "$backup" "$backup.old" >/dev/null

	_cp "$path" "$backup" md5

	if [[ "$CP_FIRST" = '1' || "$CP_KEEP" = '1' ]]; then
		test -f "$backup.old" && _rm "$backup.old" >/dev/null
		return
	fi

	for ((i = n - 1; i > 0; i--)); do
		test -f "$backup.$i" && _cp "$backup.$i" "$backup.$((i + 1))" >/dev/null
	done

	_mv "$backup.old" "$backup.1" >/dev/null
}


#!/bin/bash

#--
# Backup $1 as RKBASH_DIR/backup/replace(/, ._., $1).
# Keep last n backups.
#
# @global RKBASH_DIR
# @param path
# @param keep (default = 5)
#--
function _backup_file {
	test -s "$1" || return
	local i n backup backup_dir
	backup_dir="$(dirname "$RKBASH_DIR")/backup"
	backup="$backup_dir/${1////._.}"
	n="${2:-5}"

	_msg "backup $1 as $backup"
	_mkdir "$backup_dir"

	for ((i = n - 1; i > 0; i--)); do
		test -f "$backup.$i" && _cp "$backup.$i" "$backup_dir.$((i + 1))"
	done

	test -f "$backup" && _cp "$backup" "$backup.1"
	_cp "$1" "$backup"
}


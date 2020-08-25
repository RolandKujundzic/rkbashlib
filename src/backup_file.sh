#!/bin/bash

#--
# Backup (realpath) $1 as RKBASH_DIR/backup/$1
# Keep last n backups. Do not backup if last
# backup is younger than 5sec or was done within
# this script.
#
# @global RKBASH_DIR
# @export BACKUP_FILE
# @param path
# @param keep (default = 5)
# shellcheck disable=SC2034
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

	test "$backup" = "$BACKUP_FILE" && return

	if [[ -f "$backup" && $(stat -c %Y "$backup") -ge $(( $(date +%s) - 5 )) ]]; then
		_msg "keep existing backup (younger than 5s)"
		return
	fi

	_msg "backup $path"
	_mkdir "$backup_dir"

	test -f "$backup" && _cp "$backup" "$backup.old" >/dev/null

	_cp "$path" "$backup" md5
	BACKUP_FILE="$backup"

	if [[ "$CP_FIRST" = '1' || "$CP_KEEP" = '1' ]]; then
		test -f "$backup.old" && _rm "$backup.old" >/dev/null
		return
	fi

	for ((i = n - 1; i > 0; i--)); do
		test -f "$backup.$i" && _cp "$backup.$i" "$backup.$((i + 1))" >/dev/null
	done

	_mv "$backup.old" "$backup.1" >/dev/null
}


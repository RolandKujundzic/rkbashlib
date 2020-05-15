#!/bin/bash

#--
# Execute sql transaction. Use $1 as sql dump directory. 
# If $1/tables.txt exists load table list (sorted in create order) or autodetect ($1/prefix_*.sql). 
# Parameter $2 is action flag (2^n): 1=drop, 2=create, 4=alter, 8=insert, 16=update, 32=autoexec.
# Action dump files are either $1/alter|insert|update.sql or $1/alter|insert|update/table.sql.
# If not autoexec ask before every action.
#
# @param string directory name
# @param int flag 
# @global RKSCRIPT_DIR 
# shellcheck disable=SC2012
#--
function _sql_transaction {
	local flag sql_dir st et sql_dump tables acf i
	flag=$(($2 + 0))
	sql_dir="$1"
	st="START TRANSACTION;"
	et="COMMIT;"

	_require_dir "$sql_dir"
	_mkdir "$RKSCRIPT_DIR/sql_transaction" >/dev/null

	if test -s "$sql_dir/tables.txt"; then
		tables=( "$(cat "$sql_dir/tables.txt")" )
	else
		tables=( "$(ls "$sql_dir/"*_*.sql | sed -E 's/^.+?\/([a-z0-9_]+)\.sql$/\1/i')" )
		st="$st\nSET FOREIGN_KEY_CHECKS=0;"
		et="SET FOREIGN_KEY_CHECKS=1;\n$et"
	fi

	test ${#tables[@]} -lt 1 && _abort "table list is empty"
	test $((flag & 32)) -eq 32 && acf=y

	if test $((flag & 1)) -eq 1; then	
		sql_dump="$RKSCRIPT_DIR/sql_transaction/drop.sql"
		echo -e "$st\n" >"$sql_dump"
		for ((i = ${#tables[@]} - 1; i > -1; i--)); do
			echo "DROP TABLE IF EXISTS ${tables[$i]};" >>"$sql_dump"
		done 
		echo -e "\n$et" >>"$sql_dump"

		AUTOCONFIRM=$acf
		_confirm "Drop ${#tables[@]} tables (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi

	if test $((flag & 2)) -eq 2; then	
		sql_dump="$RKSCRIPT_DIR/sql_transaction/create.sql"
		echo -e "$st\n" >"$sql_dump"
		for ((i = 0; i < ${#tables[@]}; i++)); do
			cat "$sql_dir/${tables[$i]}.sql" >>"$sql_dump"
		done
		echo -e "\n$et" >>"$sql_dump"

		AUTOCONFIRM=$acf
		_confirm "Create tables (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi

	test $((flag & 4)) -eq 4 && _sql_transaction_load "$sql_dir" alter $acf
	test $((flag & 8)) -eq 8 && _sql_transaction_load "$sql_dir" update $acf
	test $((flag & 16)) -eq 16 && _sql_transaction_load "$sql_dir" insert $acf
}


#--
# Helper function. Load $1.
#
# @parma sql directory path
# @param name (alter|insert|update)
# @param autoconfirm
# @global RKSCRIPT_DIR
# shellcheck disable=SC2034
#--
function _sql_transaction_load {
	local sql_dump
	sql_dump="$RKSCRIPT_DIR/sql_transaction/$2.sql"
	_rm "$sql_dump" >/dev/null

	if test -s "$1/$2.sql"; then
		_cp "$1/$2.sql" "$sql_dump"
	elif test -d "$1/$2"; then
		cat "$1/$2/*.sql" > "$sql_dump"
	fi

	if test -s "$sql_dump"; then
		AUTOCONFIRM="$3"
		_confirm "Execute $2 queries (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi
}


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
#--
function _sql_transaction {
	local FLAG=$(($2 + 0))
	local SQL_DIR="$1"
	local ST="START TRANSACTION;"
	local ET="COMMIT;"
	local SQL_DUMP
	local TABLES
	local ACF
	local i

	_require_dir "$SQL_DIR"
	_mkdir "$RKSCRIPT_DIR/sql_transaction" >/dev/null

	if test -s "$SQL_DIR/tables.txt"; then
		TABLES=( `cat "$SQL_DIR/tables.txt"` )
	else
		TABLES=( `ls "$SQL_DIR/"*_*.sql | sed -E 's/^.+?\/([a-z0-9_]+)\.sql$/\1/i'` )
		ST="$ST\nSET FOREIGN_KEY_CHECKS=0;"
		ET="SET FOREIGN_KEY_CHECKS=1;\n$ET"
	fi

	test ${#TABLES[@]} -lt 1 && _abort "table list is empty"
	test $((FLAG & 32)) -eq 32 && ACF=y

	if test $((FLAG & 1)) -eq 1; then	
		SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/drop.sql"
		echo -e "$ST\n" >$SQL_DUMP
		for ((i = ${#TABLES[@]} - 1; i > -1; i--)); do
			echo "DROP TABLE IF EXISTS ${TABLES[$i]};" >>$SQL_DUMP
		done 
		echo -e "\n$ET" >>$SQL_DUMP

		AUTOCONFIRM=$ACF
		_confirm "Drop ${#TABLES[@]} tables (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi

	if test $((FLAG & 2)) -eq 2; then	
		SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/create.sql"
		echo -e "$ST\n" >$SQL_DUMP
		for ((i = 0; i < ${#TABLES[@]}; i++)); do
			cat "$SQL_DIR/${TABLES[$i]}.sql" >>$SQL_DUMP
		done
		echo -e "\n$ET" >>$SQL_DUMP

		AUTOCONFIRM=$ACF
		_confirm "Create tables (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi

	test $((FLAG & 4)) -eq 4 && _sql_transaction_load "$SQL_DIR" alter $ACF
	test $((FLAG & 8)) -eq 8 && _sql_transaction_load "$SQL_DIR" update $ACF
	test $((FLAG & 16)) -eq 16 && _sql_transaction_load "$SQL_DIR" insert $ACF
}


#--
# Helper function. Load $1.
#
# @parma sql directory path
# @param name (alter|insert|update)
# @param autoconfirm
#--
function _sql_transaction_load {
	local SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/$2.sql"
	_rm "$SQL_DUMP" >/dev/null

	if test -s "$1/$2.sql"; then
		_cp "$1/$2.sql" "$SQL_DUMP"
	elif test -d "$1/$2"; then
		cat "$1/$2/*.sql" > "$SQL_DUMP"
	fi

	if test -s "$SQL_DUMP"; then
		AUTOCONFIRM=$3
		_confirm "Execute $2 queries (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi
}


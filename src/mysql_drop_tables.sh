#!/bin/bash

#--
# Drop all tables in database.
#
# @global 
#--
function _mysql_drop_tables {
	_require_global DB_NAME DB_PASS
	_confirm "Drop all tables in $DB_NAME" 1
  test "$CONFIRM" = "y" || return

	local tmp_dir="$RKSCRIPT_DIR/load_dump"
	local drop_sql="$tmp_dir/$DB_NAME.sql"

	_mkdir "$tmpdir"
	echo "SET FOREIGN_KEY_CHECKS = 0;" > $drop_sql
	echo "SELECT concat('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema = '$DB_NAME';" | \
		mysql -N -u $DB_NAME -p$DB_PASS $DB_NAME >> $drop_sql || _abort "create '$drop_sql' failed"
	echo "SET FOREIGN_KEY_CHECKS = 1;" >> $drop_sql
	mysql -u $DB_NAME -p$DB_PASS $DB_NAME < $drop_sql || _abort "drop all tables in $DB_NAME failed - see $drop_sql"
	_rm $drop_sql	
}


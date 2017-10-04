#!/bin/bash

#------------------------------------------------------------------------------
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @param parallel_import (optional - use parallel import if set)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort extract_tgz cd cp rm mv mkdir mysql_load mysql_conn
#------------------------------------------------------------------------------
function _mysql_restore {

	local TMP_DIR="/tmp/mysql_dump"
	local FILE=`basename $1`

	_mkdir $TMP_DIR 1
	_cp "$1" "$TMP_DIR/$FILE"

	_cd $TMP_DIR

	_extract_tgz "$FILE" "tables.txt"

	cat create_tables.sql | sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' > create_tables.fix.sql
	local IS_DIFFERENT=`cmp -b create_tables.sql create_tables.fix.sql`

	if ! test -z "$IS_DIFFERENT"; then
		_mv create_tables.fix.sql create_tables.sql
	else
		_rm create_tables.fix.sql
	fi

	for a in `cat tables.txt`
	do
		# load only create_tables.sql ... write other load commands to restore.sh
		_mysql_load $a".sql"

		if ! test -z "$2" && test "$a" = "create_tables"; then
			_mysql_conn
			echo "create restore.sh"
			echo -e "#!/bin/bash\n" > restore.sh
			echo -e "MYSQL_CONN=$MYSQL_CONN\n" >> restore.sh
			echo 'function _restore {' >> restore.sh
			echo '  echo "start restore $1"' >> restore.sh
			echo '  mysql $MYSQL_CON < $1".sql" &> $1".sql.log" && rm $1".sql" || echo "import $1 failed"' >> restore.sh
			echo '  echo "done."' >> restore.sh
			echo -e "}\n\n" >> restore.sh

			chmod 755 restore.sh
		fi
	done

  if ! test -z "$2"; then
    echo "start table imports in background"  
    . restore.sh

    _rm "create_tables.sql"
    local IMPORT=1
    SECONDS=0

    while test "$IMPORT" = "1"
    do
      IMPORT=0
      for a in `cat tables.txt`
      do
        # sql file is removed after successfull import
        if test -f $a".sql"; then
          IMPORT=1
        else
          echo "$a import finished"
        fi
      done

      sleep 10
    done

    echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
  fi

	_cd

	_rm $TMP_DIR
}


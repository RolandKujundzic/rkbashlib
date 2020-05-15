#!/bin/bash

#--
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @param parallel_import (optional - use parallel import if set)
# @global MYSQL_CONN (call _mysql_conn for mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME")
# shellcheck disable=SC1091,SC2013,SC2016,SC2034
#--
function _mysql_restore {
	local a tmp_dir file import
	tmp_dir="/tmp/mysql_dump"
	file=$(basename "$1")

	_mkdir "$tmp_dir" 1
	_cp "$1" "$tmp_dir/$file"

	_cd "$tmp_dir"

	_extract_tgz "$file" "tables.txt"

	sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' create_tables.sql > create_tables.fix.sql

	if ! test -z "$(cmp -b create_tables.sql create_tables.fix.sql)"; then
		_mv create_tables.fix.sql create_tables.sql
	else
		_rm create_tables.fix.sql
	fi

	for a in $(cat tables.txt); do
		# load only create_tables.sql ... write other load commands to restore.sh
		_mysql_load "$a.sql"

		if ! test -z "$2" && test "$a" = "create_tables"; then
			_mysql_conn
			echo "create restore.sh"
			{
				echo -e "#!/bin/bash\n"
				echo -e "MYSQL_CONN=\"$MYSQL_CONN\"\n"
				echo 'function _restore {'
				echo '  mysql $MYSQL_CONN < $1 &> $1".log" && rm $1 || echo "import $1 failed"'
				echo '  echo "$1 import finished"'
				echo -e "}\n\n"
			} > restore.sh
			_chmod 755 restore.sh
		fi
	done

  if ! test -z "$2"; then
    echo "start table imports in background"  
    source restore.sh

    _rm "create_tables.sql"
    import=1
    SECONDS=0

    while test "$import" = '1'; do
      import=0
      for a in $(cat tables.txt); do
        # sql file is removed after successfull import
        test -f "$a.sql" && import=1
      done

      sleep 10
    done

    echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
  fi

	_cd

	_rm "$tmp_dir"
}


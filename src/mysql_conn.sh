#!/bin/bash

#--
# Export MYSQL_CONN or MYSQL (if parameter is set) connection string.
# If MYSQL_CONN is empty but DB_NAME and DB_PASS exist use these.
# MYSQL_CONN is "mysql -h DBHOST -u DBUSER -pDBPASS DBNAME".
# MYSQL is "mysql -u root".
#
# @abort
# @global MYSQL_CONN DB_NAME DB_PASS
# @export MYSQL_CONN MYSQL 
# @require _abort
# @param require root access
#--
function _mysql_conn {

	if test -z "$1" && test -z "$MYSQL_CONN"; then
		if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		else
			_abort "mysql connection string MYSQL_CONN is empty (DB_NAME=$DB_NAME)"
		fi
	fi

	if test -z "$MYSQL_CONN" && ! test -z "$1" && test "$UID" = "0"; then
		MYSQL_CONN="-u root"
	fi

	local TRY_MYSQL=

	if test -z "$1"; then
    TRY_MYSQL=`(echo "USE $DB_NAME" | mysql $MYSQL_CONN 2>&1) | grep 'ERROR 1045'`

		if test -z "$TRY_MYSQL"; then
			# MYSQL_CONN works
			return
		else
			_abort "mysql connection for $DB_NAME string is invalid: $MYSQL_CONN"
		fi
	fi

	if test -z "$MYSQL"; then
		if ! test -z "$MYSQL_CONN"; then
			MYSQL="mysql $MYSQL_CONN"
		elif ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
			MYSQL="mysql -h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		fi
	fi

	if ! test -z "$MYSQL"; then
    TRY_MYSQL=`(echo "USE mysql" | $MYSQL 2>&1) | grep 'ERROR 1045'`
    if ! test -z "$TRY_MYSQL" && test "$MYSQL" != "mysql -u root"; then
      MYSQL=
    fi
  fi

  if test -z "$MYSQL"; then
    if test "$UID" = "0"; then
      MYSQL="mysql -u root"
    else
      _abort "you must be root to run [mysql -u root]"
    fi
  fi

  TRY_MYSQL=`(echo "USE mysql" | $MYSQL 2>&1) | grep 'ERROR 1045'`
  if ! test -z "$TRY_MYSQL" && test "$MYSQL" != "mysql -u root"; then
    echo "admin access to mysql database failed: $MYSQL"
  fi
}


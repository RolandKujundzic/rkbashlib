#!/bin/bash

#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

FIX_MYSQL_DUMP=1
MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

BACKUP_TODAY="/path/to/mysql_dump."`date +"%Y%m%d"`".tgz"
BACKUP_YESTERDAY="/path/to/mysql_dump."`date --date='-1 day' +"%Y%m%d"`".tgz"

if test -f "$BACKUP_TODAY"; then
  _mysql_restore "$BACKUP_TODAY" 1
elif test -f "$BACKUP_YESTERDAY"; then
  _mysql_restore "$BACKUP_YESTERDAY" 1
else
  _abort "neither yesterdays ($BACKUP_YESTERDAY) nor todays ($BACKUP_TODAY) backup found"
fi


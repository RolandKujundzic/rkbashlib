#!/bin/bash

#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

_mysql_backup /path/to/backup/directory


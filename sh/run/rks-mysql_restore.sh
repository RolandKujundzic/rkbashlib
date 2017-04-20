#!/bin/bash

#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

_mysql_restore /path/to/mysql_dump.sql


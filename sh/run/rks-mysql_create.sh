#!/bin/bash

#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

APP=$0
APP_DESC="Create mysql database and user (dblogin = dbname)"

if ! test -z "$1" && ! test -z "$2"; then
  _mysql_create_db $1 $2
elif test -f settings.php || test -f index.php; then
  _mysql_create_db
else
  _syntax "name password"
fi

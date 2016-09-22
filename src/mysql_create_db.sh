#!/bin/bash

#------------------------------------------------------------------------------
# Create Mysql Database. Define MYSQL (e.g. MYSQL="mysql -u root").
#
# @param dbname = username
# @param password
#------------------------------------------------------------------------------
function _mysql_create_db {
	echo "create mysql database $1"
	echo "CREATE DATABASE work" | $MYSQL
	echo "GRANT ALL ON $1.* TO '$1'@'localhost' IDENTIFIED BY '$2'" | $MYSQL
}


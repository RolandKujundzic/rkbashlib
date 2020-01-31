#!/bin/bash

function call_mysql {
	{ echo "$1" | mysql -u'rkscript' -p'secret' 'rkscript'; } && return 0 || return 1
}


AUTOCONFIRM="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"

_mysql_create_db 'rkscript' 'secret'

_SQL="call_mysql"
_SQL_QUERY[customer_table]="CREATE TABLE customer (id int not null auto_increment, name varchar(30) not null, PRIMARY KEY(id))"
_SQL_QUERY[select_customer]="SELECT id, name FROM customer WHERE id='id'"
_SQL_QUERY[insert_customer]="INSERT INTO customer (name) VALUES ('name')"

CUSTOMER="John Paul Peter Mary Claudia Maria David"

_sql 'execute' 'customer_table'

for a in $CUSTOMER; do
	_SQL_PARAM=([name]="$a")
	_sql 'execute' 'insert_customer'
done

_SQL_PARAM=([id]="3")
_sql 'select' 'select_customer'
echo "${_SQL_COL[id]}: ${_SQL_COL[name]}"

_mysql_drop_db 'rkscript'

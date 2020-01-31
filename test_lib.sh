#!/bin/bash

#. /usr/local/lib/rkscript.sh || { echo "ERROR: . /usr/local/lib/rkscript.sh"; exit 1; }
. lib/rkscript.sh || { echo "ERROR: . /usr/local/lib/rkscript.sh"; exit 1; }


#--
# M A I N
#--

export DB_NAME=rkscript
export DB_PASS=secret

_SQL_QUERY[customer_table]="CREATE TABLE customer (id int not null auto_increment, name varchar(30) not null, PRIMARY KEY(id))"
_SQL_QUERY[select_customer]="SELECT id, name FROM customer WHERE id='id'"
_SQL_QUERY[insert_customer]="INSERT INTO customer (name) VALUES ('name')"

AUTOCONFIRM=yyy
_sql 'execute' "DROP TABLE IF EXISTS customer"
_sql 'execute' 'customer_table'
_sql 'select' 'show tables'
echo "_all=[${_SQL_COL[_all]}] _rows=[${_SQL_COL[_rows]}]"

CUSTOMER="John Paul Peter Mary Claudia Maria David"

for a in $CUSTOMER; do
	AUTOCONFIRM=y
  _SQL_PARAM=([name]="$a")
  _sql 'execute' 'insert_customer'
done

AUTOCONFIRM=y
_SQL_PARAM=([id]="3")
_sql 'select' 'select_customer'
echo "${_SQL_COL[id]}: ${_SQL_COL[name]}"


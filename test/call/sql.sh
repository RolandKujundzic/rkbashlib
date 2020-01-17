#!/bin/bash

function call_mysql {
	echo "echo \"$1\" | mysql -u'db-user' -p'db-pass' db-name"
}


_SQL="call_mysql"
_SQL_QUERY[select_customer]="SELECT * FROM test WHERE id='id'"

_SQL_PARAM=([id]="10")
_sql select 'select_customer'

#!/bin/bash

#--
# Start buildin standalone PHP Webserver
# @param port (default = 15080)
# @global RKSCRIPT_DIR
# @require _require_program _abort _mkdir _confirm _is_running
#--
function _php_server {
	_require_program php
	_mkdir "$RKSCRIPT_DIR" > /dev/null

	local PHP_CODE=
IFS='' read -r -d '' PHP_CODE <<'EOF'
if (preg_match('/\.(php|js|css|html|jpg|jpeg|png|gif|ico)$/', $_SERVER['REQUEST_URI']) && file_exists('./'.$_SERVER['REQUEST_URI'])) {
	return true;
}
EOF

	local PORT=${1:-15080}
	local SERVER_PID=

	if _is_running PORT $PORT; then
		local SERVER_PID=`ps aux | grep -E '[p]hp .+S localhost:15080' | awk '{print $2}'`
		test -z "$SERVER_PID" && _abort "Port $PORT is already used" || \
			_abort "PHP Server is already running on localhost:$PORT\n\nStop PHP Server: kill $SERVER_PID"
	fi
	
	_confirm "Start buildin PHP standalone Webserver" 1
	test "$CONFIRM" = "y" || _abort "user abort"

	{ php -r "$PHP_CODE" -S localhost:$PORT >"$RKSCRIPT_DIR/php_server.log" 2>&1 || _abort "PHP Server failed - see: $RKSCRIPT_DIR/php_server.log"; } &

	local SERVER_PID=`ps aux | grep -E '[p]hp .+S localhost:15080' | awk '{print $2}'` 
	test -z "$SERVER_PID" && _abort "Could not determine Server PID"

	echo -e "\nPHP buildin standalone server started"
	echo "URL: http://localhost:$PORT"
	echo "LOG: tail -f $RKSCRIPT_DIR/php_server.log"
	echo "DOCROOT: $PWD"
	echo -e "STOP: kill $SERVER_PID\n"
}


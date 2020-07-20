#!/bin/bash

#--
# Start buildin standalone PHP Webserver. Use ARG:
#   - user ($USER) 
#   - port (15080)
#   - docroot ($PWD)
#   - script (buildin = RKBASH_DIR/php_server.php)
#	  - host (0.0.0.0)
#
# @call_before _parse_arg "$@" 
# @global RKBASH_DIR ARG
# shellcheck disable=SC2009
#--
function _php_server {
	_require_program php
	_mkdir "$RKBASH_DIR"

	local php_code=
IFS='' read -r -d '' php_code <<'EOF'
<?php

function wsLog($msg) {
	file_put_contents("php://stdout", $msg."\n");
}


function wsHtaccessRedirect($htaccess_file) {
	$htaccess = file($htaccess_file);
	$uri = mb_substr($_SERVER['REQUEST_URI'], 1);

	foreach ($htaccess as $line) {
	  if (mb_substr($line, 0, 12) == 'RewriteRule ' && ($pos = mb_strpos($line, 'index.php')) !== false) {
  	  $rx = '/'.trim(mb_substr($line, 12, $pos - 12)).'/i';

	    if (preg_match($rx, $uri, $match)) {
	    	$redir = trim(mb_substr($line, $pos));
    	  for ($n = 1; $n < count($match); $n++) {
      	  $redir = str_replace('$'.$n, $match[$n], $redir);
	      }

				wsLog("redirect: $redir");
				header('Location: '.$redir);
				exit();
	    }
	  }
	}
}


if (file_exists($_SERVER['DOCUMENT_ROOT'].'/.htaccess')) {
	wsHtaccessRedirect($_SERVER['DOCUMENT_ROOT'].'/.htaccess');
}

if (!preg_match('/\.inc\.([a-z]+)$/i', $_SERVER['SCRIPT_NAME']) &&
		preg_match('/\.(php|js|css|html?|jpe?g|png|gif|ico|svg|eot|ttf|woff2?)$/i', $_SERVER['SCRIPT_NAME']) && 
		file_exists($_SERVER['DOCUMENT_ROOT'].$_SERVER['SCRIPT_NAME'])) {
	return false;
}
else if (getenv('route')) {
	require_once $_SERVER['DOCUMENT_ROOT'].'/'.getenv('route');
}
else {
	wsLog('return 403 ('.$_SERVER['DOCUMENT_ROOT'].$_SERVER['SCRIPT_NAME'].': '.$_SERVER['REQUEST_URI'].')');
	http_response_code(403);
	exit();
}
EOF

	test -z "${ARG[0]}" && _abort 'call _parse_arg "@$" first'

	if test -z "${ARG[script]}"; then
		echo "$php_code" > "$RKBASH_DIR/php_server.php"
		ARG[script]="$RKBASH_DIR/php_server.php"
	fi

	test -z "${ARG[port]}" && ARG[port]=15080
	test -z "${ARG[docroot]}" && ARG[docroot]="$PWD"
	test -z "${ARG[host]}" && ARG[host]="0.0.0.0"

	local log server_pid
	log="$RKBASH_DIR/php_server.log"

	if _is_running "port:${ARG[port]}"; then
		server_pid=$(ps aux | grep -E "[p]hp .+\:${ARG[port]}.+php_server.php" | awk '{print $2}')
		if test -z "$server_pid"; then
			_abort "Port ${ARG[port]} is already used"
		else
			_abort "PHP Server is already running on ${ARG[host]}:${ARG[port]}\n\nStop PHP Server: kill [-9] $server_pid"
		fi
	fi

	_confirm "Start buildin PHP standalone Webserver" 1
	test "$CONFIRM" = "y" || _abort "user abort"

	if test -z "${ARG[user]}"; then
		{ php -t "${ARG[docroot]}" -S ${ARG[host]}:${ARG[port]} "${ARG[script]}" >"$log" 2>&1 || \
			_abort "PHP Server failed - see: $log"; } &
	else
		{ sudo -H -u ${ARG[user]} bash -c "php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1" || \
			_abort "PHP Server failed - see: $log"; } &
		sleep 1
	fi

	server_pid=$(ps aux | grep -E "[p]hp .+\:${ARG[port]}.+php_server.php" | awk '{print $2}')
	test -z "$server_pid" && _abort "Could not determine Server PID"

	echo -e "\nPHP buildin standalone server started"
	echo "URL: http://${ARG[host]}:${ARG[port]}"
	echo "LOG: tail -f $log"
	echo "DOCROOT: ${ARG[docroot]}"
	echo "CMD: php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1"
	echo -e "STOP: kill $server_pid\n"
}


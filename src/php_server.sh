#!/bin/bash

#--
# Start buildin standalone PHP Webserver. Use ARG:
#   - user ($USER) 
#   - port (15080)
#   - docroot ($PWD)
#   - script (buildin = RKBASH_DIR/php_server.php)
#	  - host (0.0.0.0)
#   - list
#
# @global RKBASH_DIR ARG
# shellcheck disable=SC2009
#--
function _php_server {
	test -z "${ARG[0]}" && _abort 'call _rks_app "$@" or _parse_arg "$@" first'
	test -z "${ARG[port]}" && ARG[port]=15080

	if test "${ARG[list]}" = '1'; then
		ps aux | grep -Po '[p]hp .*\-S .+'
		return
	fi

	local server_pid	

	if test "${ARG[stop]}" = '1'; then
		server_pid=$(ps aux | grep -P '[p]hp .*\-S .+:'"${ARG[port]}"'.*' | awk '{print $2}')
		if test "$server_pid" -ge 80; then
			_confirm "Stop buildin php webserver (port ${ARG[port]}, pid $server_pid)" 1
			test "$CONFIRM" = 'y' && kill -9 "$server_pid"
		fi

		return
	fi

	_require_program php
	_mkdir "$RKBASH_DIR"

	test -z "${ARG[script]}" && _php_server_script
	test -z "${ARG[docroot]}" && ARG[docroot]="$PWD"
	test -z "${ARG[host]}" && ARG[host]="0.0.0.0"

	if _is_running "port:${ARG[port]}"; then
		server_pid=$(ps aux | grep -P '[p]hp .*\-S .+:'"${ARG[port]}"'.*' | awk '{print $2}')
		if test -z "$server_pid"; then
			_abort "Port ${ARG[port]} is already used"
		else
			_abort "PHP Server is already running on ${ARG[host]}:${ARG[port]}\n\nStop PHP Server: kill [-9] $server_pid"
		fi
	fi

	_confirm "Start buildin PHP standalone Webserver" 1
	test "$CONFIRM" = "y" && _php_server_start
}


#--
# Start buildin php http server on ARG[host]:ARG[port] with ARG[script] as ARG[user]
# shellcheck disable=SC2009
#--
function _php_server_start {
	local log server_pid

	log="$RKBASH_DIR/php_server.log"

	if test -z "${ARG[user]}"; then
		php -t "${ARG[docroot]}" -S ${ARG[host]}:${ARG[port]} "${ARG[script]}" >"$log" 2>&1 &
	else
		sudo -H -u ${ARG[user]} bash -c "php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1" &
		sleep 1
	fi

	server_pid=$(ps aux | grep -P '[p]hp .*\-S .+:'"${ARG[port]}"'.*' | awk '{print $2}')
	test -z "$server_pid" && _abort "Could not determine Server PID"

	echo -e "\nPHP buildin standalone server started"
	echo "URL: http://${ARG[host]}:${ARG[port]}"
	echo "LOG: tail -f $log"
	echo "DOCROOT: ${ARG[docroot]}"
	echo "CMD: php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1"
	echo -e "STOP: kill $server_pid\n"
}


#--
# If ARG[script] is not set create server script
#--
function _php_server_script {
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

	echo "$php_code" > "$RKBASH_DIR/php_server.php"
	ARG[script]="$RKBASH_DIR/php_server.php"
}


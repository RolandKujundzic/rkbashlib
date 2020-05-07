#!/bin/bash

#--
# Print ssl public key status of /etc/letsencrypt/live/$1/fullchain.pem.
# 
# @export ENDDATE
# @param string domain
# @param string min days (default = 14)
# @print valid, missing or expired
#--
function _check_ssl {
	if ! _cert_file "$1"; then
		echo 'missing'
		return
	fi

	local min_days
	min_days="${2:-14}"

	ENDDATE=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$1/fullchain.pem")
	export ENDDATE=${ENDDATE:9}

	php -r 'print strtotime(getenv("ENDDATE")) > time() + 3600 * 24 * '"$min_days"' ? "valid" : "expired";'
}


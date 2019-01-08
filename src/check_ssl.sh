#!/bin/bash

#------------------------------------------------------------------------------
# Print ssl public key status (in /etc/letsencrypt/live/) and $2 is empty.
# Abort if $2 is set and status != valid.
# 
# @export ENDDATE
# @param string domain
# @param int abort (_abort if set)
# @print valid, missing or expired (if $2 is empty)
# @require _abort
#------------------------------------------------------------------------------
function _check_ssl {
	if ! test -f /etc/letsencrypt/live/$1/fullchain.pem; then
		if ! test -z "$2"; then
			_abort "missing file /etc/letsencrypt/live/$1/fullchain.pem"
		fi

		echo "missing"
		return
	fi

	ENDDATE=`openssl x509 -enddate -noout -in /etc/letsencrypt/live/$1/fullchain.pem`
	export ENDDATE=${ENDDATE:9}
	local STATUS=$(php -r 'print strtotime(getenv("ENDDATE")) > time() + 3600 * 24 * 14 ? "valid" : "expired";')

	if test "$STATUS" = "expired"; then
		_abort "domain $1 in /etc/letsencrypt/live/$1/fullchain.pem has expired"
	fi

	echo $STATUS
}


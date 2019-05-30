#!/bin/bash

#------------------------------------------------------------------------------
# Abort if domain is missing or /.../$2/fullchain.pem doesn not contain DNS:$1.
#
# @param string domain
# @param string domain_dir (/etc/letsencrypt/live/$domain_dir/fullchain.pem
# @require _abort
#------------------------------------------------------------------------------
function _cert_domain {
	local CERT_FILE="/etc/letsencrypt/live/$1/fullchain.pem"

	if ! test -z "$2"; then
		CERT_FILE="/etc/letsencrypt/live/$2/fullchain.pem"
	fi

	if ! test -f "$CERT_FILE"; then
		_abort "no such file $CERT_FILE"
	else   
		local HAS_DOMAIN=`openssl x509 -text -noout -in "$CERT_FILE" | grep "DNS:$1"`
         
		if test -z "$HAS_DOMAIN"; then
			_abort "missing domain $1 in $CERT_FILE"
		fi
 	fi
}



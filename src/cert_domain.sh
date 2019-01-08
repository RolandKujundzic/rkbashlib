#!/bin/bash

#------------------------------------------------------------------------------
# Abort if domain is missing or /.../$2/fullchain.pem doesn not contain DNS:$1.
#
# @param string domain
# @param string domain_dir (/etc/letsencrypt/live/$domain_dir/fullchain.pem
# @require _abort
#------------------------------------------------------------------------------
function _cert_domain {
	if ! test -f "/etc/letsencrypt/live/$1/fullchain.pem"; then
		_abort "no such file /etc/letsencrypt/live/$1/fullchain.pem"
  	fi
     
	local HAS_DOMAIN=`openssl x509 -text -noout -in "/etc/letsencrypt/live/$1/fullchain.pem" | grep "DNS:$1"`
         
	if test -z "$HAS_DOMAIN"; then
		_abort "missing domain $1 in /etc/letsencrypt/live/$1/fullchain.pem"
	fi
}



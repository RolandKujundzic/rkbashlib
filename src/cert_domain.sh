#!/bin/bash

#------------------------------------------------------------------------------
# Append $1 to MISSING_DOMAIN if /.../$2/fullchain.pem doesn not contain DNS:$1.
# Return false if not found.
#
# @global MISSING_DOMAIN
# @param string domain
# @param string domain_dir (/etc/letsencrypt/live/$domain_dir/fullchain.pem
# @return boolean
#------------------------------------------------------------------------------
function _cert_domain {
	if ! test -f "/etc/letsencrypt/live/$1/fullchain.pem"; then
  		return false
  	fi
     
	local HAS_DOMAIN=`openssl x509 -text -noout -in "/etc/letsencrypt/live/$1/fullchain.pem" | grep "DNS:$1"`
         
	if test -z "$HAS_DOMAIN"; then
		MISSING_DOMAIN="$  MISSING_DOMAIN $1"
		return false
	fi

	return true
}



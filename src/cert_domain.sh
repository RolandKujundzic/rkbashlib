#!/bin/bash

#--
# Abort if domain is missing or /.../$2/fullchain.pem doesn not contain DNS:$1.
#
# @param string domain
# @param string domain_dir (/etc/letsencrypt/live/$domain_dir/fullchain.pem
#--
function _cert_domain {
	local cert_file has_domain
	cert_file="/etc/letsencrypt/live/$1/fullchain.pem"

	if ! test -z "$2"; then
		cert_file="/etc/letsencrypt/live/$2/fullchain.pem"
	fi

	if ! test -f "$cert_file"; then
		_abort "no such file $cert_file"
	else   
		has_domain=$(openssl x509 -text -noout -in "$cert_file" | grep "DNS:$1")
         
		if test -z "$has_domain"; then
			_abort "missing domain $1 in $cert_file"
		fi
 	fi
}


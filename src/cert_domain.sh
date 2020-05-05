#!/bin/bash

#--
# Abort if ssl certificate is missing or does not contain subdomain.
#
# @param string domain
# @param string subdomain list (optional)
#--
function _cert_domain {
	_cert_file "$1"
	local has_domain

	has_domain=$(openssl x509 -text -noout -in "$CERT_FULL" | grep "DNS:*.$1")
	test -z "$has_domain" || return

	has_domain=$(openssl x509 -text -noout -in "$CERT_FULL" | grep "DNS:$1")
	test -z "$has_domain" && _abort "missing domain $1 in $CERT_FULL"

	for a in $2; do
		has_domain=$(openssl x509 -text -noout -in "$CERT_FULL" | grep "DNS:$a.$1")
		test -z "$has_domain" && _abort "missing domain $a.$1 in $CERT_FULL"
	done
}


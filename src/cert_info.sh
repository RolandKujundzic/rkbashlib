#!/bin/bash

#--
# Abort if ssl certificate is missing or does not contain subdomain.
#
# @param string domain|path/to/fullchain.pem
# @export CERT_DNS CERT_GMT CERT_DOMAIN CERT_DOMAINS CERT_ISSUER CERT_UNTIL CERT_FULL
# @param string subdomain list (optional)
# shellcheck disable=SC2119,SC2034
#--
function _cert_info {
	local domain

	if test -f "$1"; then
		CERT_FULL="$1"
	else
		_cert_file "$1"
		domain="$1"
		test -z "$CERT_SUB" || domain="$CERT_SUB"
	fi

	local certinfo dns
	certinfo=$(openssl x509 -text -noout -in "$CERT_FULL")
	dns=$(openssl x509 -in "$CERT_FULL" -text | grep "DNS:" | sed -E -e 's/,? ?DNS\:/ /g' | _trim)

	test -z "$domain" && domain=$(echo "$certinfo" | grep -E -o 'CN = .+\.[a-z]+' | grep -v 'Encrypt Authority' | sed 's/CN = //')
	test -z "$domain" && domain=$(echo "$certinfo" | grep -E -o 'Subject\: CN=.+\.[a-z]+' | sed 's/Subject: CN=//')
	
	CERT_DOMAIN="$domain"
	CERT_ISSUER=$(echo "$certinfo" | grep 'Issuer:' | sed -E 's/.+O = (.+), CN =.+\.[a-z]+/\1/')
	CERT_GMT=$(echo "$certinfo" | grep "GMT" | _trim)
	CERT_DNS=$(echo "$certinfo" | grep "DNS:" | _trim)
	CERT_UNTIL=$(echo "$certinfo" | grep "GMT" | grep -o -E 'Not After .+' | sed -E -e 's/.+\: (.+ GMT).*/\1/i') 
	CERT_DOMAINS="$dns"

	[[ "$CERT_DNS" =~ DNS:*.$domain ]] && return
	[[ "$CERT_DNS" =~ DNS:$domain ]] || _abort "missing domain $domain in $CERT_FULL"

	for a in $2; do
		[[ "$CERT_DNS" =~ DNS:$a.$domain ]] || _abort "missing domain $a.$domain in $CERT_FULL"
	done
}


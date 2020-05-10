#!/bin/bash

#--
# Abort if ssl certificate is missing or does not contain subdomain.
#
# @param string domain|path/to/fullchain.pem
# @export CERT_DNS CERT_GMT CERT_DOMAINS CERT_UNTIL CERT_FULL
# @param string subdomain list (optional)
# shellcheck disable=SC2034
#--
function _cert_domain {
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

	if test -z "$domain"; then
		domain=$(echo "$certinfo" | grep -E -o 'CN = .+' | grep -v 'Encrypt Authority' | sed 's/CN = //')
	fi

	CERT_GMT=$(echo "$certinfo" | grep "GMT" | _trim)
	CERT_DNS=$(echo "$certinfo" | grep "DNS:" | _trim)
	CERT_UNTIL=$(echo "$certinfo" | grep "GMT" | grep -o -E 'Not After .+' | sed -E -e 's/.+\: (.+ GMT).*/\1/i') 
	CERT_DOMAINS=( "$dns" )

	[[ "$CERT_DNS" =~ DNS:*.$domain ]] && return
	[[ "$CERT_DNS" =~ DNS:$domain ]] || _abort "missing domain $domain in $CERT_FULL"

	for a in $2; do
		[[ "$CERT_DNS" =~ DNS:$a.$domain ]] || _abort "missing domain $a.$domain in $CERT_FULL"
	done
}


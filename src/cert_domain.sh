#!/bin/bash

#--
# Abort if ssl certificate is missing or does not contain subdomain.
#
# @param string domain
# @export CERT_DNS CERT_GMT CERT_DOMAINS
# @param string subdomain list (optional)
# shellcheck disable=SC2034
#--
function _cert_domain {
	_cert_file "$1"

	local certinfo dns
	certinfo=$(openssl x509 -text -noout -in "$CERT_FULL")
	dns=$(openssl x509 -in "$CERT_FULL" -text | grep "DNS:" | sed -E -e 's/DNS://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/, / /g')

	CERT_GMT=$(echo "$certinfo" | grep "GMT" | _trim)
	CERT_DNS=$(echo "$certinfo" | grep "DNS:" | _trim)
	CERT_DOMAINS=( $dns )

	[[ "$CERT_DNS" =~ DNS:*.$1 ]] && return
	[[ "$CERT_DNS" =~ DNS:$1 ]] || _abort "missing domain $1 in $CERT_FULL"

	for a in $2; do
		[[ "$CERT_DNS" =~ DNS:$a.$1 ]] || _abort "missing domain $a.$1 in $CERT_FULL"
	done
}


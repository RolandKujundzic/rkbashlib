#!/bin/bash

#--
# Export path to SSL certificate files:
#
# - CERT_ENGINE=acme.sh|certbot
# - CERT_FULL=~/.acme.sh/domain.tld/fullchain.cer or /etc/letsencrypt/live/domain.tld/fullchain.pem
# - CERT_KEY=~/.acme.sh/domain.tld/domain.tld.key or /etc/letsencrypt/live/domain.tld/privkey.pem
# - CERT_PUB=~/.acme.sh/domain.tld/domain.tld.cer or /etc/letsencrypt/live/domain.tld/cert.pem
# - CERT_CA=~/.acme.sh/domain.tld/ca.cer or /etc/letsencrypt/live/domain.tld/chain.pem
#
# @param domain.tld
# @export CERT_ENGINE|FULL|KEY|CA|PUB
# shellcheck disable=SC2034
#--
function _cert_file {
	local domain
	domain="$1"
	
	test -z "$domain" && _abort "empty domain parameter"

	if test -s "$HOME/.acme.sh/$domain/fullchain.cer"; then
		CERT_ENGINE="acme.sh"

		if test "$UID" = "0" && test -s "/etc/letsencrypt/acme.sh/$domain/fullchain.pem"; then
			if test -L "/etc/letsencrypt/live/$domain"; then
				CERT_FULL="/etc/letsencrypt/live/$domain/fullchain.pem"
				CERT_KEY="/etc/letsencrypt/live/$domain/privkey.pem"
				CERT_PUB="/etc/letsencrypt/live/$domain/cert.pem"
				CERT_CA="/etc/letsencrypt/live/$domain/chain.pem"
			else
				CERT_FULL="/etc/letsencrypt/acme.sh/$domain/fullchain.pem"
				CERT_KEY="/etc/letsencrypt/acme.sh/$domain/privkey.pem"
				CERT_PUB="/etc/letsencrypt/acme.sh/$domain/cert.pem"
				CERT_CA="/etc/letsencrypt/acme.sh/$domain/chain.pem"
			fi
		else
			CERT_FULL="$HOME/.acme.sh/$domain/fullchain.cer"
			CERT_KEY="$HOME/.acme.sh/$domain/$domain.key"
			CERT_PUB="$HOME/.acme.sh/$domain/$domain.cer"
			CERT_CA="$HOME/.acme.sh/$domain/ca.cer"
		fi
	elif test -d "/etc/letsencrypt/archive/$domain" && test -L "/etc/letsencrypt/live/$domain/fullchain.pem"; then
		_run_as_root
		CERT_ENGINE="certbot"
		CERT_FULL="/etc/letsencrypt/live/$domain/fullchain.pem"
		CERT_KEY="/etc/letsencrypt/live/$domain/privkey.pem"
		CERT_PUB="/etc/letsencrypt/live/$domain/cert.pem"
		CERT_CA="/etc/letsencrypt/live/$domain/chain.pem"
	else
		_abort "found neither $HOME/.acme.sh/$domain/fullchain.cer nor /etc/letsencrypt/live/$domain/fullchain.pem"
	fi
}


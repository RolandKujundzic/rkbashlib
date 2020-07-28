#!/bin/bash

#--
# Export path to SSL certificate files:
#
# - CERT_ENGINE=acme.sh|certbot
# - CERT_SUB=sub.domain.tld
# - CERT_FULL=~/.acme.sh/domain.tld/fullchain.cer or /etc/letsencrypt/live/domain.tld/fullchain.pem
# - CERT_KEY=~/.acme.sh/domain.tld/domain.tld.key or /etc/letsencrypt/live/domain.tld/privkey.pem
# - CERT_PUB=~/.acme.sh/domain.tld/domain.tld.cer or /etc/letsencrypt/live/domain.tld/cert.pem
# - CERT_CA=~/.acme.sh/domain.tld/ca.cer or /etc/letsencrypt/live/domain.tld/chain.pem
# - CERT_CONF=~/.acme.sh/domain.tld/domain.tld.conf
#
# @param domain.tld|.../domain.tld/fullchain.cer
# @param abort if missing (default = 1)
# @export CERT_ENGINE|SUB|FULL|KEY|CA|PUB
# shellcheck disable=SC2034,SC2086
# return boolean
#--
function _cert_file {
	local domain res acme_dir le_live le_acme subdomain
	domain="$1"

	test -z "$domain" && _abort "empty domain parameter"
	if test -f "$1"; then
		domain=$(dirname "$1")
		domain=$(basename "$domain")
		[[ "$domain" =~ ^.+\..+\..+$ ]] && domain="${domain#*.}"
	fi	

	acme_dir="$HOME/.acme.sh/$domain"
	le_live="/etc/letsencrypt/live/$domain"
	le_acme="/etc/letsencrypt/acme.sh/$domain"

	CERT_ENGINE=
	CERT_SUB=
	CERT_FULL=
	CERT_KEY=
	CERT_PUB=
	CERT_CA=
	CERT_CONF=
	res=1

	if test -s "$acme_dir/fullchain.cer"; then
		CERT_ENGINE="acme.sh"
	else
		subdomain=$(ls $HOME/.acme.sh/*.$domain/fullchain.cer 2>/dev/null)
		if [[ -n "$subdomain" && -s "$subdomain" ]]; then
			acme_dir=$(dirname $subdomain)
			domain=$(basename $acme_dir)
			CERT_ENGINE="acme.sh"
			CERT_SUB=$domain
		fi
	fi

	if test "$CERT_ENGINE" = "acme.sh"; then
		CERT_FULL="$acme_dir/fullchain.cer"
		CERT_KEY="$acme_dir/$domain.key"
		CERT_PUB="$acme_dir/$domain.cer"
		CERT_CA="$acme_dir/ca.cer"
		CERT_CONF="$acme_dir/$domain.conf"
		res=0
	fi

	if [[ "$UID" = "0" && -n "$CERT_FULL" ]]; then
		if test -L "$le_live" || test -L "$le_live/fullchain.pem"; then
			CERT_FULL="$le_live/fullchain.pem"
			CERT_KEY="$le_live/privkey.pem"
			CERT_PUB="$le_live/cert.pem"
			CERT_CA="$le_live/chain.pem"
		elif test -s "$le_acme/fullchain.pem"; then
			CERT_FULL="$le_acme/fullchain.pem"
			CERT_KEY="$le_acme/privkey.pem"
			CERT_PUB="$le_acme/cert.pem"
			CERT_CA="$le_acme/chain.pem"
		fi
	fi

	if test -z "$CERT_FULL"; then
		test "$UID" = "0" || echo "missing $acme_dir/fullchain.cer - change into root to read /etc/letsencrypt/..."
		test -d "$HOME/.acme.sh" || _run_as_root
		if test -d "/etc/letsencrypt/archive/$domain" && test -L "$le_live/fullchain.pem"; then
			CERT_ENGINE="certbot"
			CERT_FULL="$le_live/fullchain.pem"
			CERT_KEY="$le_live/privkey.pem"
			CERT_PUB="$le_live/cert.pem"
			CERT_CA="$le_live/chain.pem"
			res=0
		fi
	fi

	[[ -z "$CERT_FULL" && "$2" != "0" ]] && \
		_abort "found neither $acme_dir/fullchain.cer nor $le_live/fullchain.pem"

	return $res
}


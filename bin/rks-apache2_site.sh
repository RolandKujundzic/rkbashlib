#!/bin/bash
MERGE2RUN="copyright abort syntax run_as_root cd confirm rks-apache2_site"


#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#


#------------------------------------------------------------------------------
# Abort with error message.
#
# @param abort message
#------------------------------------------------------------------------------
function _abort {
	echo -e "\nABORT: $1\n\n" 1>&2
	exit 1
}


#------------------------------------------------------------------------------
# Abort with SYNTAX: message.
# Usually APP=$0
#
# @global APP, APP_DESC
# @param message
#------------------------------------------------------------------------------
function _syntax {
	echo -e "\nSYNTAX: $APP $1\n" 1>&2

	if ! test -z "$APP_DESC"; then
		echo -e "$APP_DESC\n\n" 1>&2
	else
		echo 1>&2
	fi

	exit 1
}


#------------------------------------------------------------------------------
# Abort if user is not root.
#
# @require abort
#------------------------------------------------------------------------------
function _run_as_root {
	if test "$UID" != "0"
	then
		_abort "Please change into root and try again"
	fi
}


#------------------------------------------------------------------------------
# Change to directory $1. If parameter is empty and _cd was executed before 
# change to last directory.
#
# @param path
# @export LAST_DIR
# @require abort
#------------------------------------------------------------------------------
function _cd {
	echo "cd '$1'"

	if test -z "$1"
	then
		if ! test -z "$LAST_DIR"
		then
			_cd "$LAST_DIR"
			return
		else
			_abort "empty directory path"
		fi
	fi

	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	LAST_DIR="$PWD"

	cd "$1" || _abort "cd '$1' failed"
}


#------------------------------------------------------------------------------
# Show "message  Press y or n  " and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 sec expired.
#
# @param string message
# @export CONFIRM
#------------------------------------------------------------------------------
function _confirm {
	CONFIRM=n

	echo -n "$1  y [n]  "
	read -n1 -t 10 CONFIRM
	echo

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}


#------------------------------------------------------------------------------
function _http_conf {
	HTTP_CONF="<VirtualHost *:80>
ServerName $DOMAIN
ServerAdmin $EMAIL
DocumentRoot $DOCROOT

ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined

<Directory />
	Options -Indexes +FollowSymLinks
	AllowOverride All
	Require all granted

	<Files ~ \"\.(inc\.html|conf|ser|sql|json)$\">
		Require all denied
	</Files>

	<FilesMatch \"^\.\">
		Require all denied
	</FilesMatch>

</Directory>
</VirtualHost>"
}


#------------------------------------------------------------------------------
function _https_conf {
	HTTPS_CONF="
<VirtualHost *:80>
ServerName $DOMAIN
$REDIRECT
</VirtualHost>

<IfModule mod_ssl.c>
	<VirtualHost _default_:443>
		ServerName $DOMAIN

		ServerAdmin $EMAIL
		DocumentRoot $DOCROOT

		ErrorLog \${APACHE_LOG_DIR}/error.log
		CustomLog \${APACHE_LOG_DIR}/access.log combined

		<Directory />
			Options -Indexes +FollowSymLinks
			AllowOverride All
			Require all granted

			<Files ~ \"\.(inc\.html|conf|ser|sql|json)$\">
				Require all denied
			</Files>

			<FilesMatch \"^\.\">
				Require all denied
			</FilesMatch>

			<FilesMatch \"\.(php)$\">
				SSLOptions +StdEnvVars
			</FilesMatch>
		</Directory>

		SSLEngine on
		SSLCertificateFile      /etc/letsencrypt/live/$DOMAIN/fullchain.pem
		SSLCertificateKeyFile   /etc/letsencrypt/live/$DOMAIN/privkey.pem
	</VirtualHost>
</IfModule>"
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

APP=$0
APP_DESC="Create apache2 http and https site configuration"

_run_as_root
_cd /etc/apache2/sites-available

# parse parameter
for i in "$@"; do
	case $i in
		domain=*)
			DOMAIN="${i#*=}"
			shift
			;;
		email=*)
			EMAIL="${i#*=}"
			shift
			;;
		docroot=*)
			DOCROOT="${i#*=}"
			shift
			;;
		ssl_redir=*)
			SSL_REDIR="${i#*=}"
			shift
			;;
		*)
			# ignore unknown
			;;
	esac
done

if test -z "$DOMAIN" || test -z "$EMAIL" || test -z "$DOCROOT"; then
	_syntax "domain=name.tld email=admin@name.tld docroot=/path/to/name.tld [ssl_redir=www|yes|no]"
fi

if ! test -d "$DOCROOT"; then
	_abort "No such directory $DOCROOT"
fi

if test "$SSL_REDIR" = "yes"; then
	REDIRECT="Redirect / https://$DOMAIN/"
elif test "$SSL_REDIR" = "www"; then
	REDIRECT="Redirect / https://www.$DOMAIN/"
else
	REDIRECT=""
fi

HTTP_SITE="80-"$DOMAIN".conf"
HTTPS_SITE="443-"$DOMAIN".conf"

if test -f $HTTP_SITE; then
	_confirm "$PWD/$HTTP_SITE already exists - remove and continue?"
	test "$CONFIRM" = "n" && _abort "keep existing $HTTP_SITE"
fi

_http_conf
echo "$HTTP_CONF" > $HTTP_SITE

if test -f $HTTPS_SITE; then
	_confirm "$PWD/$HTTPS_SITE already exists - remove and continue?"
	test "$CONFIRM" = "n" && _abort "keep existing $HTTPS_SITE"
fi

_https_conf
echo "$HTTPS_CONF" > $HTTPS_SITE

echo -e "\n$HTTP_SITE and $HTTPS_SITE have been created in $PWD
Run the following command to activate site:

a2ensite $HTTP_SITE # don't activate if SSL_REDIR=www|yes
a2ensite $HTTPS_SITE # don't activate if you have no SSL certificate
service apache2 reload\n\n"


#!/bin/bash

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
	_syntax "domain=name.tld email=admin@name.tld docroot=/webhome/domain[.tld]/www [ssl_redir=www|yes|no]"
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


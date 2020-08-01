#!/bin/bash

#--
# Install nginx, php_fpm and php site
# shellcheck disable=SC2016,SC2012
#--
function nginx_php_fpm {
	local site php_fpm
	site=/etc/nginx/sites-available/default

	_install_nginx

	if [[ -f "$site" && ! -f "${site}.orig" ]]; then
		_orig "$site"
		echo "changing $site"
		echo 'server {
listen 80 default_server; root /var/www/html; index index.html index.htm index.php; server_name localhost;
location / { try_files $uri $uri/ =404; }
location ~ \.php$ { fastcgi_pass unix:/var/run/php5-fpm.sock; fastcgi_index index.php; include fastcgi_params; }
}' > "$site"
	fi

	php_fpm=php$(ls /etc/php/*/fpm/php.ini | sed -E 's#/etc/php/(.+)/fpm/php.ini#\1#')-fpm
	_service "$php_fpm" restart
	_service nginx restart
}


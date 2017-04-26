#!/bin/bash

#------------------------------------------------------------------------------
# Install composer (getcomposer.org). Use init parameter to install apigen/apigen
# and phpunit/phpunit. Use install if 
#
# @param [|init|remove|install] (optional - default = empty)
# @require rm
#------------------------------------------------------------------------------
function _composer {
	local DO="$1"
	local GLOBAL_COMPOSER=`which composer`
	local LOCAL_COMPOSER=

	if test -f "composer.phar"; then
		LOCAL_COMPOSER=composer.phar
	fi

	if test -z "$DO"; then
		echo -e "\nWhat do you want to do?\n"

		if test -z "$GLOBAL_COMPOSER" && test -z "$LOCAL_COMPOSER"; then
			DO=l
			echo "[g]+ENTER = global composer installation: /usr/local/bin/composer"
			echo "[l]+ENTER = local composer installation: composer.phar"
		else
			DO=u

			if test -f composer.json; then
				echo "[i]+ENTER = install packages from composer.json"
				echo "[u]+ENTER = update packages from composer.json"
			fi

			if ! test -z "$LOCAL_COMPOSER"; then
				echo "[r]+ENTER = remove local composer.phar"
			fi
		fi

 		echo -e "[q]+ENTER = quit\n\n"
		echo -n "If you wait 10 sec [$DO] will be selected. Your Choice? "
		read -t 10 USER_DO

		if ! test -z "$USER_DO"; then
			DO=$USER_DO
		fi

		if test "$DO" = "q"; then
			return
		fi
	fi

	if test "$DO" = "remove" || test "$DO" = "r"; then
		echo "remove composer"
		_rm "composer.phar vendor composer.lock ~/.composer"
	fi

	if test "$DO" = "g" || test "$DO" = "l"; then
		php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
		php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

		test -f composer-setup.php || _abort "composer-setup.php missing"

		echo -n "install composer as "
		if test "$DO" = "g"; then
			echo "/usr/local/bin/composer - Enter root password if asked"
			sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
		else
			echo "composer.phar"
			php composer-setup.php
		fi

		php -r "unlink('composer-setup.php');"

		# curl -sS https://getcomposer.org/installer | php
	fi

	local COMPOSER=
	if ! test -z "$LOCAL_COMPOSER"; then
		COMPOSER="php composer.phar"
	elif ! test -z "$GLOBAL_COMPOSER"; then
		COMPOSER="composer"
	fi

	if test "$DO" = "init" || test "$DO" = "d"; then
		$COMPOSER require --dev apigen/apigen
	fi

	if test -f composer.json; then
		if test "$DO" = "install" || test "$DO" = "i"; then
			$COMPOSER install
		elif test "$DO" = "u"; then
			$COMPOSER update
		fi
	fi
}


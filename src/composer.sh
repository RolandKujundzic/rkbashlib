#!/bin/bash

#--
# Install composer (getcomposer.org). If no parameter is given ask for action
# or execute default action (install composer if missing otherwise update) after
# 10 sec. 
#
# @param [install|update|remove] (empty = default = update or install)
#--
function _composer {
	local action global_comp local_comp user_action cmd
	global_comp=$(command -v composer)
	action="$1"

	test -f "composer.phar" && local_comp=composer.phar

	if test -z "$action"; then
		echo -e "\nWhat do you want to do?\n"

		if [[ -z "$global_comp" && -z "$local_comp" ]]; then
			action=l
			echo "[g] = global composer installation: /usr/local/bin/composer"
			echo "[l] = local composer installation: composer.phar"
		else
			if test -f composer.json; then
				action=i
				test -d vendor && action=u

				echo "[i] = install packages from composer.json"
				echo "[u] = update packages from composer.json"
				echo "[a] = update vendor/composer/autoload*"
			fi

			if test -n "$local_comp"; then
				echo "[r] = remove local composer.phar"
			fi
		fi

 		echo -e "[q] = quit\n\n"
		echo -n "Type ENTER or wait 10 sec to select default. Your Choice? [$action]  "
		read -n1 -r -t 10 user_action
		echo

		test -z "$user_action" || action=$user_action
		test "$action" = "q" && return
	fi

	if test "$action" = "remove" || test "$action" = "r"; then
		echo "remove composer"
		_rm "composer.phar vendor composer.lock ~/.composer"
	fi

	if test "$action" = "g" || test "$action" = "l"; then
		echo -n "install composer as "
		if test "$action" = "g"; then
			echo "/usr/local/bin/composer - Enter root password if asked"
			_composer_phar /usr/local/bin/composer
		else
			echo "composer.phar"
			_composer_phar
		fi
	fi

	if test -n "$local_comp"; then
		cmd="php composer.phar"
	elif test -n "$global_comp"; then
		cmd="composer"
	fi

	if test -f composer.json; then
		if test "$action" = "install" || test "$action" = "i"; then
			$cmd install
		elif test "$action" = "update" || test "$action" = "u"; then
			$cmd update
		elif test "$action" = "a"; then
			$cmd dump-autoload -o
		fi
	fi
}


#!/bin/bash

#--
# Install composer (getcomposer.org). If no parameter is given ask for action
# or execute default action (install composer if missing otherwise update) after
# 10 sec. 
#
# @param [install|update|remove] (empty = default = update or install)
# shellcheck disable=SC2120
#--
function _composer {
	local action cmd
	action="$1"

	if [[ ! -f 'composer.phar' && ! -f '/usr/local/bin/composer' ]]; then
		_composer_install
		test "$action" = 'q' && return
	fi

	cmd=$(command -v composer)
	test -z "$cmd" && cmd='php composer.phar'

	if test -z "$action"; then
		_composer_ask
		test "$action" = 'q' && return
	fi

	$cmd validate --no-check-publish 2>/dev/null || \
		_abort "$cmd validate --no-check-publish"

	if test -f composer.json; then
		if test "$action" = 'i'; then
			$cmd install
		elif test "$action" = 'u'; then
			$cmd update
		elif test "$action" = 'a'; then
			$cmd dump-autoload -o
		fi
	fi
}


#--
# Install composer globally or as ./composer.phar
# @global action
#--
function _composer_install {
	ASK_DESC="[g] = Global installation as /usr/local/bin/composer\n[l] = Local installation as ./composer.phar"
	_ask 'Install composer' '<g|l>'

	if test "$ANSWER" = 'g'; then
		echo 'install composer as /usr/local/bin/composer - Enter root password if asked'
		_composer_phar /usr/local/bin/composer
	elif test "$ANSWER" = 'l'; then
		echo 'install composer as ./composer.phar'
		_composer_phar
	else
		action='q'
	fi
}


#--
# @global action 
# shellcheck disable=SC2034
#--
function _composer_ask {
	if ! test -f 'composer.json'; then
		action='q'
		return
	fi

	ask='<i'
	ASK_DESC="[i] = install packages from composer.json"
	ASK_DEFAULT='i'

	if test -d 'vendor'; then
		ASK_DESC="$ASK_DESC\n[u] = update packages from composer.json\n[a] = update vendor/composer/autoload*"
		ASK_DEFAULT='u'
		ask="$ask|u|a"
	fi

	if test -f 'composer.phar'; then
		ask="$ask|r"
		ASK_DESC="$ASK_DESC\n[r] = remove local composer.phar"
	fi

	ASK_DESC="$ASK_DESC\n[q] = quit"
	_ask 'Composer action?' "$ask|q>" 1
	action=$ANSWER

	if test "$action" = "r"; then
		echo "remove composer"
		_rm "composer.phar vendor composer.lock ~/.composer"
		action='q'
	fi
}


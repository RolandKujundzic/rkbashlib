#!/bin/bash

test -z "$RKSCRIPT_SH" || return
RKSCRIPT_SH=1

test -z "$APP" && APP="$0"
test -z "$APP_PID" && export APP_PID="$APP_PID $$"
test -z "$CURR" && CURR="$PWD"


test -z "$RKSCRIPT_DIR" && RKSCRIPT_DIR="$HOME/.rkscript/$$"

for a in ps head grep awk find sed sudo cd chown chmod mkdir rm ls; do
  command -v $a >/dev/null || { echo "ERROR: missing $a"; exit 1; }
done

#--
# Abort with error message. Use NO_ABORT=1 for just warning output (return 1, export ABORT=1).
#
# @exit
# @global APP NO_ABORT
# @param abort message
#--
function _abort {
	if test "$NO_ABORT" = 1; then
		ABORT=1
		echo "WARNING: $1"
		return 1
	fi

	echo -e "\nABORT: $1\n\n" 1>&2

	local other_pid=

	if ! test -z "$APP_PID"; then
		# make shure APP_PID dies
		for a in $APP_PID; do
			other_pid=`ps aux | grep -E "^.+\\s+$a\\s+" | awk '{print $2}'`
			test -z "$other_pid" || kill $other_pid 2> /dev/null 1>&2
		done
	fi

	if ! test -z "$APP"; then
		# make shure APP dies
		other_pid=`ps aux | grep "$APP" | awk '{print $2}'`
		test -z "$other_pid" || kill $other_pid 2> /dev/null 1>&2
	fi

	exit 1
}


#--
# Create apigen documentation for php project in docs/apigen.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/apigen)
# @require _abort _require_program _require_dir _mkdir _cd _composer_json _confirm _rm
#--
function _apigen_doc {
  local DOC_DIR=./docs/apigen
	local PRJ="docs/.apigen"
	local BIN="$PRJ/vendor/apigen/apigen/bin/apigen"
	local SRC_DIR=./src

	_mkdir "$DOC_DIR"
	_mkdir "$PRJ"
	_require_program composer

	local CURR="$PWD"

	if ! test -f "$PRJ/composer.json"; then
		_cd "$PRJ"
		_composer_json "rklib/rkphplib_doc_apigen"
		composer require "apigen/apigen:dev-master"
		composer require "roave/better-reflection:dev-master#c87d856"
		_cd "$CURR"
	fi

	if ! test -s "$BIN"; then
		_cd "$PRJ"
		composer update
		_cd "$CURR"
	fi

	if ! test -z "$1"; then
		SRC_DIR="$1"
	fi

	if ! test -z "$2"; then
		DOC_DIR="$2"
	fi

	_require_dir "$SRC_DIR"

	if test -d "$DOC_DIR"; then
		_confirm "Remove existing documentation directory [$DOC_DIR] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$DOC_DIR"
		fi
	fi

	echo "Create apigen documentation"
	echo "$BIN generate '$SRC_DIR' --destination '$DOC_DIR'"
	$BIN generate "$SRC_DIR" --destination "$DOC_DIR"
}


declare -A API_QUERY

#--
# Query $API_QUERY[url]/$1. Set $API_QUERY[log|out]. Abort if "query failed|no result".
#
# @param string query type curl|func|wget
# @param string query string
# @param hash query parameter
# @global API_QUERY
#--
function _api_query {
	test -z "$1" && _abort "missing query type - use curl|func|wget"
	test -z "$2" && _abort "missing query string"

	local OUT_F="$RKSCRIPT_DIR/api_query.res"	
	local LOG_F="$RKSCRIPT_DIR/api_query.log"	
	local ERR_F="$RKSCRIPT_DIR/api_query.err"

	echo '' > "$OUT_F"

	API_QUERY[out]=
	API_QUERY[log]=

	if test "$1" = "wget"; then
		_msg "wget ${API_QUERY[url]}/$2"
		wget -q -O "$OUT_F" "${API_QUERY[url]}/$2" >"$LOG_F" 2>"$ERR_F" || _abort "wget failed"
		test -s "$OUT_F" || _abort "no result"
	else
		_abort "$1 api query not implemented"
	fi

	test -s "$OUT_F" && API_QUERY[out]=`cat "$OUT_F"`
	test -s "$LOG_F" && API_QUERY[log]=`cat "$LOG_F"`
	test -z "$ERR_F" || _abort "non-empty error log"
}


#--
# Append file $2 to file $1 if first 3 lines from $2 are not in $1.
#
# @param target file
# @param source file
# @require _abort _msg
#--
function _append_file {
	local FOUND=
	test -f "$2" || _abort "no such file [$2]"
	test -s "$1" && FOUND=$(grep "`head -3 \"$2\"`" "$1")
	test -z "$FOUND" || { _msg "$2 was already appended to $1"; return; }

	_msg "append file '$2' to '$1'"
	cat "$2" >> "$1" || _abort "cat '$2' >> '$1'"
}


#--
# @deprecated use _append_file
# @param target file
# @param source file
# @require _append_file _msg
#--
function _append {
	_msg "DEPRECATED: use _append_file"
	_append_file "$1" "$2"
}


#--
# Append text $2 to file $1 if not found in $1.
#
# @param target file
# @param text
# @require _abort
#--
function _append_txt {
	local FOUND=
	test -f "$1" && FOUND=$(grep "$2" "$1")
	test -z "$FOUND" || { _msg "$2 was already appended to $1"; return; }

	_msg "append text '$2' to '$1'"
	echo "$2" >> "$1" || _abort "echo '$2' >> '$1'"
}


#--
# Clean apt installation.
#
# @require _abort _run_as_root
#--
function _apt_clean {
	_run_as_root
	apt -y clean || _abort "apt -y clean"
	apt -y autoclean || _abort "apt -y autoclean"
	apt -y install -f || _abort "apt -y install -f"
	apt -y autoremove || _abort "apt -y autoremove"
}


#--
# Install apt packages.
#
# @require _abort _run_as_root
#--
function _apt_install {
	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	_run_as_root 1

	test "$RKSCRIPT_DIR" = "$HOME/.rkscript/$$" && RKSCRIPT_DIR="$HOME/.rkscript"

	for a in $1
	do
		if test -d "$RKSCRIPT_DIR/apt/$a"; then
			echo "already installed, skip: apt -y install $a"
		else
			sudo apt -y install $a || _abort "apt -y install $a"
			_log "apt -y install $a" apt/$a
		fi
	done

	test "$RKSCRIPT_DIR" = "$HOME/.rkscript" && RKSCRIPT_DIR="$HOME/.rkscript/$$"

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}


#--
# Remove (purge) apt packages.
#
# @param package list
# @require _apt_clean _abort _run_as_root _confirm _rm
#--
function _apt_remove {
	_run_as_root

	for a in $1; do
		_confirm "Run apt -y remove --purge $a" 1
		if test "$CONFIRM" = "y"; then
			apt -y remove --purge $a || _abort "apt -y remove --purge $a"
			_rm "$RKSCRIPT_DIR/apt/$a"
		fi
	done

	_apt_clean
}


#--
# Install Amazon AWS PHP SDK
#
# @require _composer _composer_pkg 
#--
function _aws {
	_composer
	_composer_pkg aws/aws-sdk-php
}


test -z "$RKSCRIPT_CACHE" && RKSCRIPT_CACHE="$HOME/.rkscript/cache"

#--
# Load $1 from cache. If $2 is set update cache value first. Compare last 
# modification of cache file $RKSCRIPT_CACHE/$1 with sh/run and ../rkscript/src.
# Export CACHE_OFF=1 to disable cache. Disable cache if bash version is 4.3.*.
#
# @param variable name
# @param variable value
# @global RKSCRIPT_CACHE
# @require _mkdir
#--
function _cache {
	test -z "$CACHE_OFF" || return

	# bash 4.3.* does not support ${2@Q} expression
	local BASH43=`/bin/bash --version | grep 'ersion 4.3.'`
	test -z "$BASH43" || return

	# bash 3.* does not support ${2@Q} expression
	local BASH3X=`/bin/bash --version | grep 'ersion 3.'`
	test -z "$BASH3X" || return

	_mkdir "$RKSCRIPT_CACHE"

	local CACHE="$RKSCRIPT_CACHE/$1.sh"

	if ! test -z "$2"; then
		# update cache value - ${2@Q} = escaped value of $2
		echo "$1=${2@Q}" > "$CACHE"
		echo "update cached value of $1 ($CACHE)"
	fi

	if test -f "$CACHE" && test -d "sh/run" && test -d "../rkscript/src"; then
		# last modification unix ts local source
		local SH_LM=`stat -c %Y sh/run`
		# last modification unix ts include source
		local SRC_LM=`stat -c %Y ../rkscript/src`
		# last modification of cache
		local CACHE_LM=`stat -c %Y "$CACHE"`

		if test $SH_LM -lt $CACHE_LM && test $SRC_LM -lt $CACHE_LM; then
			. "$CACHE"
			echo "use cached value of $1 ($CACHE)"
		fi
	fi
}


#--
# Download source url to target path.
#
# @global DOCROOT if not empty and head.inc.html exists copy files here and append to 
# head.inc.html
#
# @global CDN_DIR path prefix (if empty use ./)
#
# @param string source url
# @param string target path
# @require _abort _mkdir _download
#--
function _cdn_dl {
	local SUFFIX=`echo "$2" | awk -F . '{print $NF}'`
	local TARGET="$2"

	if test -z "$CDN_DIR"; then
		TARGET="./$TARGET"
	else
		TARGET="$CDN_DIR/$TARGET"
	fi

	_mkdir `dirname "$TARGET"`
	_download "$1" "$TARGET"
	_download "$1.map" "$TARGET.map" 1

	if ! test -z "$DOCROOT"; then
		_cp "$TARGET" "$DOCROOT/$2"

		if test -f "$TARGET.map"; then
			_cp "$TARGET.map" "$DOCROOT/$2.map"
		fi

		if test -f "$DOCROOT/head.inc.html"; then
			local HAS_FILE=`grep "=\"$2\"" "$DOCROOT/head.inc.html"`

			if ! test -z "$HAS_FILE"; then
				echo "$2 is already in head.inc.html"
			elif test "$SUFFIX" = "css" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<link rel=\"stylesheet\" href=\"$2\" \/>/g" > "$DOCROOT/head.inc.html"
			elif test "$SUFFIX" = "js" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<script src=\"$2\"><\/script>/g" > "$DOCROOT/head.inc.html"
			fi
		fi
	fi
}


#--
# Change to directory $1. If parameter is empty and _cd was executed before 
# change to last directory.
#
# @param path
# @param do_not_echo
# @export LAST_DIR
# @require _abort 
#--
function _cd {
	local has_realpath=`which realpath`

	if ! test -z "$has_realpath" && ! test -z "$1"; then
		local curr_dir=`realpath "$PWD"`
		local goto_dir=`realpath "$1"`

		if test "$curr_dir" = "$goto_dir"; then
			return
		fi
	fi

	if test -z "$2"; then
		echo "cd '$1'"
	fi

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


#--
# Abort if domain is missing or /.../$2/fullchain.pem doesn not contain DNS:$1.
#
# @param string domain
# @param string domain_dir (/etc/letsencrypt/live/$domain_dir/fullchain.pem
# @require _abort
#--
function _cert_domain {
	local CERT_FILE="/etc/letsencrypt/live/$1/fullchain.pem"

	if ! test -z "$2"; then
		CERT_FILE="/etc/letsencrypt/live/$2/fullchain.pem"
	fi

	if ! test -f "$CERT_FILE"; then
		_abort "no such file $CERT_FILE"
	else   
		local HAS_DOMAIN=`openssl x509 -text -noout -in "$CERT_FILE" | grep "DNS:$1"`
         
		if test -z "$HAS_DOMAIN"; then
			_abort "missing domain $1 in $CERT_FILE"
		fi
 	fi
}



#--
# Abort if ip_address of domain does not point to IP_ADDRESS.
# Call _ip_address first.
#
# @global IP_ADDRESS
# @param domain
# @require _abort _require_program _is_ip4
#--
function _check_ip {
	_require_program ping

	local IP_OK=`ping -4 -c 1 "$1" 2> /dev/null | grep "$IP_ADDRESS"`
	if test -z "$IP_OK"; then
		_abort "$1 does not point to server ip $IP_ADDRESS"
	fi
}



#--
# Print ssl public key status of /etc/letsencrypt/live/$1/fullchain.pem.
# 
# @export ENDDATE
# @param string domain
# @print valid, missing or expired
#--
function _check_ssl {
	if ! test -f /etc/letsencrypt/live/$1/fullchain.pem; then
		echo "missing"
		return
	fi

	ENDDATE=`openssl x509 -enddate -noout -in /etc/letsencrypt/live/$1/fullchain.pem`
	export ENDDATE=${ENDDATE:9}
	local STATUS=$(php -r 'print strtotime(getenv("ENDDATE")) > time() + 3600 * 24 * 14 ? "valid" : "expired";')

	echo $STATUS
}


#--
# Change file+directory privileges recursive.
#
# @param path/to/entry
# @param file privileges (default = 644)
# @param dir privileges (default = 755)
# @param main dir privileges (default = dir privleges)
# @require _abort _file_priv _dir_priv
#--
function _chmod_df {
	local CHMOD_PATH="$1"
	local FPRIV=$2
	local DPRIV=$3
	local MDPRIV=$4

	if ! test -d "$CHMOD_PATH" && ! test -f "$CHMOD_PATH"; then
		_abort "no such directory or file: [$CHMOD_PATH]"
	fi

	test -z "$FPRIV" && FPRIV=644
	test -z "$DPRIV" && DPRIV=755

	_file_priv "$CHMOD_PATH" $FPRIV
	_dir_priv "$CHMOD_PATH" $DPRIV

	if ! test -z "$MDPRIV" && test "$MDPRIV" != $"$DPRIV"; then
		echo "chmod $MDPRIV '$CHMOD_PATH'"
		chmod "$MDPRIV" "$CHMOD_PATH" || _abort "chmod $MDPRIV '$CHMOD_PATH'"
	fi
}


#--
# Change mode of path $2 to $1. If chmod failed try sudo.
# Use _find first to chmod all FOUND entries.
#
# @param file mode (octal)
# @param file path (if path is empty use $FOUND)
# global CHMOD (default chmod -R)
# @require _abort _sudo
#--
function _chmod {
	test -z "$1" && _abort "empty privileges parameter"
	test -z "$2" && _abort "empty path"

	local tmp=`echo "$1" | sed -e 's/[012345678]*//'`
	test -z "$tmp" || _abort "invalid octal privileges '$1'"

	local CMD="chmod -R"
	if ! test -z "$CHMOD"; then
		CMD="$CHMOD"
		CHMOD=
	fi

	local a=; local i=; local PRIV=;

	if test -z "$2"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			PRIV=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				PRIV=`stat -c "%a" "${FOUND[$i]}"`
			fi

			if test "$1" != "$PRIV" && test "$1" != "0$PRIV"; then
				_sudo "$CMD $1 '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$2"; then
		PRIV=`stat -c "%a" "$2"`

		if test "$1" != "$PRIV" && test "$1" != "0$PRIV"; then
			_sudo "$CMD $1 '$2'" 1
		fi
	else
		# no stat compare because subdir entry may have changed
		_sudo "$CMD $1 '$2'" 1
	fi
}


#--
# Change owner and group of path
#
# @param path (if empty use $FOUND)
# @param owner
# @param group 
# @sudo
# @global CHOWN (default chown -R)
# @require _abort
#--
function _chown {
	if test -z "$2" || test -z "$3"; then
		_abort "owner [$2] or group [$3] is empty"
	fi

	local CMD="chown -R"
	if ! test -z "$CHOWN"; then
		CMD="$CHOWN"
		CHOWN=
	fi

	if test -z "$1"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			local CURR_OWNER=
			local CURR_GROUP=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				CURR_OWNER=$(stat -c '%U' "${FOUND[$i]}")
				CURR_GROUP=$(stat -c '%G' "${FOUND[$i]}")
			fi

			if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
				_sudo "$CMD '$2.$3' '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$1"; then
		local CURR_OWNER=$(stat -c '%U' "$1")
		local CURR_GROUP=$(stat -c '%G' "$1")

		if test -z "$CURR_OWNER" || test -z "$CURR_GROUP"; then
			_abort "stat owner [$CURR_OWNER] or group [$CURR_GROUP] of [$1] failed"
		fi

		if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
			_sudo "$CMD '$2.$3' '$1'" 1
		fi
	else
		# no stat compare because subdir entry may have changed
		_sudo "$CMD $2.$3 '$1'" 1
	fi
}


#--
# Execute command $1.
#
# @param command
# @param 2^n flag (2^0= no echo, 2^1= print output)
# @require _abort _log
#--
function _cmd {

	# @ToDo unescape $1 to avoid eval
	local EXEC="$1"

	# change $2 into number
	local FLAG=$(($2 + 0))

	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	test $((FLAG & 1)) = 1 && LOG_NO_ECHO=1

	_log "$EXEC" cmd
	eval "$EXEC ${LOG_CMD[cmd]}" || _abort "command failed"
	
	if test $((FLAG & 2)) = 2; then
		tail -n +5 "${LOG_FILE[cmd]}"
	else
		echo "ok"
	fi

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}


#--
# Create composer.json
#
# @param package name e.g. rklib/test
# @require _abort _rm _confirm _license
#--
function _composer_json {
	if test -z "$1"; then
		_abort "empty project name use e.g. rklib/NAME"
	fi

	if test -f "composer.json"; then
		_confirm "Overwrite existing composer.json"
		if test "$CONFIRM" = "y"; then
			_rm "composer.json"
		else
			return
    fi
	fi

	_license "gpl-3.0"

	local CLASSMAP=
	if test -d "src"; then
		CLASSMAP='"src/"'
	fi

	echo "create composer.json ($1, $LICENSE)"
	1>"composer.json" cat <<EOL
{
	"name": "$1",
	"type": "",
	"description": "",
	"authors": [
		{ "name": "Roland Kujundzic", "email": "roland@kujundzic.de" }
	],
	"minimum-stability" : "dev",
	"prefer-stable" : true,
	"require": {
		"php": ">=7.2.0",
		"ext-mbstring": "*"
	},
	"autoload": {
		"classmap": [$CLASSMAP],
		"files": []
	},
	"license": "GPL-3.0-or-later"
}
EOL
}


#--
# Install composer.phar in current directory
#
# @param install_as (default = './composer.phar')
# @require _abort _rm _wget
#--
function _composer_phar {
  local EXPECTED_SIGNATURE="$(_wget "https://composer.github.io/installer.sig" -)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  local ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    _rm composer-setup.php
    _abort 'Invalid installer signature'
  fi

	local INSTALL_AS="$1"
	local SUDO=sudo

	if test -z "$INSTALL_AS"; then
		INSTALL_AS="./composer.phar"
		SUDO=
	fi

  $SUDO php composer-setup.php --quiet --install-dir=`dirname "$INSTALL_AS"` --filename=`basename "$INSTALL_AS"`
  local RESULT=$?

	if ! test "$RESULT" = "0" || ! test -s "$INSTALL_AS"; then
		_abort "composer installation failed"
	fi

	_rm composer-setup.php
}


#--
# Install php package with composer. Target directory is vendor/$1
#
# @param composer-vendor-directory
# @require _abort
#--
function _composer_pkg {
	if ! test -f composer.phar; then
		_abort "Install composer first"
	fi

	if test -d "vendor/$1" && test -f composer.json && ! test -z `grep "$1" composer.json`; then
		echo "Update composer package $1 in vendor/" 
		php composer.phar update $1
	else
		echo "Install composer package $1 in vendor/" 
		php composer.phar require $1
	fi
}


#--
# Install composer (getcomposer.org). If no parameter is given ask for action
# or execute default action (install composer if missing otherwise update) after
# 10 sec. 
#
# @param [install|update|remove] (empty = default = update or install)
# @require _composer_phar _abort _rm
#--
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
			echo "[g] = global composer installation: /usr/local/bin/composer"
			echo "[l] = local composer installation: composer.phar"
		else
			if test -f composer.json; then
				DO=i
				if test -d vendor; then
					DO=u
				fi

				echo "[i] = install packages from composer.json"
				echo "[u] = update packages from composer.json"
				echo "[a] = update vendor/composer/autoload*"
			fi

			if ! test -z "$LOCAL_COMPOSER"; then
				echo "[r] = remove local composer.phar"
			fi
		fi

 		echo -e "[q] = quit\n\n"
		echo -n "Type ENTER or wait 10 sec to select default. Your Choice? [$DO]  "
		read -n1 -t 10 USER_DO
		echo

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
		echo -n "install composer as "
		if test "$DO" = "g"; then
			echo "/usr/local/bin/composer - Enter root password if asked"
			_composer_phar /usr/local/bin/composer
		else
			echo "composer.phar"
			_composer_phar
		fi
	fi

	local COMPOSER=
	if ! test -z "$LOCAL_COMPOSER"; then
		COMPOSER="php composer.phar"
	elif ! test -z "$GLOBAL_COMPOSER"; then
		COMPOSER="composer"
	fi

	if test -f composer.json; then
		if test "$DO" = "install" || test "$DO" = "i"; then
			$COMPOSER install
		elif test "$DO" = "update" || test "$DO" = "u"; then
			$COMPOSER update
		elif test "$DO" = "a"; then
			$COMPOSER dump-autoload -o
		fi
	fi
}


#--
# Show "message  Press y or n  " and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 sec expired. Use --q1=y and --q2=n call parameter to confirm
# question 1 and reject question 2. Set CONFIRM_COUNT= before _confirm if necessary.
# If AUTOCONFIRM is set do: echo $1 [$AUTOCONFIRM] && CONFIRM=$AUTOCONFIRM && return.
#
# @param string message
# @param 2^N flag 1=switch y and n (y = default, wait 3 sec) | 2=auto-confirm (y)
# @global AUTOCONFIRM --qN
# @export CONFIRM CONFIRM_TEXT
#--
function _confirm {
	CONFIRM=

	if ! test -z "$AUTOCONFIRM"; then
		CONFIRM="$AUTOCONFIRM"
		echo "$1 <$AUTOCONFIRM>"
		AUTOCONFIRM=
		return
	fi

	if test -z "$CONFIRM_COUNT"; then
		CONFIRM_COUNT=1
	else
		CONFIRM_COUNT=$((CONFIRM_COUNT + 1))
	fi

	local FLAG=$(($2 + 0))

	if test $((FLAG & 2)) = 2; then
		if test $((FLAG & 1)) = 1; then
			CONFIRM=n
		else
			CONFIRM=y
		fi

		return
	fi

	while read -d $'\0' 
	do
		local CCKEY="--q$CONFIRM_COUNT"
		if test "$REPLY" = "$CCKEY=y"; then
			echo "found $CCKEY=y, accept: $1" 
			CONFIRM=y
		elif test "$REPLY" = "$CCKEY=n"; then
			echo "found $CCKEY=n, reject: $1" 
			CONFIRM=n
		fi
	done < /proc/$$/cmdline

	if ! test -z "$CONFIRM"; then
		# found -y or -n parameter
		CONFIRM_TEXT="$CONFIRM"
		return
	fi

	local DEFAULT=

	if test $((FLAG & 1)) -ne 1; then
		DEFAULT=n
		echo -n "$1  y [n]  "
		read -n1 -t 10 CONFIRM
		echo
	else
		DEFAULT=y
		echo -n "$1  [y] n  "
		read -n1 -t 3 CONFIRM
		echo
	fi

	if test -z "$CONFIRM"; then
		CONFIRM=$DEFAULT
	fi

	CONFIRM_TEXT="$CONFIRM"

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}


#--
# Add android platform to cordova. If platforms/android exists do nothing.
# Apply patches from www_src/patch if found.
#
# @param optional action e.g. clean
# @require _rm _patch
#--
function _cordova_add_android {

	if test "$1" = "clean" && test -d platforms/android; then
		_rm platforms/android
	fi

	if ! test -d platforms/android; then
		echo "cordova platform add android"
		cordova platform add android
		_patch www_src/patch/android
	fi
}


#--
# Add ios platform to cordova. If platforms/ios exists do nothing.
# Apply patches from www_src/patch if found.
#
# @param optional action e.g. clean
# @require _rm _os_type _patch
#--
function _cordova_add_ios {
	local OS_TYPE=$(_os_type)

	if test "$OS_TYPE" != "macos"; then
		echo "os type = $OS_TYPE != macos - do not add cordova ios" 
		return
	fi

	if test "$1" = "clean" && test -d platforms/ios; then
		_rm platforms/ios
	fi

	if ! test -d platforms/ios; then
		echo "cordova platform add ios"
		cordova platform add ios
		_patch www_src/patch/ios
	fi
}


#--
# Create corodva project in app/ directory.
# 
# @param app name
# @require _abort _os_type _cordova_add_android _cordova_add_ios _mkdir
#--
function _cordova_create {
	if test -d "app/$1"; then
		_abort "Cordova project app/$1 already exists"
	fi

	test -d app || _mkdir app

	cd app
	cordova create $1
	cd $1

	local OS_TYPE=$(_os_type)

	if "$OS_TYPE" = "linux"; then
		_cordova_add_android
		test -d www_src/patch/android || _mkdir www_src/patch/android
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/android/patch.sh
	elif "$OS_TYPE" = "macos"; then
		_cordova_add_ios
		test -d www_src/patch/ios || _mkdir www_src/patch/ios
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/ios/patch.sh
	fi

	cd ../..
}


#--
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @global SUDO
# @require _abort _md5 _sudo
#--
function _cp {
	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	local TARGET_DIR=`dirname "$2"`
	test -d "$TARGET_DIR" || _abort "no such directory [$TARGET_DIR]"

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
		local MD1=`_md5 "$1"`
		local MD2=`_md5 "$2"`

		if test "$MD1" = "$MD2"; then
			echo "_cp: keep $2 (same as $1)"
		else
			echo "Copy file $1 to $2 (update)"
			_sudo "cp '$1' '$2'" 1
		fi

		return
	fi

	if test -f "$1"; then
		echo "Copy file $1 to $2"
		_sudo "cp '$1' '$2'" 1
	elif test -d "$1"; then
		if test -d "$2"; then
			local PDIR=`dirname $2`"/"
			echo "Copy directory $1 to $PDIR"
			_sudo "cp -r '$1' '$PDIR'" 1
		else
			echo "Copy directory $1 to $2"
			_sudo "cp -r '$1' '$2'" 1
		fi
	else
		_abort "No such file or directory [$1]"
	fi

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}


#--
# Create tgz archive $1 with files from file/directory list $2.
#
# @param tgz_file
# @param directory/file list
# @require _abort
#--
function _create_tgz {
	local a=; for a in $2
	do
		if ! test -f $a && ! test -d $a
		then
			_abort "No such file or directory $a"
		fi
	done

	if test -z "$1"; then
		_abort "Empty archive path"
	fi

  echo "create archive $1"
  SECONDS=0
  tar -czf $1 $2 || _abort "tar -czf $1 $2 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 
}

	
#--
# Install user ($1) crontab ($2 $3).
#
# @param string user
# @param string repeat-time
# @param string command
# @require _abort
#--
function _crontab {
	local CRONTAB_DIR="/var/spool/cron/crontabs"
	log "install $1 crontab: $2 $3"
	_mkdir "$CRONTAB_DIR" >/dev/null

	grep "$3" "$CRONTAB_DIR/$1" && { echo "already installed - skip"; return; }
	echo "$2 $3" >>"$CRONTAB_DIR/$1" || _abort "failed to create $1 cron"
}


#--
# Change directory privileges (recursive).
#
# @param directory
# @param privileges (default 755)
# @param options (default "! -path '/.*/'")
# @require _abort _require_program
#--
function _dir_priv {
	_require_program realpath

	local DIR=`realpath "$1"`
	test -d "$DIR" || _abort "no such directory [$DIR]"

	local PRIV="$2"
	if test -z "$PRIV"; then
		PRIV=755
	else
		_is_integer "$PRIV"
	fi

	local MSG="chmod $PRIV directories in $1/"

	if test -z "$3"; then
    FIND_OPT="! -path '/.*/'"
    MSG="$MSG ($FIND_OPT)"
	else
    FIND_OPT="$3"
    MSG="$MSG ($FIND_OPT)"	
  fi

	echo "$MSG"
	find "$1" $FIND_OPT -type d -exec chmod $PRIV {} \; || _abort "find '$1' $FIND_OPT -type d -exec chmod $PRIV {} \;"
}


#--
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
# @require _abort _mv _mkdir _wget
#--
function _dl_unpack {

	if test -d "$1"; then
		echo "Use existing unpacked directory $1"
		return
	fi

	local ARCHIVE=`basename $2`

	if ! test -f "$ARCHIVE"; then
		echo "Download $2"
		_wget "$2"
	fi

	if ! test -f "$ARCHIVE"; then
		_abort "No such archive $ARCHIVE - download of $2 failed"
	fi

	local EXTENSION="${ARCHIVE##*.}"
	local UNPACK_CMD=

	if test "$EXTENSION" = "zip"; then
		UNPACK_CMD="unzip"
		echo "Unpack zip: $UNPACK_CMD '$ARCHIVE'"

		local HAS_DIR=`unzip -l "$ARCHIVE" | grep "$1\$"`

		if test -z "$HAS_DIR"; then
			_mkdir "$1"
			cd "$1"
			unzip "../$ARCHIVE"
			cd ..
		else
			unzip "$ARCHIVE"
		fi
	else
		UNPACK_CMD="tar -xf"
		echo "Unpack tar: $UNPACK_CMD '$ARCHIVE'"
		tar -xf "$ARCHIVE"
	fi

	if ! test -d "$1"; then
		local BASE="${ARCHIVE%.*}"

		if test -d $BASE; then
			_mv "$BASE" "$1"
		else
			_abort "$UNPACK_CMD $ARCHIVE failed"
		fi
  fi
}

#--
# Remove stopped docker container (if found).
#
# @param name
# @require _docker_stop
#--
function _docker_rm {
	_docker_stop "$1"

	local HAS_CONTAINER=`docker ps -a | grep "$1"`

	if ! test -z "$HAS_CONTAINER"; then
		echo "docker rm $1"
		docker rm "$1"
	fi
}


#--
# Remove stopped docker container $1 (if found). Start docker container $1.
#
# @param name
# @param config file
# @require _abort _cd _docker_stop _docker_rm
#--
function _docker_run {
	_docker_rm $1

	if ! test -z "$WORKSPACE" && ! test -z "$CURR" && test -d "$WORKSPACE/linux/rkdocker"; then
		_cd "$WORKSPACE/linux/rkdocker"
	else
		_abort "Export WORKSPACE (where $WORKSPACE/linux/rkdocker exists) and CURR=path/current/directory"
	fi

	local CONFIG=

	if test -f "$CURR/$2"; then
		CONFIG="$CURR/$2"
	elif test -f "$2"; then
		CONFIG="$2"
	else
		_abort "No such configuration $CURR/$2 ($PWD/$2)"
	fi
	
  echo "DOCKER_NAME=$1 ./run.sh $CONFIG start"
  DOCKER_NAME=$1 ./run.sh $2 start

	cd $CURR
}


#--
# Stop running docker container (if found).
#
# @param name
#--
function _docker_stop {
	local HAS_CONTAINER=`docker ps | grep "$1"`

	if ! test -z "$HAS_CONTAINER"; then
		echo "docker stop $1"
		docker stop "$1"
	fi
}


#--
# Download for url to local file.
#
# @param string url
# @param string file
# @param bool allow_fail
# @require _abort _mkdir _wget
#--
function _download {
	if test -z "$2"; then
		_abort "Download target path is empty"
	fi

	if test -z "$1"; then
		_abort "Download url is empty"
	fi

	local PDIR=`dirname "$2"`
	_mkdir "$PDIR"
	
	if test -z "$3"; then
		echo "Download $1 as $2"
	fi

	_wget "$1" "$2"

	if test -z "$3" && ! test -s "$2"; then
		_abort "Download of $2 as $1 failed"
	fi

	if ! test -z "$3"; then
		if test -s "$2"; then
			echo "Download $1 as $2"
		elif test -f "$2"; then
			rm "$2"
		fi
	fi
}

#--
# Extract tgz archive $1. If second parameter is existing directory, remove
# before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# @require _abort _rm
#--
function _extract_tgz {

	if ! test -f "$1"; then
		_abort "Invalid archive path [$1]"
	fi

	if ! test -z "$2" && test -d $2; then
		_rm "$2"
	fi

  echo "extract archive $1"
  SECONDS=0
  tar -xzf $1 || _abort "tar -xzf $1 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 

	if ! test -z "$2"; then
		if ! test -d "$2" && ! test -f "$2"; then
			_abort "Path $2 was not created"
		fi
	fi
}


#--
# Change file privileges for directory (recursiv). 
#
# @param directory
# @param privileges (default 644)
# @param options (default "! -path '.*/' ! -path 'bin/*' ! -name '.*' ! -name '*.sh'")
# @require _abort _require_program
#--
function _file_priv {
	_require_program realpath

	local DIR=`realpath "$1"`
	test -d "$DIR" || _abort "no such directory [$DIR]"

	local PRIV="$2"
	if test -z "$PRIV"; then
		PRIV=644
	else
		_is_integer "$PRIV"
	fi

	local MSG="chmod $PRIV files in $1/"

	if test -z "$3"; then
		FIND_OPT="! -path '/.*/' ! -path '/bin/*' ! -name '.*' ! -name '*.sh'"
		MSG="$MSG ($FIND_OPT)"
	else
		FIND_OPT="$3"
		MSG="$MSG ($FIND_OPT)"
	fi

	echo "$MSG"
	find "$1" $FIND_OPT -type f -exec chmod $PRIV {} \; || _abort "find '$1' $FIND_OPT -type f -exec chmod $PRIV {} \;"
}


#--
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD (optional use $PWD as default)
# @export DOCROOT
# @require _abort  
#--
function _find_docroot {
	local DIR=
	local LAST_DIR=

	if ! test -z "$DOCROOT"; then
		DOCROOT=`realpath $DOCROOT`
		echo "use existing DOCROOT=$DOCROOT"
		return
	fi

	if test -z "$1"; then
		DIR=$(realpath "$PWD")
	else
		DIR=$(realpath "$1")
	fi

	local BASE=`basename $DIR`
	if test "$BASE"="cms"; then
		DOCROOT=`dirname $DIR`
	fi

	if ! test -z "$DOCROOT" && test -f "$DOCROOT/index.php" && (test -f "$DOCROOT/settings.php" || test -d "$DOCROOT/data"); then
		echo "use DOCROOT=$DOCROOT"
		return
	fi

	while test -d "$DIR" && ! (test -f "$DIR/index.php" && (test -f "$DIR/settings.php" || test -d "$DIR/data")); do
		LAST_DIR="$DIR"
		DIR=$(dirname "$DIR")

		if test "$DIR" = "$LAST_DIR" || ! test -d "$DIR"; then
			_abort "failed to find DOCROOT of [$1]"
		fi
	done

	if test -f "$DIR/index.php" && (test -f "$DIR/settings.php" || test -d "$DIR/data"); then
		DOCROOT="$DIR"
	else
		_abort "failed to find DOCROOT of [$1]"
	fi
}


#--
# Save found filesystem entries into FOUND.
#
# @param any paramter useable with find command
# @export FOUND Path Array
# @required _require_program
#--
function _find {
	FOUND=()
	local a=

	_require_program find

	while read a; do
		FOUND+=("$a")
	done <<< `find $@ 2>/dev/null`
}


#--
# Return saved value ($RKSCRIPT_DIR/$APP/name.nfo).
#
# @param string name
#--
function _get {
	local DIR="$RKSCRIPT_DIR/"`basename "$APP"`

	test -f "$DIR/$1.nfo" || _abort "no such file $DIR/$1.nfo"

	cat "$DIR/$1.nfo"
}


#--
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
# For git parameter (e.g. [-b master --single-branch]) use global variable GIT_PARAMETER.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo test
#
# @param git url
# @param local directory (optional, default = basename $1 without .git)
# @param after_checkout (e.g. "./run.sh build")
# @global CONFIRM_CHECKOUT (if =1 use positive confirm if does not exist) GIT_PARAMETER
# @require _abort _confirm _cd _ln
#--
function _git_checkout {
	local CURR="$PWD"
	local GIT_DIR="${2:-`basename "$1" | sed -E 's/\.git$//'`}"

	if test -d "$GIT_DIR"; then
		_confirm "Update $GIT_DIR (git pull)?" 1
	elif ! test -z "$CONFIRM_CHECKOUT"; then
		_confirm "Checkout $1 to $GIT_DIR (git clone)?" 1
	fi

	if test "$CONFIRM" = "n"; then
		echo "Skip $1"
		return
	fi

	if test -d "$GIT_DIR"; then
		_cd "$GIT_DIR"
		echo "git pull $GIT_DIR"
		git pull
		test -s .gitmodules && git submodule update --init --recursive --remote
		test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
		_cd "$CURR"
	elif test -d "../../$GIT_DIR/.git" && ! test -L "../../$GIT_DIR"; then
		_ln "../../$GIT_DIR" "$GIT_DIR"
		_git_checkout "$1" "$GIT_DIR"
	else
		echo -e "git clone $GIT_PARAMETER '$1' '$GIT_DIR'\nEnter password if necessary"
		git clone $GIT_PARAMETER "$1" "$GIT_DIR"

		if ! test -d "$GIT_DIR/.git"; then
			_abort "git clone failed - no $GIT_DIR/.git directory"
		fi

		if test -s "$GIT_DIR/.gitmodules"; then
			_cd "$GIT_DIR"
			test -s .gitmodules && git submodule update --init --recursive --remote
			test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
			_cd ..
		fi

		if ! test -z "$3"; then
			_cd "$GIT_DIR"
			echo "run [$3] in $GIT_DIR"
			$3
			_cd ..
		fi
	fi

	GIT_PARAMETER=
}


declare -A GITHUB_LATEST
declare -A GITHUB_IS_LATEST

#--
# Export GITHUB_[IS_]LATEST[$2].
#
# @export $GITHUB_LATEST[$1] = NN.NN and GITHUB_IS_LATEST[$1]=1|''
# @param $1 user/project (latest github url = https://github.com/[user/project]/releases/latest)
# @param $2 app
#--
function _github_latest {
	local VNUM=`$2 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/'`
	local REDIR=`curl -Ls -o /dev/null -w %{url_effective} "https://github.com/$1/releases/latest"`
	local LATEST=`basename "$REDIR" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+)\.?([0-9]*).*/\1\2/'`

	if ! test -z "$LATEST"; then
		GITHUB_LATEST[$2]=`basename "$REDIR"`
		GITHUB_IS_LATEST[$2]=''

		if ! test -z "$VNUM" && test `echo "$VNUM >= $LATEST" | bc -l` == 1; then
			GITHUB_IS_LATEST[$2]=1
		fi
	fi
}


#--
# Update git components.
#
# @require _git_checkout _mkdir
#--
function _git_update {
	_mkdir php
	cd php
	_git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	_git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib
	cd ..
}


#--
# Gunzip file.
#
# @param file
# @param ignore_if_not_gzip (optional)
# @require _abort
#--
function _gunzip {

	if ! test -f "$1"; then
		_abort "no such gzip file [$1]"
	fi

	local REAL_FILE=`realpath "$1"`
	local IS_GZIP=`file "$REAL_FILE"  | grep 'gzip compressed data'`

	if test -z "$IS_GZIP"; then
		if test -z "$2"; then
			_abort "invalid gzip file [$1]"
		else 
			echo "$1 is not in gzip format - skip gunzip"
			return
		fi
	fi

	local TARGET=`echo "$1" | sed -e 's/\.gz$//'`

	if test -L "$1"; then
		echo "gunzip -c '$1' > '$TARGET'"
		gunzip -c "$1" > "$TARGET"
	else
		echo "gunzip $1"
		gunzip "$1"
	fi

	if ! test -f "$TARGET"; then
		_abort "gunzip failed - no such file $TARGET"
	fi
}


declare -A PROCESS

#--
# Export PROCESS[pid|start|command]. Second parameter is 2^n flag:
#
#  - 2^0 = $1 is bash script (search for /[b]in/bash.+$1.sh)
#  - 2^1 = logfile PROCESS[log] must exists
#  - 2^2 = abort if process does not exists
#  - 2^3 = abort if process exists 
#  - 2^4 = logfile has PID=PROCESS_ID in first three lines or contains only pid
#
# If flag containts 2^1 search for logged process id.
#
# @param command (e.g. "convert", "rx:node https.js", "bash:/tmp/test.sh")
# @param flag optional 2^n value
# @option PROCESS[log]=$1.log if empty and (flag & 2^1 = 2) or (flag & 2^4 = 16)
# @export PROCESS[pid|start|command] 
# @require _abort
#--
function _has_process {
	local flag=$(($2 + 0))
	local logfile_pid=
	local process=
	local rx=

	case $1 in
		bash:*)
			rx="/[b]in/bash.+${1#*:}";;
		rx:*)
			rx="${1#*:}";;
		*)
			rx=" +[0-9\:]+ +[0-9\:]+ +.+[b]in.*/$1"
	esac

	if test $((flag & 1)) = 1; then
		rx="/[b]in/bash.+$1.sh"
	fi

	if test -z "${PROCESS[log]}" && (test $((flag & 2)) = 2 || test $((flag & 16)) = 16); then
		PROCESS[log]="$1.log"
	fi

	if test $((flag & 2)) = 2 && ! test -f "${PROCESS[log]}"; then
		_abort "no such logfile ${PROCESS[log]}"
	fi

	if test $((flag & 16)) = 16; then
		if test -s "${PROCESS[log]}" || test $((flag & 2)) = 2; then
			logfile_pid=`head -3 "${PROCESS[log]}" | grep "PID=" | sed -e "s/PID=//" | grep -E '^[1-9][0-9]{0,4}$'`

			if test -z "$logfile_pid"; then
				logfile_pid=`cat "${PROCESS[log]}" | grep -E '^[1-9][0-9]{0,4}$'`
			fi

			if test -z "$logfile_pid"; then
				_abort "missing PID of [$1] in logfile ${PROCESS[log]}"
			fi
		else
			logfile_pid=-1
		fi
	fi
		
	if test -z "$logfile_pid"; then
		process=`ps -aux | grep -E "$rx"`
	else
		process=`ps -aux | grep -E "$rx" | grep " $logfile_pid "`		
	fi

	if test $((flag & 4)) = 4 && test -z "$process"; then
		_abort "no $1 process (rx=$rx, old_pid=$logfile_pid)"
	elif test $((flag & 8)) = 8 && ! test -z "$process"; then
		_abort "process $1 is already running (rx=$rx, old_pid=$logfile_pid)"
	fi
	
	PROCESS[pid]=`echo "$process" | awk '{print $2}'`
	PROCESS[start]=`echo "$process" | awk '{print $9, $10}'`
	PROCESS[command]=`echo "$process" | awk '{print $11, $12, $13, $14, $15, $16, $17, $18, $19, $20}'`

	# reset option
	PROCESS[log]=
}


#--
# Create .htaccess file in directory $1 if missing. Options $2:
#
# - deny
# - auth
#
# @param path to directory
# @param option (e.g. deny, auth)
# @require _mkdir _abort
#--
function _htaccess {
	if test "$2" = "deny"; then
		if ! test -f "$1/.htaccess"; then
			_mkdir "$1"
			echo "Require all denied" > "$1/.htaccess"
		else
			local has_deny=`cat "$1/.htaccess" | grep 'Require all denied'`
			if test -z "$has_deny"; then
				echo "Require all denied" > "$1/.htaccess"
			fi
		fi
	elif test "$2" = "auth"; then
		_abort "ToDo ..."
	fi
}

#--
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir 
# @param string app url (optional)
# @global APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
# @require _abort _mkdir _cp _dl_unpack _rm _require_global
#--
function _install_app {

	if test -z "$1"; then
		_abort "use _install_app . $2"
	fi

	if ! test -z "$2"; then 
		#_require_global "APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC"
		_dl_unpack $1 $2
	fi

  if ! test -d $APP_PREFIX; then
    _mkdir $APP_PREFIX
 	fi

	local DIR=; for DIR in $APP_DIR_LIST
  do
    _mkdir `dirname $APP_PREFIX/$DIR`
    _cp $1/$DIR $APP_PREFIX/$DIR
  done

	local FILE=; for FILE in $APP_FILE_LIST
  do
    _mkdir `dirname $APP_PREFIX/$FILE`
		_cp $1/$FILE $APP_PREFIX/$FILE md5
  done

	local ENTRY=; for ENTRY in $APP_SYNC
	do
		$SUDO rsync -av $1/$ENTRY $APP_PREFIX/
	done

	_rm $1
}


#--
# Install NODE_VERSION from latest binary package.
#
# @global NODE_VERSION 
# @require _abort _os_type _require_global _install_app
#--
function _install_node {

	if test -z "$NODE_VERSION"; then
		NODE_VERSION=v12.14.0
	fi

	_require_global "NODE_VERSION"

	local OS_TYPE=$(_os_type)

	if test -d /usr/local/bin && test "$OS_TYPE" = "linux"
	then
		APP_SYNC="bin include lib share"
		APP_PREFIX="/usr/local"

		local CURR_SUDO=$SUDO
		SUDO=sudo

		echo "Update node from $CURR_NODE_VERSION to $NODE_VERSION"
		_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"

		SUDO=$CURR_SUDO
	else
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi
}


#--
# Export ip address as IP_ADDRESS (ip4) and IP6_ADDRESS (ip6) (and DYNAMIC_IP).
#
# @export IP_ADDRESS IP6_ADDRESS DYNAMIC_IP
# @require _abort _require_program
#--
function _ip_address {
	_require_program ip

	IP_ADDRESS=`ip route get 1 | grep -E ' src [0-9\.]+ uid ' | sed -e 's/.* src //' | sed -e 's/ uid.*//'`
	if test -z "$IP_ADDRESS"; then
		IP_ADDRESS=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
	fi

	IP6_ADDRESS=`ip -6 addr | grep 'scope global' | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d'`
	local ip6_dyn=`ip -6 addr | grep 'scope global temporary dynamic' | awk '{print $2}' | sed -e 's/\/[0-9]*$//'`
	if ! test -z "$ip6_dyn"; then
		IP6_ADDRESS="$ip6_dyn"
		DYNAMIC_IP=1
	fi

	_require_program ping
	local host=`hostname`
	local ping_ok=`ping -4 -c 1 "$host" 2>/dev/null | grep "$IP_ADDRESS"`

	if test -z "$ping_ok"; then
		ping_ok=`ping -4 -c 1 "$host" 2>/dev/null | grep "127.0."`

		if test -z "$ping_ok"; then
			_abort "failed to detect IP_ADDRESS (ping -4 -c 1 $host != $IP_ADDRESS)"
		fi
	fi
}


#--
# Print module name if $module is git module.
#
# @param module name
#--
function _is_gitmodule {

	if test -z "$1" || ! test -s ".gitmodule"; then
		return
	fi

	cat .gitmodules | grep -E "\[submodule \".*$1\"\]" | sed -E "s/\[submodule \"(.*$1)\"\]/\1/"
}


#--
# Abort if parameter is not integer
#
# @param number
# @require _abort
#--
function _is_integer {
	local re='^[0-9]+$'

	if ! [[ $1 =~ $re ]] ; then
		_abort "[$1] is not integer"
	fi
}


#--
# Check if ip_address is ip4. IP can be empty if flag & 1.
#
# @param ip_address
# @param flag
# @require _abort 
#--
function _is_ip4 {
	local FLAG=$(($2 + 0))
	if test -z "$1" && test $((FLAG & 1)) = 1; then
		return;
	fi

	local is_ip4=`echo "$1" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'`

	if test -z "$is_ip4"; then
		_abort "Invalid ip4 address [$1] use e.g. 32.123.7.38"
	fi
}


#--
# Check if ip_address is ip6. IP can be empty if flag & 1.
#
# @param ip_address
# @param flag
# @require _abort 
#--
function _is_ip6 {
	local FLAG=$(($2 + 0))
	if test -z "$1" && test $((FLAG & 1)) = 1; then
		return;
	fi

	local is_ip6=`echo "$3" | \
		grep -E '^[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}$'`

	if test -z "$is_ip6"; then
		_abort "Invalid ip6 [$1] use e.g. 2001:4dd1:4fa3:0:95b2:572a:1d5e:4df5"
	fi
}


#--
# Abort with error message. Process Expression is either CUSTOM with 
# regular expression as second parameter (first character must be in brackets)
# or PORT with port number as second parameter or expression name from list:
#
# NGINX, APACHE2, DOCKER_PORT_80, DOCKER_PORT_443 
#
# Example:
#
# if test "$(_is_running APACHE2)" = "APACHE2_running"; then
# if test "$(_is_running PORT 80)" != "PORT_running"; then
# if test "$(_is_running CUSTOM [a]pache2)" = "CUSTOM_running"; then
#
# @param Process Expression Name 
# @param Regular Expression if first parameter is CUSTOM e.g. [a]pache2
# @require _abort _os_type
# @os linux
# @return bool
#--
function _is_running {
	_os_type linux

	test -z "$1" && _abort "no process name"

	# use [a] = a to ignore "grep process"
	local APACHE2='[a]pache2.*k start'
	local DOCKER_PORT_80='[d]ocker-proxy.* -host-port 80'
	local DOCKER_PORT_443='[d]ocker-proxy.* -host-port 443'
	local NGINX='[n]ginx.*master process'
	local IS_RUNNING=

	if ! test -z "$2"; then
		if test "$1" = "CUSTOM"; then
			IS_RUNNING=$(ps aux 2>/dev/null | grep -E "$2")
		elif test "$1" = "PORT"; then
			IS_RUNNING=$(netstat -tulpn 2>/dev/null | grep -E ":$2 .+:* .+LISTEN.*")
		fi
	elif test -z "${!1}"; then
		_abort "invalid grep expression name $1 (use NGINX, APACHE2, DOCKER_PORT80, ... or CUSTOM '[n]ame')"
	else
		IS_RUNNING=$(ps aux 2>/dev/null | grep -E "${!1}")
	fi

	local RES=1  # not running
	test -z "$IS_RUNNING" || RES=0

	return $RES
}


#--
# Join parameter with first parameter as delimiter.
# @echo 
#--
function _join {
  local IFS="$1"
  echo "${*:2}" # same as: shift; echo "$*";
}


#--
# If pid is file:path/to/process.pid try [head -3 path/to/process.pid | grep PID=] first
# otherwise assume file contains only pid. If pid is rx:REGULAR_EXPRESSION try
# [ps aux | grep -e "REGULAR_EXPRESSION"].
#
# @param pid [pid|file|rx]:...
# @param abort if process does not exist (optional)
# @require _abort
#--
function _kill_process {
	local MY_PID=

	case $1 in
		file:*)
			local PID_FILE="${1#*:}"

			if ! test -s "$PID_FILE"; then
				_abort "no such pid file $PID_FILE"
			fi

			MY_PID=`head -3 "$PID_FILE" | grep "PID=" | sed -e "s/PID=//"`
			if test -z "$MY_PID"; then
				MY_PID=`cat "$PID_FILE" | grep -E '^[1-9][0-9]{0,4}$'`
			fi
			;;
		pid:*)
			MY_PID="${1#*:}"
			;;
		rx:*)
			MY_PID=`ps aux | grep -E "${1#*:}" | awk '{print $2}'`
			;;
	esac

	if test -z "$MY_PID"; then
		_abort "no pid found ($1)"
	fi

	local FOUND_PID=`ps aux | awk '{print $2}' | grep -E '^[1-9][0-9]{0,4}$' | grep "$MY_PID"`
	if test -z "$FOUND_PID"; then
		if ! test -z "$2"; then
			_abort "no such pid $MY_PID"
		fi

		echo "no such pid $MY_PID"
	else
		echo "kill $MY_PID"
		kill "$MY_PID" || _abort "kill '$MY_PID'"
	fi
}


#--
# Print label.
#
# @param label
#--
function _label {
	echo "$1"
	echo "-------------------------------------------------------------------------------"
}


#--
# Create LICENCSE file for "gpl-3.0" (keep existing).
#
# @see https://help.github.com/en/articles/licensing-a-repository 
# @param license name (default "gpl-3.0")
# @export LICENSE
# @require _abort _wget _confirm
#--
function _license {
	if ! test -z "$1" && test "$1" != "gpl-3.0"; then
		_abort "unknown license [$1] use [gpl-3.0]"
	fi

	LICENSE=$1
	if test -z "$LICENSE"; then
		LICENSE="gpl-3.0"
	fi

	local LFILE="./LICENSE"

	if test -s "$LFILE"; then
		local IS_GPL3=`head -n 2 "$LFILE" | tr '\n' ' ' | sed -E 's/\s+/ /g' | grep 'GNU GENERAL PUBLIC LICENSE Version 3'`

		if ! test -z "$IS_GPL3"; then
			echo "keep existing gpl-3.0 LICENSE ($LFILE)"
			return
		fi

		_confirm "overwrite existing $LFILE file with $LICENSE"
		if test "$CONFIRM" != "y"; then
			echo "keep existing $LFILE file"
			return
		fi
	fi

	_wget "http://www.gnu.org/licenses/gpl-3.0.txt" "$LFILE"
}

#--
# Link $2 to $1.
#
# @param source path
# @param link path
# @require _abort _rm _mkdir _require_program _cd
#--
function _ln {
	_require_program realpath

	local target=`realpath "$1"`

	if test "$PWD" = "$target"; then
		_abort "ln -s '$taget' '$2' # in $PWD"
	fi

	if test -L "$2"; then
		local old_target=`realpath "$2"`

		if test "$target" = "$old_target"; then
			echo "Link $2 to $target already exists"
			return
		fi

		_rm "$2"
	fi

	local link_dir=`dirname "$2"`
	link_dir=`realpath "$link_dir"`
	local target_dir=`dirname "$target"`

	if test "$target_dir" = "$link_dir"; then
		local cwd="$PWD"
		_cd "$target_dir"
		local tname=`basename "$1"`
		local lname=`basename "$2"`
		echo "ln -s '$tname' '$lname' # in $PWD"
		ln -s "$tname" "$lname" || _abort "ln -s '$tname' '$lname' # in $PWD"
		_cd "$cwd"
	else
		_mkdir "$link_dir"
		echo "Link $2 to $target"
		ln -s "$target" "$2"
	fi

	if ! test -L "$2"; then
		_abort "ln -s '$target' '$2'"
	fi
}


declare -Ai LOG_COUNT  # define hash (associative array) of integer
declare -A LOG_FILE  # define hash
declare -A LOG_CMD  # define hash
LOG_NO_ECHO=

#--
# Pring log message. If second parameter is set assume command logging.
# Set LOG_NO_ECHO=1 to disable echo output.
#
# @param message
# @param name (if set use $RKSCRIPT_DIR/$name/$NAME_COUNT.nfo)
# @export LOG_NO_ECHO LOG_COUNT[$2] LOG_FILE[$2] LOG_CMD[$2]
#--
function _log {
	test -z "$LOG_NO_ECHO" && echo -n "$1"
	
	if test -z "$2"; then
		test -z "$LOG_NO_ECHO" && echo
		return
	fi

	# assume $1 is shell command
	LOG_COUNT[$2]=$((LOG_COUNT[$2] + 1))
	LOG_FILE[$2]="$RKSCRIPT_DIR/$2/${LOG_COUNT[$2]}.nfo"
	LOG_CMD[$2]=">>'${LOG_FILE[$2]}' 2>&1"

	if ! test -d "$RKSCRIPT_DIR/$2"; then
		mkdir -p "$RKSCRIPT_DIR/$2"
		if ! test -z "$SUDO_USER"; then
			chown -R $SUDO_USER.$SUDO_USER "$RKSCRIPT_DIR" || _abort "chown -R $SUDO_USER.$SUDO_USER '$RKSCRIPT_DIR'"
		elif test "$UID" = "0"; then
			chmod -R 777 "$RKSCRIPT_DIR" || _abort "chmod -R 777 '$RKSCRIPT_DIR'"
		fi
	fi

	local NOW=`date +'%d.%m.%Y %H:%M:%S'`
	echo -e "# _$2: $NOW\n# $PWD\n# $1 ${LOG_CMD[$2]}\n" > "${LOG_FILE[$2]}"

	if ! test -z "$SUDO_USER"; then
		chown $SUDO_USER.$SUDO_USER "${LOG_FILE[$2]}" || _abort "chown $SUDO_USER.$SUDO_USER '${LOG_FILE[$2]}'"
	elif test "$UID" = "0"; then
		chmod 666 "${LOG_FILE[$2]}" || _abort "chmod 666 '${LOG_FILE[$2]}'"
	fi

	test -z "$LOG_NO_ECHO" && echo " ${LOG_CMD[$2]}"
}


#--
# Run lynx. Keystroke file example: "key q\nkey y"
#
# @param url
# @param keystroke file (optional)
# @require _abort _require_program
#--
function _lynx {
	_require_program lynx

	if test -z "$1"; then
		_abort "url parameter missing"
	fi

	if ! test -z "$2" && test -s "$2"; then
		lynx -cmd_script="$2" -dump "$1"
	else
		lynx -dump "$1"
	fi
}


#--
# Show where php string function needs to change to mb_* version.
#--
function _mb_check {

	echo -e "\nSearch all *.php files in src/ - output filename if string function\nmight need to be replaced with mb_* version.\n"
	echo -e "Type any key to continue or wait 5 sec.\n"

	read -n1 -t 5 ignore_keypress

	# do not use ereg*
	MB_FUNCTIONS="parse_str split stripos stristr strlen strpos strrchr strrichr strripos strrpos strstr strtolower strtoupper strwidth substr_count substr"

	local a=; for a in $MB_FUNCTIONS
	do
		FOUND=`grep -d skip -r --include=*.php $a'(' src | grep -v 'mb_'$a'('`

		if ! test -z "$FOUND"
		then
			echo "$FOUND"
		fi
	done
}


#--
# Print md5sum of file (text if $2=1).
#
# @param file
# @param bool (optional: 1 = threat $1 as string)
# @require _abort _require_program
# @print md5sum
#--
function _md5 {
	_require_program md5sum
	
	if test -z "$1"; then
		_abort "Empty parameter"
	elif test -f "$1"; then
		md5sum "$1" | awk '{print $1}'
	elif test "$2" = "1"; then
		echo -n "$1" | md5sum | awk '{print $1}'
	else
		_abort "No such file [$1]"
	fi
}


#--
# Merge "$APP"_ into $APP (concat "$APP""_/*.inc.sh").
#
# @global APP
# @require _require_file _require_dir _chmod _md5 _rm
#--
function _merge_sh {
	_require_file "$APP"
	local SH_DIR="$APP"'_'
	local TMP_APP="$APP"'__'
	_require_dir "$SH_DIR"

	local MD5_OLD=`_md5 "$APP"`
  echo -n "merge $SH_DIR into $APP ... "

	echo '#!/bin/bash' > "$TMP_APP"

	local a
	for a in "$SH_DIR"/*.inc.sh; do
		tail -n+2 "$a" >> "$TMP_APP"
  done

	local MD5_NEW=`_md5 "$TMP_APP"`

	if test "$MD5_OLD" = "$MD5_NEW"; then
		echo "no change"
		_rm "$TMP_APP" >/dev/null
	else
		echo "update"
		_mv "$TMP_APP" "$APP"
  	_chmod 755 "$APP"
	fi
}


#--
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param flag (optional, 2^0=abort if directory already exists, 2^1=chmod 777 directory)
# @global SUDO
# @require _abort
#--
function _mkdir {

	if test -z "$1"; then	
		_abort "Empty directory path"
	fi

	local FLAG=$(($2 + 0))

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		$SUDO mkdir -p $1 || _abort "mkdir -p '$1'"
	else
		test $((FLAG & 1)) = 1 && _abort "directory $1 already exists"
		echo "directory $1 already exists"
	fi

	test $((FLAG & 2)) = 2 && _chmod 777 "$1"
}


#--
# Mount $1 (e.g. /dev/sdb2) to $2 (e.g. /mnt)
#
# @param device
# @param directory (mount point)
# @require _abort _confirm
#--
function _mount {
	local HAS_FS=`file -sL $1 | grep ' filesystem'`
	if test -z "$HAS_FS"; then
		# check if fat32 boot
		HAS_FS=`file -sL $1 | grep 'MBR boot sector'`

		test -z "$HAS_FS" && _abort "no filesystem on $1"
	fi

	local HAS_MOUNT=`mount | grep -E "^$1 on $2"`

	if test -z "$HAS_MOUNT"; then
		HAS_MOUNT=`mount | grep -E "^$1 on "`
		if ! test -z "$HAS_MOUNT"; then
			_confirm "umount $1 (and re-mount as $2)" 1
			test "$CONFIRM" = "y" || _abort "user abort"
			umount /dev/sdb2 || _abort "umount /dev/sdb2"
		fi

		_confirm "Mount $1 as $2"
		if test "$CONFIRM" = "y"; then
			mount $1 "$2" || _abort "mount $1 '$2'"
		fi

		HAS_MOUNT=`mount | grep -E "^$1 on $2"`
		test -z "$HAS_MOUNT" && _abort "failed to mount $1 as $2"
	else
		echo "$1 is already mounted as $2"
	fi
}


#--
# Print message
#
# @param message
# @param echo option (-n|-e|default='')
#--
function _msg {
	echo $2 "$1"
}

#--
# Move files/directories. Target path directory must exist.
#
# @param source_path
# @param target_path
# @require _abort
#--
function _mv {

	if test -z "$1"; then
		_abort "Empty source path"
	fi

	if test -z "$2"; then
		_abort "Empty target path"
	fi

	local PDIR=`dirname "$2"`
	if ! test -d "$PDIR"; then
		_abort "No such directory [$PDIR]"
	fi

	local AFTER_LAST_SLASH=${1##*/}

	if test "$AFTER_LAST_SLASH" = "*"
	then
		echo "mv $1 $2"
		mv $1 $2 || _abort "mv $1 $2 failed"
	else
		echo "mv '$1' '$2'"
		mv "$1" "$2" || _abort "mv '$1' '$2' failed"
	fi
}


#--
# Check if .my.cnf exists. If found export DB_PASS and DB_NAME. If $SQL_PASS 
# and $MYSQL are set save $MYSQL as $MYSQL_SQL. Otherwise set MYSQL=[mysql --defaults-file=.my.cnf].
#
# @global SQL_PASS MYSQL
# @export DB_NAME DB_PASS MYSQL(=mysql --defaults-file=.my.cnf)
# @param path to .my.cnf (default = .my.cnf)
#--
function _my_cnf {
	local MY_CNF="$1"

	if ! test -z "$SQL_PASS" && ! test -z "$MYSQL"; then
		local MYSQL_SQL="$MYSQL"
	fi

	if test -z "$MY_CNF"; then
		MY_CNF=".my.cnf"
	fi

	if ! test -s "$MY_CNF"; then
		return
	fi

	local MY_CNF_CONTENT=`cat ".my.cnf" 2> /dev/null`
	if test -z "$MY_CNF_CONTENT"; then
		return
	fi

	DB_PASS=`grep password "$MY_CNF" | sed -E 's/.*=\s*//g'`
	DB_NAME=`grep user "$MY_CNF" | sed -E 's/.*=\s*//g'`

	if ! test -z "$DB_PASS" && ! test -z "$DB_NAME" && test -z "$MYSQL_SQL"; then
		MYSQL="mysql --defaults-file=.my.cnf"
	fi
}


#--
# Backup mysql database. Run as cron job. Create daily backup.
# Run as cron job, e.g. daily every 1/2 hour
#
# 10 8,9,10,11,12,13,14,15,16,17,18,19,20  * * *  /path/to/mysql_backup.sh
#
# @param backup directory
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require _abort _cd _cp _mysql_dump _create_tgz _rm
#--
function _mysql_backup {

	local DUMP="mysql_dump."`date +"%H%M"`".tgz"
	local DAILY_DUMP="mysql_dump."`date +"%Y%m%d"`".tgz"
	local FILES="tables.txt"

	if test -f "tables.txt"; then
		_abort "last dump failed or is still running"
	fi

	_cd $1

	echo "update $DUMP and $DAILY_DUMP"

	# dump structure
	echo "create_tables" > tables.txt
	_mysql_dump "create_tables.sql" "-d"
	FILES="$FILES create_tables.sql"

	local T=; for T in $(mysql $MYSQL_CONN -e 'show tables' -s --skip-column-names)
	do
		# dump table
		echo "$T" >> tables.txt
		_mysql_dump "$T"".sql" "--extended-insert=FALSE --no-create-info=TRUE $T"
		FILES="$FILES $T"".sql"
	done

	_create_tgz $DUMP "$FILES"
	_cp "$DUMP" "$DAILY_DUMP"
	_rm "$FILES"

	_cd
}


#--
# Export MYSQL_CONN or MYSQL (if parameter is set) connection string.
# If MYSQL_CONN is empty but DB_NAME and DB_PASS exist use these.
# MYSQL_CONN is "mysql -h DBHOST -u DBUSER -pDBPASS DBNAME".
# MYSQL is "mysql -u root".
#
# @abort
# @global MYSQL_CONN DB_NAME DB_PASS
# @export MYSQL_CONN MYSQL 
# @require _abort
# @param require root access
#--
function _mysql_conn {

	if test -z "$1" && test -z "$MYSQL_CONN"; then
		if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		else
			_abort "mysql connection string MYSQL_CONN is empty (DB_NAME=$DB_NAME)"
		fi
	fi

	if test -z "$MYSQL_CONN" && ! test -z "$1" && test "$UID" = "0"; then
		MYSQL_CONN="-u root"
	fi

	local TRY_MYSQL=

	if test -z "$1"; then
    TRY_MYSQL=`(echo "USE $DB_NAME" | mysql $MYSQL_CONN 2>&1) | grep 'ERROR 1045'`

		if test -z "$TRY_MYSQL"; then
			# MYSQL_CONN works
			return
		else
			_abort "mysql connection for $DB_NAME string is invalid: $MYSQL_CONN"
		fi
	fi

	if test -z "$MYSQL"; then
		if ! test -z "$MYSQL_CONN"; then
			MYSQL="mysql $MYSQL_CONN"
		elif ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
			MYSQL="mysql -h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		fi
	fi

	if ! test -z "$MYSQL"; then
    TRY_MYSQL=`(echo "USE mysql" | $MYSQL 2>&1) | grep 'ERROR 1045'`
    if ! test -z "$TRY_MYSQL" && test "$MYSQL" != "mysql -u root"; then
      MYSQL=
    fi
  fi

  if test -z "$MYSQL"; then
    if test "$UID" = "0"; then
      MYSQL="mysql -u root"
    else
      _abort "you must be root to run [mysql -u root]"
    fi
  fi

  TRY_MYSQL=`(echo "USE mysql" | $MYSQL 2>&1) | grep 'ERROR 1045'`
  if ! test -z "$TRY_MYSQL" && test "$MYSQL" != "mysql -u root"; then
    echo "admin access to mysql database failed: $MYSQL"
  fi
}


#--
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php. DB_CHARSET=[utf8|latin1|utf8mb4=ask] or empty
# (=server default) if nothing is set.
#
# @param dbname = username
# @param password
# @global MYSQL DB_CHARSET
# @export DB_NAME DB_PASS
# @require _abort _mysql_split_dsn _mysql_conn
#--
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	_mysql_split_dsn
	_mysql_conn 1

	local HAS_DB=`echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL 2> /dev/null && echo "ok"`
	if ! test -z "$HAS_DB"; then
		echo "Keep existing database $DB_NAME"
		return
	fi

	local CHARSET=

	if test "$DB_CHARSET" = "utf8mb4"; then
		CHARSET="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
	elif test "$DB_CHARSET" = "utf8"; then
		CHARSET="DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci"
	elif test "$DB_CHARSET" = "latin1"; then
		CHARSET="DEFAULT CHARACTER SET latin1 DEFAULT COLLATE latin1_german1_ci"
	else
		_confirm "Use charset utf8mb4"
		if test "$CONFIRM" = "y"; then
			CHARSET="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
		fi
	fi

	echo "create mysql database $DB_NAME"
	echo "CREATE DATABASE $DB_NAME $CHARSET" | $MYSQL || _abort "create database $DB_NAME failed"
	echo "create mysql database user $DB_NAME"
	echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" | $MYSQL || \
		_abort "create database user $DB_NAME failed"
}


#--
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require _abort
#--
function _mysql_dump {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	nice -n 10 ionice -c2 -n 7 mysqldump --single-transaction --quick $MYSQL_CONN $2 > "$1" || _abort "mysqldump ... $2 > $1 failed"
	echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	if ! test -f "$1"; then
		_abort "no such dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi
}


#--
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh. 
#
# @param dump_file (if empty try data/sql/mysqlfulldump.sql, setup/mysqlfulldump.sql)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require _abort _confirm _mysql_conn
#--
function _mysql_load {

	local DUMP=$1

	if ! test -f "$DUMP"; then
		if test -s "data/sql/mysqlfulldump.sql"; then
			DUMP=data/sql/mysqlfulldump.sql
		elif test -s "setup/mysqlfulldump.sql"; then
			DUMP=setup/mysqlfulldump.sql
		else
			_abort "no such mysql dump [$DUMP]"
		fi

		_confirm "Load $DUMP?"
		if test "$CONFIRM" != "y"; then
			echo "Do not load $DUMP"
			return
		fi
	fi

	local DUMP_OK=`tail -1 "$DUMP" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$DUMP]"
	fi

	if ! test -z "$FIX_MYSQL_DUMP"; then
		echo "fix $DUMP"
		local TMP_DUMP=`dirname $DUMP`"/_fix.sql"
		echo -e "SET FOREIGN_KEY_CHECKS=0;\nSTART TRANSACTION;\n" > $TMP_DUMP
		sed -e "s/^\/\*\!.*//" < $DUMP | sed -e "s/^INSERT INTO/INSERT IGNORE INTO/" >> $TMP_DUMP
		echo -e "\nCOMMIT;\n" >> $TMP_DUMP
		mv "$TMP_DUMP" "$DUMP"
	fi

	if test -f "restore.sh"; then
		local LOG="$DUMP"".log"
		echo "add $DUMP to restore.sh"
		echo "_restore $DUMP &" >> restore.sh
	else
		_mysql_conn
		echo "mysql ... < $DUMP"
		SECONDS=0
		mysql $MYSQL_CONN < "$DUMP" || _abort "mysql ... < $DUMP failed"
		echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
	fi
}


#--
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @param parallel_import (optional - use parallel import if set)
# @global MYSQL_CONN (call _mysql_conn for mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME")
# @require _abort _extract_tgz _cd _cp _chmod _rm _mv _mkdir _mysql_load _mysql_conn
#--
function _mysql_restore {

	local TMP_DIR="/tmp/mysql_dump"
	local FILE=`basename $1`

	_mkdir $TMP_DIR 1
	_cp "$1" "$TMP_DIR/$FILE"

	_cd $TMP_DIR

	_extract_tgz "$FILE" "tables.txt"

	cat create_tables.sql | sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' > create_tables.fix.sql
	local IS_DIFFERENT=`cmp -b create_tables.sql create_tables.fix.sql`

	if ! test -z "$IS_DIFFERENT"; then
		_mv create_tables.fix.sql create_tables.sql
	else
		_rm create_tables.fix.sql
	fi

	local a=; for a in `cat tables.txt`
	do
		# load only create_tables.sql ... write other load commands to restore.sh
		_mysql_load $a".sql"

		if ! test -z "$2" && test "$a" = "create_tables"; then
			_mysql_conn
			echo "create restore.sh"
			echo -e "#!/bin/bash\n" > restore.sh
			echo -e "MYSQL_CONN=\"$MYSQL_CONN\"\n" >> restore.sh
			echo 'function _restore {' >> restore.sh
			echo '  mysql $MYSQL_CONN < $1 &> $1".log" && rm $1 || echo "import $1 failed"' >> restore.sh
			echo '  echo "$1 import finished"' >> restore.sh
			echo -e "}\n\n" >> restore.sh
			_chmod 755 restore.sh
		fi
	done

  if ! test -z "$2"; then
    echo "start table imports in background"  
    . restore.sh

    _rm "create_tables.sql"
    local IMPORT=1
    SECONDS=0

    while test "$IMPORT" = "1"
    do
      IMPORT=0
      for a in `cat tables.txt`
      do
        # sql file is removed after successfull import
        if test -f $a".sql"; then
          IMPORT=1
        fi
      done

      sleep 10
    done

    echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
  fi

	_cd

	_rm $TMP_DIR
}


#--
# Split php database connect string SETTINGS_DSN. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @export DB_NAME DB_PASS MYSQL
# @require _abort _find_docroot _my_cnf 
#--
function _mysql_split_dsn {
	local SETTINGS_DSN=
	local PATH_RKPHPLIB=$PATH_RKPHPLIB
	local PHP_CODE=

	_my_cnf

	if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"
	then
		# use already defined DB_NAME and DB_PASS
		return
	fi

	if ! test -f "$1"; then
		test -z "$DOCROOT" && _find_docroot "$PWD"

		if test -f "$DOCROOT/settings.php"; then
			_mysql_split_dsn "$DOCROOT/settings.php"
			return
		elif test -f "$DOCROOT/index.php"; then
			_mysql_split_dsn "$DOCROOT/index.php"
			return
		fi

		_abort "no such file [$1]"
	fi

	PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("SETTINGS_DSN")) print SETTINGS_DSN;'
	SETTINGS_DSN=`php -r "$PHP_CODE"`

	if test -z "$PATH_RKPHPLIB"; then
		PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("PATH_RKPHPLIB")) print PATH_RKPHPLIB;'
		PATH_RKPHPLIB=`php -r "$PHP_CODE"`
	fi
	
	if test -z "$PATH_RKPHPLIB" && test -d "/webhome/.php/rkphplib/src"; then
		PATH_RKPHPLIB="/webhome/.php/rkphplib/src/"
	fi

	if test -z "$SETTINGS_DSN" && test -f "settings.php"; then
		PHP_CODE='ob_start(); include("settings.php"); $html = ob_get_clean(); if (defined("SETTINGS_DSN")) print SETTINGS_DSN;'
		SETTINGS_DSN=`php -r "$PHP_CODE"`
		DOCROOT="$PWD"
	fi

	if ! test -z "$DOCROOT" && ! test -z "$PATH_RKPHPLIB" && ! test -f "$PATH_RKPHPLIB/Exception.class.php" && \
			test -f "$DOCROOT/$PATH_RKPHPLIB/Exception.class.php"; then
		PATH_RKPHPLIB="$DOCROOT/$PATH_RKPHPLIB"
	fi

	if test -z "$SETTINGS_DSN"; then
		_abort "autodetect SETTINGS_DSN failed"
	fi
 
	if test -z "$PATH_RKPHPLIB"; then
		if test -d "/home/rk/Desktop/workspace/rkphplib/src"; then
			PATH_RKPHPLIB="/home/rk/Desktop/workspace/rkphplib/src/"
		else
			_abort "autodetect PATH_RKPHPLIB failed - export PATH_RKPHPLIB=/path/to/rkphplib/src/"
		fi
	fi

	local SPLIT_DSN='require("'$PATH_RKPHPLIB'ADatabase.class.php"); $dsn = \rkphplib\ADatabase::splitDSN("'$SETTINGS_DSN'");'

	PHP_CODE=$SPLIT_DSN' print $dsn["login"];'
	DB_NAME=`php -r "$PHP_CODE"`

	PHP_CODE=$SPLIT_DSN' print $dsn["password"];'
	DB_PASS=`php -r "$PHP_CODE"`

	if test -z "$DB_NAME" || test -z "$DB_PASS"; then
		_abort "database name [$DB_NAME] or password [$DB_PASS] is empty"
	fi
}


#--
# Check node.js version. Install node and npm if missing. 
# Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v12.14.0 and NPM_VERSION=6.13.4 as default.
#
# @global NODE_VERSION NPM_VERSION APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
# @require _ver3 _require_global _install_node _sudo
#--
function _node_version {

	if test -z "$NODE_VERSION"; then
		NODE_VERSION=v12.14.0
	fi

	if test -z "$NPM_VERSION"; then
		NPM_VERSION=6.13.4
	fi

	local HAS_NODE=`which node`
	local HAS_NPM=`which npm`

	if test -z "$HAS_NODE" || test -z "$HAS_NPM"; then
		_install_node
	fi

	_require_global "NODE_VERSION NPM_VERSION"

	local CURR_NODE_VERSION=`node --version`

	if [ $(_ver3 $CURR_NODE_VERSION) -lt $(_ver3 $NODE_VERSION) ]
	then
		_install_node
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(_ver3 $CURR_NPM_VERSION) -lt $(_ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest"
		_sudo "npm i -g npm"
	fi
}


#--
# Copy module from node_module/$2 to $1 if necessary.
# Apply patch patch/npm2js/`basename $1`.patch if found.
#
# @param target path
# @param source path (node_modules/$2)
# @require _abort _cp _patch
#--
function _npm2js {

	if test -z "$2"; then
		_abort "empty module path"
	fi

	if ! test -f "node_modules/$2" && ! test -d "node_modules/$2"; then
		_abort "missing node_modules/$2"
	fi

	_cp "node_modules/$2" "$1" md5

	local BASE=`basename "$1"`
	local PATCH="$BASE"".patch"

	if test -f patch/npm2js/$PATCH; then
		PATCH_LIST="$BASE"
		PATCH_DIR=`dirname "$1"`
		_patch patch/npm2js
	fi
}


#--
# Install npm module $1 (globally if $2 = -g)
#
# @sudo
# @param package_name
# @param npm_param (e.g. -g, --save-dev)
# @require _node_version
#--
function _npm_module {

  local HAS_NPM=`which npm`
  if test -z "$HAS_NPM"; then
		_node_version
  fi

	local EXTRA_PARAM=

	if test "$1" = "ios-deploy"; then
		EXTRA_PARAM="--unsafe-perm=true --allow-root"
	fi

	if test "$2" = "-g"
	then
		if test -d /usr/local/lib/node_modules/$1
		then
			echo "node module $1 is already globally installed - updating"
			sudo npm update $EXTRA_PARAM -g $1
			return
		else
			echo "install node module $1 globally"
			sudo npm install $EXTRA_PARAM -g $1
			return
		fi
	fi

	if test -d node_modules/$1
	then
		echo "node module $1 is already installed - updating"
		npm update $EXTRA_PARAM $1
	return
	fi

	npm install $EXTRA_PARAM $1 $2
}

#--
# Backup $1 as $1.orig (if not already done).
#
# @param path
# @param bool is_optional
# @require _cp _abort
#--
function _orig {
	if test -f "$1"; then
		if test -f "$1.orig"; then
			echo "Backup $1.orig already exists"
		else
			echo "Backup $1 as $1.orig"
			_cp "$1" "$1.orig"
		fi
	elif test -d "$1"; then
		if test -d "$1.orig"; then
			echo "Backup $1.orig already exists"
		else
			echo "Backup $1 as $1.orig"
			_cp "$1" "$1.orig"
		fi
	elif test -z "$2"; then
		_abort "missing $1"
	fi
}


#--
# Return linux, macos, cygwin if $1 is empty. 
# If $1 is set and != os_type abort otherwise return 0.
#
# @print string (abort if set and os_type != $1)
# @require _abort _require_program
# @print linux|macos|cygwin if $1 is empty
# @return bool
#--
function _os_type {
	local os=

	_require_program uname

	if [ "$(uname)" = "Darwin" ]; then
		os="macos"        
	elif [ "$OSTYPE" = "linux-gnu" ]; then
		os="linux"
	elif [ $(expr substr $(uname -s) 1 5) = "Linux" ]; then
		os="linux"
	elif [ $(expr substr $(uname -s) 1 5) = "MINGW" ]; then
		os="cygwin"
	fi

	if test -z "$1"; then
		echo $os
	elif test "$1" != "$os"; then
		_abort "$1 required (this is $os)"
	fi

	return 0
}

if [ "$(uname)" = "Darwin" ]; then

# enable alias expansion
shopt -s expand_aliases 

# osx has no realpath
alias realpath="python -c 'import os,sys;print os.path.realpath(sys.argv[1])'"


#--
# OSX has md5 instead of md5sum. Use md5sum function wrapper.
#
# @param file
#--
function md5sum {
	md5 -q "$1"
}


#--
# OSX /usr/bin/stat is incompatible with linux. Use stat function wrapper.
#
# @param -c
# @param -
# @require _abort 
#--
function stat {
	if test "$1" = "-c"; then
		if test "$2" = "%Y"; then
			/usr/bin/stat -f %m "$3"
			return
		elif test "$2" = "%U"; then
			ls -la "$3" | awk '{print $3}'
		elif test "$2" = "%G"; then
			ls -la "$3" | awk '{print $3}'
		elif test "$2" = "%a"; then
			/usr/bin/stat -f %A "$3"
		fi
	else
		_abort "ToDo: stat $@"
	fi
}

fi


#--
# Overwrite directory $2 with $1 (copy $1 to $2). If backup does not exist
# create it ($2.orig|bak).
#
# @param source directory $1
# @param target directory $2
#--
function _overwrite_dir {
	if ! test -d "$2"; then
		_cp "$1" "$2"
		return
	fi

	local OVERWRITE=1
	local BACKUP="$2.orig"

	if test -d "$2.orig"; then
		OVERWRITE=
		BACKUP="$2.bak"
	fi

	_confirm "Overwrite existing directory $2 (auto-backup)" $OVERWRITE
	if test "$CONFIRM" = "y"; then
		echo "backup and overwrite directory"
		_cp "$2" "$BACKUP"
		_cp "$1" "$2"
	else
		echo "keep existing directory $2"
		return
	fi
}


#--
# Overwrite file $2 with $1 (copy $1 to $2). If backup does not exist
# create it ($2.orig|bak).
#
# @param source file $1
# @param target file $2
#--
function _overwrite_file {
	if ! test -f "$2"; then
		_cp "$1" "$2"
		return
	fi

	local OVERWRITE=1
	local BACKUP="$2.orig"

	if test -f "$2.orig"; then
		OVERWRITE=
		BACKUP="$2.bak"
	fi

	_confirm "Overwrite existing file $2 (auto-backup)" $OVERWRITE
	if test "$CONFIRM" = "y"; then
		echo "backup and overwrite file"
		_cp "$2" "$BACKUP" md5
		_cp "$1" "$2" md5
	else
		echo "keep existing file $2"
		return
	fi
}


#--
# Install or update npm packages. Create package.json and README.md if missing.
# Apply patches if patch/patch.sh exists.
#
# @param upgrade (default = empty = false)
# @global NPM_PACKAGE NPM_PACKAGE_GLOBAL NPM_PACKAGE_DEV (e.g. "pkg1 ... pkgN")
# @require _npm_module
#--
function _package_json {

	if ! test -f package.json; then
		echo "create: package.json"
		echo '{ "name": "ToDo", "version": "0.1.0", "title": "ToDo", "description": "ToDo", "repository": {} }' > package.json
	fi

	if ! test -f README.md; then
		echo "create: README.md - adjust content"
		echo "ToDo" > README.md
	fi

	if ! test -z "$1"; then
		echo "upgrade package.json"
		_npm_module npm-check-updates -g
		npm-check-updates -u
	fi

	local a=; for a in $NPM_PACKAGE_GLOBAL; do
		_npm_module $a -g
	done

	local RUN_INSTALL=
	local HAS_PKG=

	for a in $NPM_PACKAGE $NPM_PACKAGE_DEV; do
		HAS_PKG=`grep $a package.json`
		if ! test -z "$HAS_PKG"; then
			RUN_INSTALL=1
		fi
	done

	if ! test -z "$RUN_INSTALL"; then
		echo "run: npm install"
		npm install
	fi

	for a in $NPM_PACKAGE; do
		_npm_module $a --save
	done

	for a in $NPM_PACKAGE_DEV; do
		_npm_module $a --save-dev
	done

	if test -f patch/patch.sh; then
		echo "Apply patches: patch/patch.sh"
		cd patch
		./patch.sh
		cd ..
	fi
}


declare -A ARG

#--
# Set ARG[name]=value if --name=value or name=value.
# If --name set ARG[name]=1. Set ARG[0] ... ARG[n].
# Reset ARG if ARG[0] is set.
#
# @parameter any
# @global ARG (hash)
#--
function _parse_arg {
	local key=; local i=; local v=;
	test -z "${ARG[0]}" || ARG=()

	for (( i = 0; i <= $#; i++ )); do
		ARG[$i]="${!i}"
		v="${!i}"

		if [[ $v == "--"*"="* ]]; then
			key="${v/=*/}"
			ARG[${key/--/}]="${v/*=/}"
		elif [[ $v == "--"* ]]; then
			ARG[${v/--/}]=1
		elif [[ $v == *"="* ]]; then
			ARG[${v/=*/}]="${v/*=/}"
		fi
	done
}


#--
# Patch either PATCH_LIST and PATCH_DIR are set or $1/patch.sh exists.
# If $1/patch.sh exists it must export PATCH_LIST and PATCH_DIR.
# Apply patch if target file and patch file exist.
#
# @param patch file directory
# @require _abort
#--
function _patch {

	if test -f "$1/patch.sh"; then
		. $1/patch.sh
	fi

	local a=; for a in $PATCH_LIST
  do
    local SRC=`find $PATCH_DIR | grep $a`

    if test -f $1/$a.patch && test -f "$SRC"
    then
			echo "patch $SRC $1/$a.patch"
      patch $SRC $1/$a.patch || _abort "patch failed"
    fi
  done
}


#--
# Create phpdocumentor documentation for php project in docs/phpdocumentor.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/phpdocumentor)
# @require _abort _require_program _require_dir _mkdir _cd _composer_json _confirm _rm
#--
function _phpdocumentor {
  local DOC_DIR=./docs/phpdocumentor
	local PRJ="docs/.phpdocumentor"
	local BIN="$PRJ/vendor/phpdocumentor/phpdocumentor/bin/phpdoc"
	local SRC_DIR=./src

	_mkdir "$DOC_DIR"
	_mkdir "$PRJ"
	_require_program composer

	local CURR="$PWD"

	if ! test -f "$PRJ/composer.json"; then
		_cd "$PRJ"
		_composer_json "rklib/rkphplib_doc_phpdocumentor"
		composer require "phpdocumentor/phpdocumentor:dev-master"
		_cd "$CURR"
	fi

	if ! test -s "$BIN"; then
		_cd "$PRJ"
		composer update
		_cd "$CURR"
	fi

	if ! test -z "$1"; then
		SRC_DIR="$1"
	fi

	if ! test -z "$2"; then
		DOC_DIR="$2"
	fi

	_require_dir "$SRC_DIR"

	if test -d "$DOC_DIR"; then
		_confirm "Remove existing documentation directory [$DOC_DIR] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$DOC_DIR"
		fi
	fi

	echo "Create phpdocumentor documentation"
	echo "$BIN run -d '$SRC_DIR' -t '$DOC_DIR'"
	$BIN run -d "$SRC_DIR" -t "$DOC_DIR"
}

#--
# Start buildin standalone PHP Webserver. Use ARG:
#   - user ($USER) 
#   - port (15080)
#   - docroot ($PWD)
#   - script (buildin = RKSCRIPT_DIR/php_server.php)
#	  - host (0.0.0.0)
#
# @call_before _parse_arg "$@" 
# @global RKSCRIPT_DIR ARG
# @require _require_program _abort _mkdir _confirm _is_running
#--
function _php_server {
	_require_program php
	_mkdir "$RKSCRIPT_DIR" > /dev/null

	local PHP_CODE=
IFS='' read -r -d '' PHP_CODE <<'EOF'
<?php

function wsLog($msg) {
	file_put_contents("php://stdout", $msg."\n");
}


function wsHtaccessRedirect($htaccess_file) {
	$htaccess = file($htaccess_file);
	$uri = mb_substr($_SERVER['REQUEST_URI'], 1);

	foreach ($htaccess as $line) {
	  if (mb_substr($line, 0, 12) == 'RewriteRule ' && ($pos = mb_strpos($line, 'index.php')) !== false) {
  	  $rx = '/'.trim(mb_substr($line, 12, $pos - 12)).'/i';

	    if (preg_match($rx, $uri, $match)) {
	    	$redir = trim(mb_substr($line, $pos));
    	  for ($n = 1; $n < count($match); $n++) {
      	  $redir = str_replace('$'.$n, $match[$n], $redir);
	      }

				wsLog("redirect: $redir");
				header('Location: '.$redir);
				exit();
	    }
	  }
	}
}


if (file_exists($_SERVER['DOCUMENT_ROOT'].'/.htaccess')) {
	wsHtaccessRedirect($_SERVER['DOCUMENT_ROOT'].'/.htaccess');
}

if (!preg_match('/\.inc\.([a-z]+)$/i', $_SERVER['SCRIPT_NAME']) &&
		preg_match('/\.(php|js|css|html?|jpe?g|png|gif|ico|svg|eot|ttf|woff2?)$/i', $_SERVER['SCRIPT_NAME']) && 
		file_exists($_SERVER['DOCUMENT_ROOT'].$_SERVER['SCRIPT_NAME'])) {
	return false;
}
else if (getenv('route')) {
	require_once $_SERVER['DOCUMENT_ROOT'].'/'.getenv('route');
}
else {
	wsLog('return 403 ('.$_SERVER['DOCUMENT_ROOT'].$_SERVER['SCRIPT_NAME'].': '.$_SERVER['REQUEST_URI'].')');
	http_response_code(403);
	exit();
}
EOF

	test -z "${ARG[0]}" && _abort 'call _parse_arg "@$" first'

	if test -z "${ARG[script]}"; then
		echo "$PHP_CODE" > "$RKSCRIPT_DIR/php_server.php"
		ARG[script]="$RKSCRIPT_DIR/php_server.php"
	fi

	test -z "${ARG[port]}" && ARG[port]=15080
	test -z "${ARG[docroot]}" && ARG[docroot]="$PWD"
	test -z "${ARG[host]}" && ARG[host]="0.0.0.0"
	local LOG="$RKSCRIPT_DIR/php_server.log"
	local SERVER_PID=

	if _is_running "PORT" "${ARG[port]}"; then
		local SERVER_PID=`ps aux | grep -E "[p]hp .+S ${ARG[host]}:${ARG[port]}" | awk '{print $2}'`
		test -z "$SERVER_PID" && _abort "Port ${ARG[port]} is already used" || \
			_abort "PHP Server is already running on ${ARG[host]}:${ARG[port]}\n\nStop PHP Server: kill [-9] $SERVER_PID"
	fi

	_confirm "Start buildin PHP standalone Webserver" 1
	test "$CONFIRM" = "y" || _abort "user abort"

	if test -z "${ARG[user]}"; then
		{ php -t "${ARG[docroot]}" -S ${ARG[host]}:${ARG[port]} "${ARG[script]}" >"$LOG" 2>&1 || \
			_abort "PHP Server failed - see: $LOG"; } &
	else
		{ sudo -H -u ${ARG[user]} bash -c "php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$LOG' 2>&1" || \
			_abort "PHP Server failed - see: $LOG"; } &
		sleep 1
	fi

	local SERVER_PID=`ps aux | grep -E "[p]hp .+S ${ARG[host]}:${ARG[port]}" | awk '{print $2}'` 
	test -z "$SERVER_PID" && _abort "Could not determine Server PID"

	echo -e "\nPHP buildin standalone server started"
	echo "URL: http://${ARG[host]}:${ARG[port]}"
	echo "LOG: tail -f $LOG"
	echo "DOCROOT: ${ARG[docroot]}"
	echo "CMD: php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$LOG' 2>&1"
	echo -e "STOP: kill $SERVER_PID\n"
}


#--
# Export PHP_VERSION=MAJOR.MINOR
# 
# @export PHP_VERSION
#--
function _php_version {
	PHP_VERSION=`php -v | grep -E '^PHP [0-9\.]+\-' | sed -E 's/PHP ([0-9]\.[0-9]).+$/\1/'`
}


#--
# Print $1 $2. If length $2 > 40 print [$1 $2:0:30 ... $2:-10].
# 
# @param string
# @param string
#--
function _print {
	if test ${#2} -gt 40; then
		echo "$1 ${2:0:30} ... ${2: -10}"
	else
		echo "$1 $2"
	fi
}


#--
# Print random string of length $1 (chars from [0-9a-zA-Z-_]).
# 
# @example _random_string n 10 26 = random from [a-z], length n
# @example _random_string n 36 26 = random from [A-Z], length n
# @example _random_string n 0 62 = random from [0-9a-zA-Z], length n 
#
# @param string length (default = 8)
# @param string char pos [0-63]
# @param string char length [1-64]
#--
function _random_string {
	local CHARS="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"
	local LEN=${1:-8}
	local i

	if ! test -z "$2" && ! test -z "$3"; then
		CHARS="${CHARS:$2:$3}"
	fi

	for (( i = 0; i < $1; i++ )); do
		echo -n "${CHARS:RANDOM%${#CHARS}:1}"
	done
	echo
}


#--
# realpath replacement on osx
#
# @param path
#--
function _realpath_osx {
	local REALPATH=
	local LINK=
	local CURR=$PWD

	cd "$(dirname "$1")"
	LINK=$(readlink "$(basename "$1")")

	while [ "$LINK" ]; do
		cd "$(dirname "$LINK")"
		LINK=$(readlink "$(basename "$1")")
	done

	REALPATH="$PWD/$(basename "$1")"

	cd "$CURR"
	echo "$REALPATH"
}


#--
# Re-create database if inside docker.
#
# @param do_not_load_dump (optional, default = empty = load_dump)
# @require _mysql_split_dsn _mysql_create_db _mysql_load
# @export DB_NAME DB_PASS MYSQL_CONN
#--
function _recreate_docker_db {
	local INSIDE_DOCKER=`cat /etc/hosts | grep 172.17`

	if test -z "$INSIDE_DOCKER"; then
		echo "not inside docker - abort database recreate"
		return
	fi

	_mysql_split_dsn
	_mysql_create_db $DB_NAME $DB_PASS

	if test -z "$1"; then
		_mysql_load
	fi
}


#--
# Export remote ip adress REMOTE_IP and REMOTE_IP6.
#
# @export REMOTE_IP REMOTE_IP6
# @require _abort _require_program
#--
function _remote_ip {
	_require_program curl

	local IP4_IP6=`curl -sSL https://dyn4.de/ip.php`

	REMOTE_IP=`echo "$IP4_IP6" | awk '{print $1}'`
	REMOTE_IP6=`echo "$IP4_IP6" | awk '{print $2}'`
}


#--
# Abort if directory does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
# @require _abort _require_priv _require_owner
#--
function _require_dir {
	test -d "$1" || _abort "no such directory '$1'"
	test -z "$2" || _require_owner "$1" "$2"
	test -z "$3" || _require_priv "$1" "$3"
}


#--
# Export required rkscript/src/* functions as $REQUIRED_RKSCRIPT.
# Call scan_rkscript_src first.
#
# @param string shell script
# @param boolean resolve recursive
# @export REQUIRED_RKSCRIPT REQUIRED_RKSCRIPT_INCLUDE
# @global RKSCRIPT_FUNCTIONS
# @require _require_global
#--
function _required_rkscript {
	local BASE=`basename "$1"`
	# negative offset doesn't work in OSX bash replace ${BASE::-3} with ${BASE:0:${#BASE}-3}
	local FUNC="_"${BASE:0:${#BASE}-3}

	_require_global RKSCRIPT_FUNCTIONS

	if [ -z ${REQUIRED_RKSCRIPT+x} ]; then
		REQUIRED_RKSCRIPT_INCLUDE=
	fi

	if [[ "$REQUIRED_RKSCRIPT_INCLUDE" =~ " $FUNC" ]]; then
		# skip already included
		return
	fi

	REQUIRED_RKSCRIPT_INCLUDE="$REQUIRED_RKSCRIPT_INCLUDE $FUNC"

	local LIST=; local b=; local a=; local sh_run=; local n=0
	for a in $RKSCRIPT_FUNCTIONS; do
		b=`cat "$1" | sed -e "s/function .*//" | grep "$a "`

		if test -z "$b"; then
			b=`cat "$1" | sed -e "s/function .*//" | grep "^\s*$a\s*$"`
		fi

		sh_run=`echo "$1" | grep 'sh/run/'`
		if test -z "$b" && ! test -z "$sh_run"; then
			b=`cat "$1" | grep -E "^\s*$a(\s|$)" | sed -E "s/^\s*($a)(\s.*$|$)/\1/"`
		fi

		if ! test -z "$b" && test "$FUNC" != "$a"; then
			LIST="$a $LIST"
			n=$((n + 1))
		fi
	done

	echo "include $FUNC (use $n functions)"

	if ! test -z "$2"; then		
		local RESULT="$LIST"

		for a in $LIST; do
			b="$RKSCRIPT_PATH/src/"${a:1}".sh"
			_required_rkscript $b $2
			# OSX workaround: use [sed -e 's/ /\'$'\n/g'] instead of [sed -e "s/ /\n/g"]
			RESULT=`echo "$RESULT $REQUIRED_RKSCRIPT" | sed -e 's/ /\'$'\n/g' | sort -u | xargs`
		done

		LIST="$RESULT"
	fi

	REQUIRED_RKSCRIPT="$LIST"
}


#--
# Abort if file does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
# @require _abort _require_owner _require_priv
#--
function _require_file {
	test -f "$1" || _abort "no such file '$1'"
	test -z "$2" || _require_owner "$1" "$2"
	test -z "$3" || _require_priv "$1" "$3"
}


#--
# Abort if global variable is empty. With bash version >= 4.4 check works even
# for arrays. If bash version < 4.4 export HAS_HASH_$1
#
# @param variable name (e.g. "GLOBAL" or "GLOB1 GLOB2 ...")
# @require _abort
#--
function _require_global {
	local BASH_VERSION=`bash --version | grep -iE '.+bash.+version [0-9\.]+' | sed -E 's/^.+version ([0-9]+)\.([0-9]+)\..+$/\1.\2/i'`

	local a=; local has_hash=; 
	for a in $1; do
		has_hash="HAS_HASH_$a"

		if (( $(echo "$BASH_VERSION >= 4.4" | bc -l) )); then
			typeset -n ARR=$a

			if test -z "$ARR" && test -z "${ARR[@]:1:1}"; then
				_abort "no such global variable $a"
			fi
		elif test -z "${a}" && test -z "${has_hash}"; then
			_abort "no such global variable $a - add HAS_HASH_$a if necessary"
		fi
	done
}

#--
# Abort if file or directory owner:group don't match.
#
# @param path
# @param owner[:group]
# @require _abort
#--
function _require_owner {
	if ! test -f "$1" && ! test -d "$1"; then
		_abort "no such file or directory '$1'"
	fi

	local arr=( ${2//:/ } )
	local owner=`stat -c '%U' "$1" 2>/dev/null`
	test -z "$owner" && _abort "stat -c '%U' '$1'"
	local group=`stat -c '%G' "$1" 2>/dev/null`
	test -z "$group" && _abort "stat -c '%G' '$1'"

	if ! test -z "${arr[0]}" && ! test "${arr[0]}" = "$owner"; then
		_abort "invalid owner - chown ${arr[0]} '$1'"
	fi

	if ! test -z "${arr[1]}" && ! test "${arr[1]}" = "$group"; then
		_abort "invalid group - chgrp ${arr[1]} '$1'"
	fi
}


#--
# Abort if file or directory privileges don't match.
#
# @param path
# @param privileges (e.g. 600)
# @require _abort
#--
function _require_priv {
	test -z "$2" && _abort "empty privileges"
	local priv=`stat -c '%a' "$1" 2>/dev/null`
	test -z "$priv" && _abort "stat -c '%a' '$1'"
	test "$2" = "$priv" || _abort "invalid privileges [$priv] - chmod -R $2 '$1'"
}


#--
# Abort if program (function) $1 does not exist (and $2 is not 1).
#
# @param program
# @param return_bool (default = 0)
# @require _abort
# @return bool (if $2==1)
#--
function _require_program {
	local TYPE=`type -t "$1"`
	local ERROR=0
  local CHECK=$2

	test "$TYPE" = "function" && return $ERROR

	command -v "$1" >/dev/null 2>&1 || ERROR=1

  if ((!CHECK && ERROR)); then
    echo "No such program [$1]" && exit 1
  fi

	return $ERROR
}


#--
function __abort {
	echo -e "\nABORT: $1\n\n"
	exit 1
}


#--
# Use for dynamic loading.
# @example _rkscript "_rm _mv _cp _mkdir"
# @global RKSCRIPT = /path/to/rkscript/src
# @param function list
#--
function _rkscript {

	if test -z "$RKSCRIPT"; then
		RKSCRIPT=../../rkscript/src
	fi

	if ! test -d "$RKSCRIPT"; then
		RKSCRIPT=../../../rkscript/src
	fi

	local ABORT=_abort
	local HAS_ABORT=`type -t $ABORT`
	if ! test "$HAS_ABORT" = "function"; then
		ABORT=__abort
	fi

	if ! test -d "$RKSCRIPT" || ! test -f "$RKSCRIPT/abort.sh"; then
		$ABORT "invalid RKSCRIPT path [$RKSCRIPT] - $APP_PREFIX $APP"
	fi

	for a in $1; do
		local TYPE=`type -t $a`
		if ! test "$TYPE" = "function"; then
			echo "load $a"
			. "$RKSCRIPT/${a:1}.sh" || $ABORT "no such function $a"
		else 
			echo "found $a"
		fi
	done
}


#--
# Remove files/directories.
#
# @param path_list
# @param int (optional - abort if set and path is invalid)
# @require _abort
#--
function _rm {

	if test -z "$1"; then
		_abort "Empty remove path list"
	fi

	local a=; for a in $1
	do
		if ! test -f $a && ! test -d $a
		then
			if ! test -z "$2"; then
				_abort "No such file or directory $a"
			fi
		else
			echo "remove $a"
			rm -rf $a
		fi
	done
}


#--
# Rsync $1 to $2. Apply rsync parameter $3 if set (e.g. --delete).
#
# @param source path e.g. user@host:/path/to/source
# @param target path default=[.]
# @param optional rsync parameter e.g. "--delete --exclude /data"
# @require _abort _log
#--
function _rsync {
	local TARGET="$2"

	if test -z "$TARGET"; then
		TARGET="."
	fi

	if test -z "$1"; then
		_abort "Empty rsync source"
	fi

	if ! test -d "$TARGET"; then
		_abort "No such directory [$TARGET]"
	fi

	local RSYNC="rsync -av $3 -e ssh '$1' '$2'"; local error=
	_log "$RSYNC" rsync
	eval "$RSYNC ${LOG_CMD[rsync]}" || error=1

	if test "$error" = "1"; then
		local sync_finished=`tail -4 ${LOG_FILE[rsync]} | grep 'speedup is '`

		if test -z "$sync_finished"; then
			_abort "$RSYNC"
		fi
	fi
}


#--
# Abort if user is not root. If sudo cache time is ok allow sudo with $1 = 1.
#
# @param try sudo
# @require _abort
#--
function _run_as_root {
	test "$UID" = "0" && return

	if test -z "$1"; then
		_abort "Please change into root and try again"
	else
		echo "sudo true - Please type in your password"
		sudo true 2>/dev/null || _abort "sudo true failed - Please change into root and try again"
	fi
}


#--
# Scan $RKSCRIPT_PATH/src/* directory. Cache result RKSCRIPT_FUNCTIONS.
#
# @export RKSCRIPT_FUNCTIONS 
# @global RKSCRIPT_PATH
# @require _require_global _cd _cache
#--
function _scan_rkscript_src {
	RKSCRIPT_FUNCTIONS=

	local HAS_CACHE=`type -t _cache`

	if test "$HAS_CACHE" = "function"; then
		_cache RKSCRIPT_FUNCTIONS
	fi

	if ! test -z "$RKSCRIPT_FUNCTIONS"; then
		echo "use cached result of _scan_rkscript_src (RKSCRIPT_FUNCTIONS)"
		return
	fi

	_require_global RKSCRIPT_PATH

	local CURR=$PWD
	_cd $RKSCRIPT_PATH/src

	local F=; local a=; local n=0
	for a in *.sh; do
		# negative length doesn't work in OSX bash replace ${a::-3} with ${a:0:${#a}-3}
		F="_"${a:0:${#a}-3}
		RKSCRIPT_FUNCTIONS="$F $RKSCRIPT_FUNCTIONS"
		n=$((n + 1))
	done

	echo "found $n RKSCRIPT_FUNCTIONS"
	_cd $CURR

	if test "$HAS_CACHE" = "function"; then
		_cache RKSCRIPT_FUNCTIONS "$RKSCRIPT_FUNCTIONS"
	fi
}


#--
# Save value as $name.nfo (in $RKSCRIPT_DIR/$APP).
#
# @param string name (required)
# @param string value
#--
function _set {
	local DIR="$RKSCRIPT_DIR/"`basename "$APP"`

	test -d "$DIR" || _mkdir "$DIR"
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$DIR/$1.nfo"
}


#--
# Show list with $linebreak entries per line.
#
# @param list
# @param linebreak
# @param label (optional)
# @require _label
#--
function _show_list {
	local i=0
	local a=

	if ! test -z "$3"; then
		echo ""
		_label "$3"
	fi

	for a in $1
	do
		i=$(($i+1))
		echo -n "$a "

		n=$(($i%$2))
		if test "$n" = "0"; then
			echo ""
		fi
	done

	echo ""
}

#--
# Load sql dump $1 (ask). Based on rks-db_connect - implement custom _sql_load if missing.
# If flag=1 load dump without confirmation.
#
# @param sql dump
# @param flag
# @require _require_program _require_file _confirm
#--
function _sql_load {
	_require_program "rks-db_connect"
	_require_file "$1"

	test "$2" = "1" && AUTOCONFIRM=y
	_confirm "load sql dump '$1'?" 1
	test "$CONFIRM" = "y" && rks-db_connect load "$1" --q1=n --q2=y
}

_SQL=
declare -A _SQL_QUERY
declare -A _SQL_PARAM

#--
# Run sql select or execute query. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=select print result of select query. If $1=execute ask if query $2 should
# be execute (default=y) or skip. Set _SQL (default _SQL="rks-db_connect query") and
# _SQL_QUERY (optional).
#
# @global _SQL _SQL_QUERY (hash) _SQL_PARAM (hash)
# @export SQL (=rks-db_connect query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @require _abort _confirm
#--
function _sql {
	if test -z "$_SQL"; then
		if test -s "/usr/local/bin/rks-db_connect"; then
			_SQL='rks-db_connect query'
		else
			_abort "set _SQL="
		fi
	fi

	local QUERY="$2"
	if ! test -z "${_SQL_QUERY[$2]}"; then
		QUERY="${_SQL_QUERY[$2]}"
		local a=

		for a in "${!_SQL_PARAM[@]}"; do
			QUERY="${QUERY//\'$a\'/\'${_SQL_PARAM[$a]}\'}"
		done
	fi

	test -z "$QUERY" && _abort "empty query in _sql $1"

	if test "$1" = "select"; then
		$_SQL "$QUERY" | tail -1
	elif test "$1" = "execute"; then
		if test "$3" = "1"; then
			echo "execute sql query: ${QUERY:0:20} ..."
			$_SQL "$QUERY"
		else
			_confirm "execute sql query: ${QUERY:0:20} ... ? " 1
			test "$CONFIRM" = "y" && $_SQL "$QUERY"
		fi
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute"
	fi
}


#--
# Execute sql transaction. Use $1 as sql dump directory. 
# If $1/tables.txt exists load table list (sorted in create order) or autodetect ($1/prefix_*.sql). 
# Parameter $2 is action flag (2^n): 1=drop, 2=create, 4=alter, 8=insert, 16=update, 32=autoexec.
# Action dump files are either $1/alter|insert|update.sql or $1/alter|insert|update/table.sql.
# If not autoexec ask before every action.
#
# @param string directory name 
# @param int flag 
# @require _sql_load _require_dir _confirm _cp
#--
function _sql_transaction {
	local FLAG=$(($2 + 0))
	local SQL_DIR="$1"
	local ST="START TRANSACTION;"
	local ET="COMMIT;"
	local SQL_DUMP
	local TABLES
	local ACF
	local i

	_require_dir "$SQL_DIR"
	_mkdir "$RKSCRIPT_DIR/sql_transaction" >/dev/null

	if test -s "$SQL_DIR/tables.txt"; then
		TABLES=( `cat "$SQL_DIR/tables.txt"` )
	else
		TABLES=( `ls "$SQL_DIR/"*_*.sql | sed -E 's/^.+?\/([a-z0-9_]+)\.sql$/\1/i'` )
		ST="$ST\nSET FOREIGN_KEY_CHECKS=0;"
		ET="SET FOREIGN_KEY_CHECKS=1;\n$ET"
	fi

	test ${#TABLES[@]} -lt 1 && _abort "table list is empty"
	test $((FLAG & 32)) -eq 32 && ACF=y

	if test $((FLAG & 1)) -eq 1; then	
		SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/drop.sql"
		echo -e "$ST\n" >$SQL_DUMP
		for ((i = ${#TABLES[@]} - 1; i > -1; i--)); do
			echo "DROP TABLE IF EXISTS ${TABLES[$i]};" >>$SQL_DUMP
		done 
		echo -e "\n$ET" >>$SQL_DUMP

		AUTOCONFIRM=$ACF
		_confirm "Drop ${#TABLES[@]} tables (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi

	if test $((FLAG & 2)) -eq 2; then	
		SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/create.sql"
		echo -e "$ST\n" >$SQL_DUMP
		for ((i = 0; i < ${#TABLES[@]}; i++)); do
			cat "$SQL_DIR/${TABLES[$i]}.sql" >>$SQL_DUMP
		done
		echo -e "\n$ET" >>$SQL_DUMP

		AUTOCONFIRM=$ACF
		_confirm "Create tables (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi

	test $((FLAG & 4)) -eq 4 && _sql_transaction_load "$SQL_DIR" alter $ACF
	test $((FLAG & 8)) -eq 8 && _sql_transaction_load "$SQL_DIR" update $ACF
	test $((FLAG & 16)) -eq 16 && _sql_transaction_load "$SQL_DIR" insert $ACF
}


#--
# Helper function. Load $1.
#
# @parma sql directory path
# @param name (alter|insert|update)
# @param autoconfirm
# @require _rm _cp _confirm _sql_load
#--
function _sql_transaction_load {
	local SQL_DUMP="$RKSCRIPT_DIR/sql_transaction/$2.sql"
	_rm "$SQL_DUMP" >/dev/null

	if test -s "$1/$2.sql"; then
		_cp "$1/$2.sql" "$SQL_DUMP"
	elif test -d "$1/$2"; then
		cat "$1/$2/*.sql" > "$SQL_DUMP"
	fi

	if test -s "$SQL_DUMP"; then
		AUTOCONFIRM=$3
		_confirm "Execute $2 queries (load $SQL_DUMP)?"
		test "$CONFIRM" = "y" && _sql_load "$SQL_DUMP" 1
	fi
}


#--
# Copy content from www_src to www.  and *.js files from src/javascript.
#
# @global SRC2WWW_FILES SRC2WWW_DIR SRC2WWW_RKJS_DIR SRC2WWW_RKJS_FILES
# @require _require_global
#--
function _src2www_copy {

	local a=; for a in $SRC2WWW_FILES $SRC2WWW_DIR; do
		cp -r www_src/$a www/
	done

	if ! test -z "$SRC2WWW_RKJS_FILES"; then
		_require_global "SRC2WWW_RKJS_DIR"
		for a in $SRC2WWW_RKJS_FILES; do
			cp $SRC2WWW_RKJS_DIR/$a www/js/
		done
	fi
}


#--
# Update www/index.html. Concat files from www_src directory in this order:
#
# - header.html, app_header.html?, main.html, app_footer.html?, *.inc.html
# - if main.js exists append hidden div#app_main with main.html and script block
#		with main.js
#	- footer.html
#
#--
function _src2www_index {

	cp www_src/header.html www/index.html

	if test -f www_src/app_header.html; then
		cat www_src/app_header.html >> www/index.html
	fi

	cat www_src/main.html >> www/index.html

	if test -f www_src/app_footer.html; then
		cat www_src/app_footer.html >> www/index.html
	fi

	local a=; for a in www_src/*.inc.html; do
		cat $a >> www/index.html
	done

	if test -f www_src/main.js; then
		echo '<div id="app_main" style="display:none">' >> www/index.html
		cat www_src/main.html >> www/index.html
		echo '</div><script>' >> www/index.html
		cat www_src/main.js >> www/index.html
		echo '</script>' >> www/index.html
	fi

	cat www_src/footer.html >> www/index.html
}


#--
# Create ssh key authentication for server $1 (rk@server.tld).
#--
function _ssh_auth {
	echo "create ssh keys for password less authentication"

	if ! test -f ~/.ssh/id_rsa.pub; then
		echo "creating local public+private key: ~/.ssh/id_rsa[.pub] - type 3x ENTER"
		ssh-keygen -t rsa
	fi

	local SSH_OK=`ssh -o 'PreferredAuthentications=publickey' $1 "echo" 2>&1`

	if ! test -z "$SSH_OK"; then
		echo "copy ~/.ssh/id_rsa.pub to $1"

		if test -d /Applications/iTunes.app; then
			./macos/ssh-copy-id.sh -i ~/.ssh/id_rsa.pub $1
		else
			# assume linux
			ssh-copy-id -i ~/.ssh/id_rsa.pub $1
		fi
	fi
}


#--
# Stop webserver (apache2, nginx) on port 80 if running.
# Ignore docker webservice on port 80.
#
# @require _is_running _os_type
# @os linux
#--
function _stop_http {
	_os_type linux

	if ! _is_running PORT 80; then
		echo "no service on port 80"
		return
	fi

	if _is_running DOCKER_PORT_80; then
		echo "ignore docker service on port 80"
		return
	fi

	if _is_running NGINX; then
		echo "stop nginx"
		sudo service nginx stop
		return
	fi

	if _is_running APACHE2; then
		echo "stop apache2"
		sudo service apache2 stop
		return
	fi
}


#--
# Switch to sudo mode. Switch back after command is executed.
# 
# @param command
# @param optional flag (1=try sudo if normal command failed)
# @require _abort _log
#--
function _sudo {
	local CURR_SUDO=$SUDO

	# ToDo: unescape $1 to avoid eval. Example: use [$EXEC] instead of [eval "$EXEC"]
	# and [_sudo "cp 'a' 'b'"] will execute [cp "'a'" "'b'"].
	local EXEC="$1"

	# change $2 into number
	local FLAG=$(($2 + 0))

	if test "$USER" = "root"; then
		_log "$EXEC" sudo
		eval "$EXEC ${LOG_CMD[sudo]}" || _abort "$EXEC"
	elif test $((FLAG & 1)) = 1 && test -z "$CURR_SUDO"; then
		_log "$EXEC" sudo
		eval "$EXEC ${LOG_CMD[sudo]}" || \
			( echo "try sudo $EXEC"; eval "sudo $EXEC ${LOG_CMD[sudo]}" || _abort "sudo $EXEC" )
	else
		SUDO=sudo
		_log "sudo $EXEC" sudo
		eval "sudo $EXEC ${LOG_CMD[sudo]}" || _abort "sudo $EXEC"
		SUDO=$CURR_SUDO
	fi
}


#--
# Create php file with includes from source directory.
#
# @param source directory
# @param output file
# @global PATH_RKPHPLIB
# @require _require_global
#--
function _syntax_check_php {
	local PHP_FILES=`find "$1" -type f -name '*.php'`
	local PHP_BIN=`grep -R -E '^#\!/usr/bin/php' "bin" | grep -v 'php -c skip_syntax_check' | sed -E 's/\:\#\!.+//'`

	_require_global PATH_RKPHPLIB

	echo -e "<?php\n\ndefine('APP_HELP', 'quiet');\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');\n" > "$2"
	echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;" >> "$2"
	echo -n '  print "ok\n";' >> "$2"
	echo -e "\n}\n" >> "$2"

	for a in $PHP_FILES $PHP_BIN
	do
		local SKIP=`head -1 "$a" | grep 'php -c skip_syntax_check'`
	
		if test -z "$SKIP"; then
			echo "_syntax_test('$a');" >> "$2"
		fi
	done
}


#--
# Abort with SYNTAX: message.
# Usually APP=$0
#
# @global APP APP_DESC $APP_PREFIX
# @param message
#--
function _syntax {
	if ! test -z "$APP_PREFIX"; then
		echo -e "\nSYNTAX: $APP_PREFIX $APP $1\n" 1>&2
	else
		echo -e "\nSYNTAX: $APP $1\n" 1>&2
	fi

	if ! test -z "$APP_DESC"; then
		echo -e "$APP_DESC\n\n" 1>&2
	else
		echo 1>&2
	fi

	exit 1
}


#--
# Run test.
#--
function _test {
	if test -f "test/run.php"; then
		php test/run.php
	fi
}


#--
# Return lowercase text. 
#
# @param string txt
#--
function _tolower {
	printf '%s\n' "$1" | awk '{ print tolower($0) }'
}

#--
# Return uppercase text. 
#
# @param string txt
#--
function _toupper {
	printf '%s\n' "$1" | awk '{ print toupper($0) }'
}

#--
# Print trimmed string. 
#
# @param string name
#--
function _trim {
	echo -e "$1" | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'
}

#--
# Link /bin/sh to /bin/shell.
#
# @abort
# @require _abort _ln _cd _rm
# @param abort message
#--
function _use_shell {
	test -L "/bin/sh" || _abort "no /bin/sh link"
	test -f "/bin/$1" || _abort "no such shell /bin/$1"

	local USE_SHELL=`diff -u /bin/sh /bin/$1`
	local CURR="$PWD"

	if ! test -z "$USE_SHELL"; then
		_rm /bin/sh
		_cd /bin
		_ln "$1" sh
		_cd "$CURR" 
	fi
}


#--
# Convert nn.mm.kk into nnmmkk (with leading zeros) 
# e.g. 3.10.8 = 031008, 14.22.72 = 142272 
# 
# @param version number (nn.mm.kk)
# @print int
#--
function _ver3 {
	printf "%02d%02d%02d" $(echo "$1" | tr -d 'v' | tr '.' ' ')
}


#--
# Make directory $1 read|writeable for webserver.
#
# @param directory path
# @require _abort _chown _chmod
#--
function _webserver_rw_dir {
	test -d "$1" || _abort "no such directory $1"

	local DIR_OWNER=`stat -c '%U' "$1"`
	local SERVER_USER=

	if test -s "/etc/apache2/envvars"; then
		SERVER_USER=`cat /etc/apache2/envvars | grep -E '^export APACHE_RUN_USER=' | sed -E 's/.*APACHE_RUN_USER=//'`
	fi

	if ! test -z "$SERVER_USER" && test "$SERVER_USER" = "$DIR_OWNER"; then
		echo "directory $1 is already owned by webserver $SERVER_USER"
		return
	fi

	_chmod 770 "$1"

	local ME="$USER"
	test -z "$SUDO_USER" || ME="$SUDO_USER"

	_chown "$1" "$ME" "$SERVER_USER"
}


#--
# Download URL with wget. 
#
# @param url
# @param save as default = autodect, use "-" for stdout
# @require _abort _require_program _confirm
#--
function _wget {
	test -z "$1" && _abort "empty url"
	_require_program wget

	local SAVE_AS=${2:-`basename "$1"`}
	if test -s "$SAVE_AS"; then
		_confirm "Overwrite $SAVE_AS" 1
		if test "$CONFIRM" != "y"; then
			echo "keep $SAVE_AS - skip wget '$1'"
			return
		fi
	fi

	if test -z "$2"; then
		echo "download $1"
		wget -q "$1" || _abort "wget -q '$1'"
	elif test "$2" = "-"; then
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
		return
	else
		echo "download $1 as $2"
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
	fi

	if test -z "$2"; then
		if ! test -s "$SAVE_AS"; then
			local NEW_FILES=`find . -amin 1 -type f`
			test -z "$NEW_FILES" && _abort "Download from $1 failed"
		fi
	elif ! test -s "$2"; then
		_abort "Download of $2 from $1 failed"
	fi
}


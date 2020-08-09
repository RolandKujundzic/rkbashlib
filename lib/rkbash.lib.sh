#!/bin/bash

test -z "$RKBASH_VERSION" || return
RKBASH_VERSION=0.3

test -z "$APP" && APP="$0"
test -z "$APP_DIR" && APP_DIR=$( cd "$( dirname "$APP" )" >/dev/null 2>&1 && pwd )
test -z "$APP_PID" && export APP_PID="$$"
test -z "$CURR" && CURR="$PWD"


test -z "$RKBASH_DIR" && RKBASH_DIR="$HOME/.rkbash/$$"

if declare -A __hash=([key]=value) 2>/dev/null; then
	test "${__hash[key]}" = 'value' || { echo -e "\nERROR: declare -A\n"; exit 1; }
	unset __hash
else
	echo -e "\nERROR: declare -A\n"
	exit 1  
fi  

if test "${@: -1}" = 'help' 2>/dev/null; then
	for a in ps tr xargs head grep awk find sed sudo cd chown chmod mkdir rm ls; do
		command -v $a >/dev/null || { echo -e "\nERROR: missing $a\n"; exit 1; }
	done
fi

#--
# Abort with error message. Use NO_ABORT=1 for just warning output (return 1, export ABORT=1).
#
# @exit
# @global APP NO_ABORT
# @export ABORT
# @param string abort message|line number
# @param abort message (optional - use if $1 = line number)
# shellcheck disable=SC2034,SC2009
#--
function _abort {
	local msg line rf brf nf
	rf="\033[0;31m"
	brf="\033[1;31m"
	nf="\033[0m"

	msg="$1"
	if test -n "$2"; then
		msg="$2"
		line="[$1]"
	fi

	if test "$NO_ABORT" = 1; then
		ABORT=1
		echo "${rf}WARNING${line}: ${msg}${nf}"
		return 1
	fi

	msg="${rf}${msg}${nf}"

	local frame trace
	if type -t caller >/dev/null 2>/dev/null; then
		frame=0
		trace=$(while caller $frame; do ((frame++)); done)
		msg="$msg\n\n$trace"
	fi

	if [[ -n "$LOG_LAST" && -s "$LOG_LAST" ]]; then
		msg="$msg\n\n$(tail -n+5 "$LOG_LAST")"
	fi

	echo -e "\n${brf}ABORT${line}:${nf} $msg\n" 1>&2

	local other_pid=

	if test -n "$APP_PID"; then
		# make shure APP_PID dies
		for a in $APP_PID; do
			other_pid=$(ps aux | grep -E "^.+\\s+$a\\s+" | awk '{print $2}')
			test -z "$other_pid" || kill "$other_pid" 2>/dev/null 1>&2
		done
	fi

	if test -n "$APP"; then
		# make shure APP dies
		other_pid=$(ps aux | grep "$APP" | awk '{print $2}')
		test -z "$other_pid" || kill "$other_pid" 2>/dev/null 1>&2
	fi

	exit 1
}


#--
# Add linenumber to $1 after _abort if caller function does not exist.
#
# @param string file 
# @global RKBASH_DIR
#--
function _add_abort_linenum {
	local lines changes tmp_file fix_line
	type -t caller >/dev/null 2>/dev/null && return

	_mkdir "$RKBASH_DIR/add_abort_linenum"
	tmp_file="$RKBASH_DIR/add_abort_linenum/"$(basename "$1")
	test -f "$tmp_file" && _abort "$tmp_file already exists"

	echo -n "add line number to _abort in $1"
	changes=0

	readarray -t lines < "$1"
	for ((i = 0; i < ${#lines[@]}; i++)); do
		fix_line=$(echo "${lines[$i]}" | grep -E -e '(;| \|\|| &&) _abort ["'"']" -e '^\s*_abort ["'"']" | grep -vE -e '^\s*#' -e '^\s*function ')
		if test -z "$fix_line"; then
			echo "${lines[$i]}" >> "$tmp_file"
		else
			changes=$((changes+1))
			echo "${lines[$i]}" | sed -E 's/^(.*)_abort (.+)$/\1_abort '$((i+1))' \2/g' >> "$tmp_file"
		fi
	done

	echo " ($changes)"
	_cp "$tmp_file" "$1" >/dev/null
}


#--
# Create vhost link to $2. Create /website/... and docroot.
# Add $1 domain to /etc/hosts (if *.xx). 
#
# @param domain
# @param docroot
#--
function _apache2_vhost {
	if ! test -d "$2"; then
		_confirm "Create docroot '$2'?" 1
		test "$CONFIRM" = "y" && _mkdir "$2"
	fi

	_split '.' "$1" >/dev/null

	local a

	if test "${#SPLIT[@]}" -eq 2; then
		a="/website/${SPLIT[0]}"'_'"${SPLIT[1]}"
		_mkdir "$a"
		_cd "$a"
		_ln "$2" '_'
	else
		a="/website/${SPLIT[1]}"'_'"${SPLIT[2]}"
		_mkdir "$a"
		_cd "$a"
		_ln "$2" "${SPLIT[0]}"
	fi

	if test -n "$(echo "$1" | grep -E '\.xx$')"; then
		_msg "Add $1 domain to /etc/hosts"
		_append_txt /etc/hosts "127.0.0.1 $1"
	fi
}


#--
# Create apigen documentation for php project in docs/apigen.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/apigen)
# @global CURR
#--
function _apigen_doc {
	local doc_dir prj bin src_dir
  doc_dir=./docs/apigen
	prj="docs/.apigen"
	bin="$prj/vendor/apigen/apigen/bin/apigen"
	src_dir=./src

	_mkdir "$doc_dir"
	_mkdir "$prj"
	_require_program composer

	if ! test -f "$prj/composer.json"; then
		_cd "$prj"
		_composer_json "rklib/rkphplib_doc_apigen"
		composer require "apigen/apigen:dev-master"
		composer require "roave/better-reflection:dev-master#c87d856"
		_cd "$CURR"
	fi

	if ! test -s "$bin"; then
		_cd "$prj"
		composer update
		_cd "$CURR"
	fi

	test -n "$1" && src_dir="$1"
	test -n "$2" && doc_dir="$2"

	_require_dir "$src_dir"

	if test -d "$doc_dir"; then
		_confirm "Remove existing documentation directory [$doc_dir] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$doc_dir"
		fi
	fi

	echo "Create apigen documentation"
	echo "$bin generate '$src_dir' --destination '$doc_dir'"
	$bin generate "$src_dir" --destination "$doc_dir"
}


declare -A API_QUERY

#--
# Query $API_QUERY[url]/$1. Set $API_QUERY[log|out]. Abort if "query failed|no result".
#
# @param string query type curl|func|wget
# @param string query string
# @param hash query parameter
# @global API_QUERY RKBASH_DIR
# shellcheck disable=SC2154
#--
function _api_query {
	test -z "$1" && _abort "missing query type - use curl|func|wget"
	test -z "$2" && _abort "missing query string"

	local out_f log_f err_f
	out_f="$RKBASH_DIR/api_query.res"	
	log_f="$RKBASH_DIR/api_query.log"	
	err_f="$RKBASH_DIR/api_query.err"

	echo '' > "$out_f"

	API_QUERY[out]=
	API_QUERY[log]=

	if test "$1" = "wget"; then
		_msg "wget ${API_QUERY[url]}/$2"
		wget -q -O "$out_f" "${API_QUERY[url]}/$2" >"$log_f" 2>"$err_f" || _abort "wget failed"
		test -s "$out_f" || _abort "no result"
	else
		_abort "$1 api query not implemented"
	fi

	test -s "$out_f" && API_QUERY[out]=$(cat "$out_f")
	test -s "$log_f" && API_QUERY[log]=$(cat "$log_f")
	test -z "$err_f" || _abort "non-empty error log"
}


#--
# Append file $2 to file $1 if first 3 lines from $2 are not in $1.
#
# @param target file
# @param source file
#--
function _append_file {
	local found h3
	test -f "$2" || _abort "no such file [$2]"
	h3=$(head -3 "$2")

	test -s "$1" && found=$(grep "$h3" "$1")
	test -z "$found" || { _msg "$2 was already appended to $1"; return; }

	_msg "append file '$2' to '$1'"
	cat "$2" >> "$1" || _abort "cat '$2' >> '$1'"
}


#--
# @deprecated use _append_file
# @param target file
# @param source file
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
#--
function _append_txt {
	local dir found
	test -f "$1" && found=$(grep "$2" "$1")
	test -z "$found" || { _msg "$2 was already appended to $1"; return; }

	dir=$(dirname "$1")
	_mkdir "$dir"

	_msg "append text '$2' to '$1'"
	if ! test -f "$1" || test -w "$1"; then
		echo "append [$2] to [$1]"
		echo "$2" >> "$1" || _abort "echo '$2' >> '$1'"
	else
		echo "sudo append [$2] to [$1]"
		{ echo "$2" | sudo tee -a "$1" >/dev/null; } || _abort "echo '$2' | sudo tee -a '$1'"
	fi
}


#--
# Clean apt installation.
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
# @param $* (package list)
# @global LOG_NO_ECHO
# shellcheck disable=SC2048
#--
function _apt_install {
	local curr_lne
	curr_lne=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	_require_program apt
	_run_as_root 1
	_rkbash_dir

	for a in $*; do
		if test -d "$RKBASH_DIR/apt/$a"; then
			_msg "already installed, skip: apt -y install $a"
		else
			sudo apt -y install "$a" || _abort "apt -y install $a"
			_log "apt -y install $a" "apt/$a"
		fi
	done

	_rkbash_dir reset
	LOG_NO_ECHO=$curr_lne
}


#--
# Remove (purge) apt packages.
#
# @param $* package list
# @global RKBASH_DIR
# shellcheck disable=SC2048
#--
function _apt_remove {
	_run_as_root

	for a in $*; do
		_confirm "Run apt -y remove --purge $a" 1
		if test "$CONFIRM" = "y"; then
			apt -y remove --purge "$a" || _abort "apt -y remove --purge $a"
			_rm "$RKBASH_DIR/apt/$a"
		fi
	done

	_apt_clean
}


#--
# Run apt update (+upgrade). Skip if run within last week.
# @param optional flag: 1 = run upgrade
# shellcheck disable=SC2024
#--
function _apt_update {
	_require_program apt
	local lu now

	_rkbash_dir apt
	lu="$RKBASH_DIR/last_update"
	now=$(date +%s)

	if [[ -f "$lu" && $(cat "$lu") -gt $((now - 3600 * 24 * 7)) ]]; then
		:
	else
		echo "$now" > "$lu" 

		_run_as_root 1
		echo -n "apt -y update &>$RKBASH_DIR/update.log ... "
		sudo apt -y update &>"$RKBASH_DIR/update.log" || _abort 'sudo apt -y update'
		echo "done"

		if test "$1" = 1; then
			echo -n "apt -y upgrade &>$RKBASH_DIR/upgrade.log  ... "
 			sudo apt -y upgrade &>"$RKBASH_DIR/upgrade.log" || _abort 'sudo apt -y upgrade'
			echo "done"
		fi
	fi

	_rkbash_dir reset
}


#--
# Ask question. Skip default answer with SPACE. Loop max. 3 times
# until answered if $3=1. Use ASK_DEFAULT=aK if answer selection 
# <a1|...|an> is used. Use AUTOCONFIRM=default to skip question
# if default answer is provided.
#
# @param string label
# @param default answer or answer selection
# @param bool required 1|[] (default empty)
# @global ASK_DEFAULT
# @export ANSWER
#--
function _ask {
	local allow default label recursion
	
	if test -z "$2"; then
		label="$1  "
	elif [[ "${2:0:1}" == "<" && "${2: -1}" == ">" ]]; then
		label="$1  $2  "
 		allow="|${2:1: -1}|"

		if test -n "$ASK_DEFAULT"; then
			default="$ASK_DEFAULT"
			label="$label [$default]"
			ASK_DEFAULT=
		fi
	else 
		label="$1  [$2]  "
 		default="$2"
	fi
	
	if [[ "$AUTOCONFIRM" = "default" && -n "$default" ]]; then
		ANSWER="$default"
		AUTOCONFIRM=
		return
	fi

	echo -n "$label"
	read -r

	if test "$REPLY" = " "; then
		ANSWER=
	elif [[ -z "$REPLY" && -n "$default" ]]; then
		ANSWER="$default"
	elif test -n "$allow"; then
		[[ "$allow" == *"|$REPLY|"* ]] && ANSWER="$REPLY" || ANSWER=
	else
		ANSWER="$REPLY"
	fi

	recursion="${4:-0}"
	if test -z "$ANSWER" && test "$recursion" -lt 3; then
		test "$recursion" -ge 2 && _abort "you failed to answer the question 3 times"
		recursion=$((recursion + 1))
		_ask "$1" "$2" "$3" "$recursion"
	fi

	[[ -z "$ANSWER" && "$1" = '1' ]] && _abort "you failed to answer the question"
}


#--
# Install Amazon AWS PHP SDK.
#--
function _aws {
	_composer
	_composer_pkg aws/aws-sdk-php
}


#--
# Backup (realpath) $1 as RKBASH_DIR/backup/$1
# Keep last n backups.
#
# @global RKBASH_DIR
# @param path
# @param keep (default = 5)
#--
function _backup_file {
	local i n path dir base backup backup_dir
	path="$(realpath "$1")"
	test -z "$path" && _abort "no such file '$1'"

	dir="$(dirname "$path")"
	base="$(basename "$path")"
	backup_dir="$(dirname "$RKBASH_DIR")/backup/$dir"
	backup="$backup_dir/$base"
	n="${2:-5}"

	_msg "backup $path"
	_mkdir "$backup_dir"

	test -f "$backup" && _cp "$backup" "$backup.old" >/dev/null

	_cp "$path" "$backup" md5

	if [[ "$CP_FIRST" = '1' || "$CP_KEEP" = '1' ]]; then
		test -f "$backup.old" && _rm "$backup.old" >/dev/null
		return
	fi

	for ((i = n - 1; i > 0; i--)); do
		test -f "$backup.$i" && _cp "$backup.$i" "$backup.$((i + 1))"
	done

	_mv "$backup.old" "$backup.1"
}


test -z "$CACHE_DIR" && CACHE_DIR="$HOME/.rkbash/cache"
test -z "$CACHE_REF" && CACHE_REF="sh/run ../rkbash/src"
CACHE_OFF=
CACHE=

#--
# Load $1 from cache. If $2 is set update cache value first. Compare last 
# modification of cache file $CACHE_DIR/$1 with sh/run and ../rkbash/src.
# Export CACHE_OFF=1 to disable cache. Disable cache if bash version is 4.3.*.
# Use CACHE_DIR/$1.sh as cache. Use last modification of entries in CACHE_REF
# for cache invalidation.
#
# @param variable name
# @param variable value
# @global CACHE_OFF (default=empty) CACHE_DIR (=$HOME/.rkbash/cache) CACHE_REF (=sh/run ../rkbash/src)
# @export CACHE CACHE_FILE
# @return bool
# shellcheck disable=SC2034
#--
function _cache {
	CACHE_FILE=
	CACHE=

	test -z "$CACHE_OFF" || return 1
	local a key prefix cdir cache_lm entry_lm

	# $1 = abc.xyz.uvw -> prefix=abc key=xyz.uvw
	key="${1#*.}"
	prefix="${1%%.*}"
	cdir="$CACHE_DIR/$prefix"
	test "$prefix" = "$key" && { prefix=""; cdir="$CACHE_DIR"; }

	CACHE_FILE="$cdir/$key"
	_mkdir "$cdir"

	# if pameter $2 is set update CACHE_FILE
	test -z "${2+x}" || echo "$2" > "$CACHE_FILE"

	cache_lm=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
	test -z "$cache_lm" && return 1

	for a in $CACHE_REF; do
		entry_lm=$(stat -c %Y "$a" 2>/dev/null || _abort "invalid CACHE_REF entry '$a'")
		test "$cache_lm" -lt "$entry_lm" && return 1
	done

	CACHE=$(cat "$CACHE_FILE")
	return 0
}


#--
# Download source url to target path. 
# Export CDN_HTML to save <script ... and <link ... to ./CDN_HTML 
#
# @global CDN_HTML
# @param string source url
# @param string target path
# shellcheck disable=SC2046
#--
function _cdn_dl {
	_wget "$1" "$2"

	if test -n "$CDN_HTML"; then
		if grep -q "\"$2\"" -- *.html; then
			:
		elif [[ ! "$CDN_HTML" =~ \.html$ ]]; then
			_abort "invalid CDN_HTML=$CDN_HTML"
		elif [[ "$2" =~ \.css$ ]]; then
			echo "<link rel=\"stylesheet\" href=\"$2\" />" >> "$CDN_HTML"
		elif [[ "$2" =~ \.js$ ]]; then
			echo "<script src=\"$2\"></script>" >> "$CDN_HTML"
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
#--
function _cd {
	local has_realpath curr_dir goto_dir
	has_realpath=$(command -v realpath)

	if [[ -n "$has_realpath" && -n "$1" ]]; then
		curr_dir=$(realpath "$PWD")
		goto_dir=$(realpath "$1")

		if test "$curr_dir" = "$goto_dir"; then
			return
		fi
	fi

	if test -z "$2"; then
		echo "cd '$1'"
	fi

	if test -z "$1"; then
		if test -n "$LAST_DIR"; then
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

	if [[ "$UID" = "0" ]]; then
		if test -L "$le_live" || test -L "$le_live/fullchain.pem"; then
			CERT_FULL="$le_live/fullchain.pem"
			CERT_KEY="$le_live/privkey.pem"
			CERT_PUB="$le_live/cert.pem"
			CERT_CA="$le_live/chain.pem"
			res=0
		elif test -s "$le_acme/fullchain.pem"; then
			CERT_FULL="$le_acme/fullchain.pem"
			CERT_KEY="$le_acme/privkey.pem"
			CERT_PUB="$le_acme/cert.pem"
			CERT_CA="$le_acme/chain.pem"
			res=0
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


#--
# Abort if ssl certificate is missing or does not contain subdomain.
#
# @param string domain|path/to/fullchain.pem
# @export CERT_DNS CERT_GMT CERT_DOMAIN CERT_DOMAINS CERT_ISSUER CERT_UNTIL CERT_FULL
# @param string subdomain list (optional)
# shellcheck disable=SC2119,SC2034
#--
function _cert_info {
	local domain

	if test -f "$1"; then
		CERT_FULL="$1"
	else
		_cert_file "$1"
		domain="$1"
		test -z "$CERT_SUB" || domain="$CERT_SUB"
	fi

	local certinfo dns
	certinfo=$(openssl x509 -text -noout -in "$CERT_FULL")
	dns=$(openssl x509 -in "$CERT_FULL" -text | grep "DNS:" | sed -E -e 's/,? ?DNS\:/ /g' | _trim)

	test -z "$domain" && domain=$(echo "$certinfo" | grep -E -o 'CN = .+' | grep -v 'Encrypt Authority' | sed 's/CN = //')
	test -z "$domain" && domain=$(echo "$certinfo" | grep -E -o 'Subject\: CN=.+' | sed 's/Subject: CN=//')
	
	CERT_DOMAIN="$domain"
	CERT_ISSUER=$(echo "$certinfo" | grep 'Issuer:' | sed -E 's/.+O = (.+), CN =.+/\1/')
	CERT_GMT=$(echo "$certinfo" | grep "GMT" | _trim)
	CERT_DNS=$(echo "$certinfo" | grep "DNS:" | _trim)
	CERT_UNTIL=$(echo "$certinfo" | grep "GMT" | grep -o -E 'Not After .+' | sed -E -e 's/.+\: (.+ GMT).*/\1/i') 
	CERT_DOMAINS="$dns"

	[[ "$CERT_DNS" =~ DNS:*.$domain ]] && return
	[[ "$CERT_DNS" =~ DNS:$domain ]] || _abort "missing domain $domain in $CERT_FULL"

	for a in $2; do
		[[ "$CERT_DNS" =~ DNS:$a.$domain ]] || _abort "missing domain $a.$domain in $CERT_FULL"
	done
}


#--
# Change old_login into new_login. If login is same or both exist do nothing.
#
# @param user
# @param fullname
#--
function _change_fullname {
	[[ -z "$1" || -z "$2" ]] && return
	
	_run_as_root
	_require_file '/etc/passwd'
	_require_program chfn
	_require_program getent
	_require_program cut

	local fullname
	fullname=$(getent passwd "$1" | cut -d ':' -f 5 | cut -d ',' -f 1)
	test "$2" = "$fullname" && return

	_msg "Change full name of $1 to $2"
	chfn -f "$2" "$1" || _abort "chfn -f '$2' '$1'"
}


#--
# Change hostname if hostname != $1.
#
# @param hostname
#--
function _change_hostname {
	local new_hname curr_hname
	new_hname="$1"
	test -z "$new_hname" && return

	_run_as_root
	_require_program hostname
	curr_hname=$(hostname)
	test "$new_hname" = "$curr_hname" && return

	_require_program hostnamectl
	_msg "change hostname '$curr_hname' to '$new_hname'"
	hostnamectl set-hostname "$new_hname" || _abort "hostnamectl set-hostname '$new_hname'"
}


#--
# Change old_login into new_login. If login is same or both exist do nothing.
# Change home directory and group (if old group name = old_login). 
#
# @param old_login
# @param new_login
#--
function _change_login {
	local old new has_new has_old old_gname
	old="$1"
	new="$2"
	test "$old" = "$new" && return

	_run_as_root
	_require_file '/etc/passwd'

	has_new=$(grep -E "^$new:" '/etc/passwd')
	test -z "$has_new" || return

	has_old=$(grep -E "^$old:" '/etc/passwd')
	test -z "$has_old" && _abort "no such user $old"

	old_gname=$(id -g -n "$old")

	killall -u username

	_require_program usermod
	_require_program groupmod

	if usermod -l "$new" "$old"; then
		_msg "changed login '$old' to '$new'"
	else
		_abort "usermod -l '$new' '$old'"
	fi

	if test "$old_gname" = "$old" && groupmod --new-name "$new" "$old"; then
		_msg "changed group '$old' to '$new'"
	else
		_abort "groupmod --new-name '$new' '$old'"
	fi

	if [[ -d "/home/$old" && ! -d "/home/$new" ]]; then
		usermod -d "/home/$new" -m "$new" || _abort "usermod -d '/home/$new' -m '$new'"
		_msg "moved '/home/$old' to '/home/$new'"
	fi
}


#--
# Change password $2 of user $1 if crypted password $3 is not used.
#
# @param user
# @param password
# shellcheck disable=SC2016
#--
function _change_password {
	[[ -z "$1" || -z "$2" ]] && return

	_run_as_root
	_require_file '/etc/shadow'
	_require_program 'getent'

	local salt epass match
	salt=$(getent shadow "$1" | cut -d'$' -f3)
	epass=$(getent shadow "$1" | cut -d':' -f2)
	match=$(python -c 'import crypt; print crypt.crypt("'"$2"'", "$6$'"$salt"'")')

	test "${match}" = "${epass}" && return

	_require_program 'chpasswd'
	_msg "change $1 password"
	{ echo "$1:$2" | chpasswd; } || _abort "password change failed for '$1'"
}


#--
# Abort if ip_address of domain does not point to IP_ADDRESS.
# Call _ip_address first. Skip if CHECK_IP_OFF=1.
#
# @global IP_ADDRESS CHECK_IP_OFF
# @param domain
#--
function _check_ip {
	test "$CHECK_IP_OFF" = '1' && return
	local ip_ok ping4
	_require_program ping

	if ping -4 -c1 localhost &>/dev/null; then
		ping4="ping -4 -c 1"
	else
		ping4="ping -c 1"
	fi

	ip_ok=$($ping4 "$1" 2> /dev/null | grep "$IP_ADDRESS")
	test -z "$ip_ok" && _abort "$1 does not point to server ip $IP_ADDRESS"
}


#--
# Print ssl public key status of /etc/letsencrypt/live/$1/fullchain.pem.
# 
# @export ENDDATE
# @param string domain
# @param string min days (default = 14)
# @print valid, missing or expired
#--
function _check_ssl {
	if ! _cert_file "$1" 0; then
		echo 'missing'
		return
	fi

	local min_days
	min_days="${2:-14}"

	ENDDATE=$(openssl x509 -enddate -noout -in "$CERT_FULL")
	export ENDDATE=${ENDDATE:9}

	php -r 'print strtotime(getenv("ENDDATE")) > time() + 3600 * 24 * '"$min_days"' ? "valid" : "expired";'
}


#--
# Change file+directory privileges recursive.
#
# @param path/to/entry
# @param file privileges (default = 644)
# @param dir privileges (default = 755)
# @param main dir privileges (default = dir privleges)
#--
function _chmod_df {
	local chmod_path fpriv dpriv mdpriv
	chmod_path="$1"
	fpriv="$2"
	dpriv="$3"
	mdpriv="$4"

	if [[ ! -d "$chmod_path" && ! -f "$chmod_path" ]]; then
		_abort "no such directory or file: [$chmod_path]"
	fi

	test -z "$fpriv" && fpriv=644
	test -z "$dpriv" && dpriv=755

	_file_priv "$chmod_path" $fpriv
	_dir_priv "$chmod_path" $dpriv

	if [[ -n "$mdpriv" && "$mdpriv" != "$dpriv" ]]; then
		echo "chmod $mdpriv '$chmod_path'"
		chmod "$mdpriv" "$chmod_path" || _abort "chmod $mdpriv '$chmod_path'"
	fi
}


#--
# Change mode of path $2 to $1. If chmod failed try sudo.
# Use _find first to chmod all FOUND entries.
#
# @param file mode (octal)
# @param file path (if path is empty use $FOUND)
# global CHMOD (default chmod -R)
# shellcheck disable=SC2006
#--
function _chmod {
	local tmp cmd i priv
	test -z "$1" && _abort "empty privileges parameter"
	test -z "$2" && _abort "empty path"

	tmp=$(echo "$1" | sed -E 's/[012345678]*//')
	test -z "$tmp" || _abort "invalid octal privileges '$1'"

	cmd="chmod -R"
	if test -n "$CHMOD"; then
		cmd="$CHMOD"
		CHMOD=
	fi

	if test -z "$2"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			priv=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				priv=`stat -c "%a" "${FOUND[$i]}"`
			fi

			if test "$1" != "$priv" && test "$1" != "0$priv"; then
				_sudo "$cmd $1 '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$2"; then
		priv=`stat -c "%a" "$2"`

		if [[ "$1" != "$priv" && "$1" != "0$priv" ]]; then
			_sudo "$cmd $1 '$2'" 1
		fi
	elif test -d "$2"; then
		# no stat compare because subdir entry may have changed
		_sudo "$cmd $1 '$2'" 1
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
#--
function _chown {
	local cmd modify curr_owner curr_group has_group me

	if [[ -z "$2" || -z "$3" ]]; then
		_abort "owner [$2] or group [$3] is empty"
	fi

	_require_program stat

	local cmd="chown -R"
	if test -n "$CHOWN"; then
		cmd="$CHOWN"
		CHOWN=
	fi

	if test -z "$1"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			curr_owner=
			curr_group=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				curr_owner=$(stat -c '%U' "${FOUND[$i]}")
				curr_group=$(stat -c '%G' "${FOUND[$i]}")
			fi

			if test "$curr_owner" != "$2" || test "$curr_group" != "$3"; then
				_sudo "$cmd '$2.$3' '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$1"; then
		curr_owner=$(stat -c '%U' "$1")
		curr_group=$(stat -c '%G' "$1")

		[[ -z "$curr_owner" || -z "$curr_group" ]] && _abort "stat owner [$curr_owner] or group [$curr_group] of [$1] failed"
		[[ "$curr_owner" != "$2" || "$curr_group" != "$3" ]] && modify=1
	elif test -d "$1"; then
		# no stat compare because subdir entry may have changed
		modify=1
	fi

	test -z "$modify" && return

	me=$(basename "$HOME")
	if test "$me" = "$2"; then
		has_group=$(groups "$me" | grep " $3 ")
		if test -n "$has_group"; then
			_msg "$cmd $2.$3 '$1'"
			$cmd "$2.$3" "$1" 2>/dev/null && return
			_msg "$cmd '$2.$3' '$1' failed - try as root"
		fi
	fi

	_sudo "$cmd '$2.$3' '$1'" 1
}


#--
# Execute command $1.
#
# @param command
# @param 2^n flag (2^0= no echo, 2^1= print output)
#--
function _cmd {
	# @ToDo unescape $1 to avoid eval
	local exec flag curr_log_no_echo
	exec="$1"
	flag=$(($2 + 0))
	curr_log_no_echo=$LOG_NO_ECHO

	test $((flag & 1)) = 1 && LOG_NO_ECHO=1

	_log "$exec" cmd
	eval "$exec ${LOG_CMD[cmd]}" || _abort "command failed"
	
	if test $((flag & 2)) = 2; then
		tail -n +5 "${LOG_FILE[cmd]}"
	else
		echo "ok"
	fi

	LOG_NO_ECHO=$curr_log_no_echo
}


#--
# Create composer.json
#
# @param package name e.g. rklib/test
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
# shellcheck disable=SC2046
#--
function _composer_phar {
	local expected_sig actual_sig install_as sudo result
	expected_sig="$(_wget "https://composer.github.io/installer.sig" -)"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	actual_sig="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if test "$expected_sig" != "$actual_sig"; then
    _rm composer-setup.php
    _abort 'Invalid installer signature'
  fi

	install_as="$1"
	sudo='sudo'

	if test -z "$install_as"; then
		install_as="./composer.phar"
		sudo=
	fi

  $sudo php composer-setup.php --quiet --install-dir=$(dirname "$install_as") --filename=$(basename "$install_as")
	result=$?

	if ! test "$result" = "0" || ! test -s "$install_as"; then
		_abort "composer installation failed"
	fi

	_rm composer-setup.php
}


#--
# Install php package with composer. Target directory is vendor/$1
#
# @param composer-vendor-directory
# shellcheck disable=SC2046
#--
function _composer_pkg {
	if ! test -f composer.phar; then
		_abort "Install composer first"
	fi

	if [[ -d "vendor/$1" && -f composer.json ]] && grep -q "$1" 'composer.json'; then
		echo "Update composer package $1 in vendor/"
		php composer.phar update "$1"
	else
		echo "Install composer package $1 in vendor/"
		php composer.phar require "$1"
	fi
}


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


#--
# Show "message  y [n]" (or $2 & 1: [y] n) and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 (3) sec expired. Use --q1=y and --q2=n call parameter to confirm
# question 1 and reject question 2. Set CONFIRM_COUNT= before _confirm if necessary.
# If AUTOCONFIRM is set (e.g. yyn) set CONFIRM=AUTOCONFIRM[0], shift AUTOCONFIRM left
# and return.
#
# @param string message
# @param 2^N flag 1=switch y and n (y = default, wait 3 sec) | 2=auto-confirm (y)
# @global AUTOCONFIRM --qN
# @export CONFIRM CONFIRM_TEXT
# shellcheck disable=SC2034
#--
function _confirm {
	local msg
	msg="\033[0;35m$1\033[0m"

	CONFIRM=

	if test -n "$AUTOCONFIRM"; then
		CONFIRM="${AUTOCONFIRM:0:1}"
		echo -e "$msg <$CONFIRM>"
		AUTOCONFIRM="${AUTOCONFIRM:1}"
		return
	fi

	if test -z "$CONFIRM_COUNT"; then
		CONFIRM_COUNT=1
	else
		CONFIRM_COUNT=$((CONFIRM_COUNT + 1))
	fi

	local flag cckey default

	flag=$(($2 + 0))

	if test $((flag & 2)) = 2; then
		if test $((flag & 1)) = 1; then
			CONFIRM=n
		else
			CONFIRM=y
		fi

		return
	fi

	while read -r -d $'\0' 
	do
		cckey="--q$CONFIRM_COUNT"
		if test "$REPLY" = "$cckey=y"; then
			echo "found $cckey=y, accept: $1" 
			CONFIRM=y
		elif test "$REPLY" = "$cckey=n"; then
			echo "found $cckey=n, reject: $1" 
			CONFIRM=n
		fi
	done < /proc/$$/cmdline

	if test -n "$CONFIRM"; then
		# found -y or -n parameter
		CONFIRM_TEXT="$CONFIRM"
		return
	fi

	if test $((flag & 1)) -ne 1; then
		default=n
		echo -n -e "$msg  y [n]  "
		read -r -n1 -t 10 CONFIRM
		echo
	else
		default=y
		echo -n -e "$msg  \033[0;35m[y]\033[0m n  "
		read -r -n1 -t 3 CONFIRM
		echo
	fi

	if test -z "$CONFIRM"; then
		CONFIRM="$default"
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
# shellcheck disable=SC2120
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
# shellcheck disable=SC2120
#--
function _cordova_add_ios {
	local os_type
	os_type=$(_os_type)

	if test "$os_type" != "macos"; then
		echo "os type = $os_type != macos - do not add cordova ios" 
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
# shellcheck disable=SC2119
#--
function _cordova_create {
	test -d "app/$1" && _abort "Cordova project app/$1 already exists"
	_mkdir app

	_cd app
	cordova create "$1"
	_cd "$1"

	local os_type
	os_type=$(_os_type)

	if "$os_type" = "linux"; then
		_cordova_add_android
		_mkdir www_src/patch/android
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/android/patch.sh
	elif "$os_type" = "macos"; then
		_cordova_add_ios
		_mkdir www_src/patch/ios
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/ios/patch.sh
	fi

	_cd ../..
}


#--
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @export CP_KEEP=1 if $3=md5 and target exists and is same as source
# export CP_FIRST=1 if $3=md5 and target does not exist
# @global SUDO
# shellcheck disable=SC2034
#--
function _cp {
	local curr_lno target_dir md1 md2 pdir
	curr_lno="$LOG_NO_ECHO"
	LOG_NO_ECHO=1

	CP_FIRST=
	CP_KEEP=

	test -z "$2" && _abort "empty target"

	target_dir=$(dirname "$2")
	test -d "$target_dir" || _abort "no such directory [$target_dir]"

	if test "$3" != 'md5'; then
		:
	elif ! test -f "$2"; then
		CP_FIRST=1
	elif test -f "$1"; then
		md1=$(_md5 "$1")
		md2=$(_md5 "$2")

		if test "$md1" = "$md2"; then
			_msg "_cp: keep $2 (same as $1)"
			CP_KEEP=1
		else
			_msg "Copy file $1 to $2 (update)"
			_sudo "cp '$1' '$2'" 1
		fi

		return
	fi

	if test -f "$1"; then
		_msg "Copy file $1 to $2"
		_sudo "cp '$1' '$2'" 1
	elif test -d "$1"; then
		if test -d "$2"; then
			pdir="$2"
			_confirm "Remove existing target directory '$2'?"
			if test "$CONFIRM" = "y"; then
				_rm "$pdir"
				_msg "Copy directory $1 to $2"
				_sudo "cp -r '$1' '$2'" 1
			else
				_msg "Copy directory $1 to $2 (use rsync)" 
				_rsync "$1/" "$2"
			fi
		else
			_msg "Copy directory $1 to $2"
			_sudo "cp -r '$1' '$2'" 1
		fi
	else
		_abort "No such file or directory [$1]"
	fi

	LOG_NO_ECHO="$curr_lno"
}


#--
# Create tgz archive $1 with files from file/directory list $2.
# If existing archive changed ask otherwise keep.
#
# @param tgz_file
# @param directory/file list
#--
function _create_tgz {
	test -z "$1" && _abort "Empty archive path"

	local a seconds
	for a in $2; do
		if ! test -f "$a" && ! test -d "$a"; then
			_abort "No such file or directory $a"
		fi
	done

	# compare existing archive
	if test -s "$1"; then	
		if tar -d --file="$1" "$2" >/dev/null 2>/dev/null; then
			return
		else
			_confirm "Update archive $1?" 1
			test "$CONFIRM" = "y" || _abort "user abort"
		fi
	fi

  _msg "create archive $1"
  seconds=0
  tar -czf "$1" "$2" >/dev/null 2>/dev/null || _abort "tar -czf '$1' $2 failed"
  _msg "$((seconds / 60)) minutes and $((seconds % 60)) seconds elapsed."

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "invalid archive '$1'"
}

	
#--
# Install user ($1) crontab ($2 $3).
#
# @param string user
# @param string repeat-time
# @param string command
#--
function _crontab {
	_msg "install '$1' crontab: [$2 $3] ... " -n
	_require_program crontab
	_mkdir '/var/spool/cron/crontabs'

	test "$(whoami)" = "$1" || _run_as_root

	if crontab -l -u "$1" 2>/dev/null | grep "$3" >/dev/null; then
		_msg "skip (already installed)"
		return
	fi

	if { crontab -l -u "$1" 2>/dev/null; echo "$2 $3"; } | crontab -u "$1" -; then
		_msg "ok"
	else
		_msg "failed"
		_abort "failed to add [$2 $3] to '$1' cron"
	fi
}


#--
# Decrypt $1. Second parameter is either empty (=ask password), password or password-file (basename starts with dot).
# If decrypted file is *.tgz archive extract it.
#
# @param encrypted file or archive
# @param password or password-file (optional, default = ask)
#--
function _decrypt {
	test -z "$1" && _abort "_decrypt: empty filepath"
	test -s "$1" || _abort "no such file '$1'"
	_require_program ccrypt

	local target pdir pbase pfile pass
	target=$(basename "$1" | sed -E 's/\.cpt$//')
	pdir=$(dirname "$1")

	if test -s "$target"; then
		_confirm "Overwrite existing file $pdir/$target?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if test -n "$2"; then
		pfile="$2"
		pbase=$(basename "$pfile")
		if test "${pbase:0:1}" = "." && test -s "$pfile"; then
			_msg "decrypt $1 (use password from $pfile)"
			pass=$(cat "$pfile")
		else
			_msg "decrypt $1 (use supplied password)"
		fi

		CCRYPT_PASS="$pass" ccrypt -f -E CCRYPT_PASS -d "$1" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -d '$1'"
	else
		_msg "decrypt $1 - Please input password"
		ccrypt -f -d "$1" || _abort "ccrypt -d '$1'"
	fi

	_require_file "$pdir/$target"

	if test "${target: -4}" = ".tgz"; then
		_extract_tgz "$pdir/$target"
		_rm "$pdir/$target" >/dev/null
	fi
}


#--
# Change directory privileges (recursive).
#
# @param directory
# @param privileges (default 755)
# @param options (default "! -path '/.*/'")
# shellcheck disable=SC2086
#--
function _dir_priv {
	_require_program realpath

	local dir priv msg find_opt

	dir=$(realpath "$1")
	test -d "$dir" || _abort "no such directory [$dir]"

	priv="$2"
	if test -z "$priv"; then
		priv=755
	else
		_is_integer "$priv"
	fi

	msg="chmod $priv directories in $1/"

	if test -z "$3"; then
    find_opt="! -path '/.*/'"
    msg="$msg ($find_opt)"
	else
    find_opt="$3"
    msg="$msg ($find_opt)"	
  fi

	_msg "$msg"
	find "$1" $find_opt -type d -exec chmod $priv {} \; || _abort "find '$1' $find_opt -type d -exec chmod $priv {} \;"
}


#--
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
#--
function _dl_unpack {
	if test -d "$1"; then
		_msg "Use existing unpacked directory $1"
		return
	fi

	local archive
	archive=$(basename "$2")

	if ! test -f "$archive"; then
		_msg "Download $2"
		_wget "$2"
	fi

	test -f "$archive" || _abort "missing $archive - $2 download failed"

	if test "${archive##*.}" = "zip"; then
		_msg "Unpack zip: unzip '$archive'"

		if test -z "$(unzip -l "$archive" | grep "$1\$")"; then
			_mkdir "$1"
			_cd "$1"
			unzip "../$archive" || _abort "unzip '../$archive'"
			_cd ..
		else
			unzip "$archive"
		fi
	else
		_msg "Unpack tar: tar -xf '$archive'"
		tar -xf "$archive" || _abort "tar -xf '$archive'"
	fi

	test -d "$1" || _mv "${archive%.*}" "$1"
}


#--
# Remove stopped docker container (if found).
#
# @param name
#--
function _docker_rm {
	_docker_stop "$1"

	if test -n "$(docker ps -a | grep "$1")"; then
		echo "docker rm $1"
		docker rm "$1"
	fi
}


#--
# Remove stopped docker container $1 (if found). Start docker container $1.
#
# @param name
# @param config file
# @global CURR WORKSPACE 
# shellcheck disable=SC2086
#--
function _docker_run {
	_docker_rm "$1"

	if [[ -n "$WORKSPACE" && -n "$CURR" && -d "$WORKSPACE/linux/rkdocker" ]]; then
		_cd "$WORKSPACE/linux/rkdocker"
	else
		_abort "Export WORKSPACE (where $WORKSPACE/linux/rkdocker exists) and CURR=path/current/directory"
	fi

	local config

	if test -f "$CURR/$2"; then
		config="$CURR/$2"
	elif test -f "$2"; then
		config="$2"
	else
		_abort "No such configuration $CURR/$2 ($PWD/$2)"
	fi
	
  echo "DOCKER_NAME=$1 ./run.sh $config start"
  DOCKER_NAME=$1 ./run.sh $2 start

	_cd "$CURR"
}


#--
# Stop running docker container (if found).
#
# @param name
#--
function _docker_stop {
	if test -n "$(docker ps | grep "$1")"; then
		echo "docker stop $1"
		docker stop "$1"
	fi
}


#--
# Encrypt file $1 (as $1.cpt) or directory (as $1.tgz.cpt). Remove source. 
# Second parameter is either empty (=ask password), password or password-file (basename must start with dot).
#
# @param file or directory path
# @param crypt key path (optional)
#--
function _encrypt {
	test -z "$1" && _abort "_encrypt: first parameter (path/to/source) missing"
	_require_program ccrypt

	local src pass base
	src="$1"
	pass="$2"
	base=$(basename "$2")

	if test -d "$1"; then
		src="$1.tgz"
		_create_tgz "$src" "$1"
	fi

	test -s "$src" || _abort "_encrypt: no such file [$src]"
	test -z "$(echo "$1" | grep -E '\.cpt$')" || _abort "$src has already suffix .cpt"
	
	if test -s "$src.cpt"; then
		_confirm "Overwrite existing $src.cpt?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if test -n "$pass"; then
		if test "${base:0:1}" = "." && test -s "$2"; then
			_msg "encrypt '$src' as *.cpt (use password from '$2')"
			pass=$(cat "$2")
		else
			_msg "encrypt '$src' as *.cpt (use supplied password)"
		fi

		CCRYPT_PASS="$pass" ccrypt -f -E CCRYPT_PASS -e "$src" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -e '$src'"
	else
		_msg "encrypt '$src' as *.cpt - Please input password"
		ccrypt -f -e "$src" || _abort "ccrypt -e '$src'"
	fi

	test -s "$src.cpt" || _abort "no such file $src.cpt"

	_rm "$src" >/dev/null
	if test -d "$1"; then
		_confirm "Remove source directory $1?" 1
		test "$CONFIRM" = "y" && _rm "$1" >/dev/null
	fi
}


#--
# Extract tgz archive $1. If second parameter is existing file or directory, 
# remove before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# global SECONDS
#--
function _extract_tgz {
	test -s "$1" || _abort "_extract_tgz: Invalid archive path [$1]"
	local target 
	target="$2"

	if [[ -z "$target" && "${1: -4}" = ".tgz" ]]; then
		target="${1:0:-4}"
	fi

	if [[ -n "$target" && -d "$target" ]]; then
		_rm "$target"
	fi

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "_extract_tgz: invalid archive '$1'"

  echo "extract archive $1"
  SECONDS=0
  tar -xzf "$1" >/dev/null || _abort "tar -xzf $1 failed"
  echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	if [[ -n "$target" && ! -d "$target" && ! -f "$target" ]]; then
		_abort "$target was not created"
	fi
}


#--
# Change file privileges for directory (recursiv). 
#
# @param directory
# @param privileges (default 644)
# @param options (default "! -path '.*/' ! -path 'bin/*' ! -name '.*' ! -name '*.sh'")
# shellcheck disable=SC2086
#--
function _file_priv {
	_require_program realpath
	local dir priv msg find_opt

	dir=$(realpath "$1")
	test -d "$dir" || _abort "no such directory [$dir]"

	priv="$2"
	if test -z "$priv"; then
		priv=644
	else
		_is_integer "$priv"
	fi

	msg="chmod $priv files in $1/"

	if test -z "$3"; then
		find_opt="! -path '/.*/' ! -path '/bin/*' ! -name '.*' ! -name '*.sh'"
		msg="$msg ($find_opt)"
	else
		find_opt="$3"
		msg="$msg ($find_opt)"
	fi

	_msg "$msg"
	find "$1" $find_opt -type f -exec chmod $priv {} \; || _abort "find '$1' $find_opt -type f -exec chmod $priv {} \;"
}


#--
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD (optional use $PWD as default)
# @param int don't abort if error (default = 0 = abort)
# @export DOCROOT
# @return bool (if $2=1)
#--
function _find_docroot {
	local dir base last_dir

	if test -n "$DOCROOT"; then
		DOCROOT=$(realpath "$DOCROOT")
		_msg "use existing DOCROOT=$DOCROOT"
		test -z "$DOCROOT" && { test -z "$2" && _abort "invalid DOCROOT" || return 1; }
		return 0
	fi

	if test -z "$1"; then
		dir=$(realpath "$PWD")
	else
		dir=$(realpath "$1")
	fi

	base=$(basename "$dir")
	test "$base" = "cms" && DOCROOT=$(dirname "$dir")

	if [[ -n "$DOCROOT" && -f "$DOCROOT/index.php" && (-f "$DOCROOT/settings.php" || -d "$DOCROOT/data") ]]; then
		_msg "use DOCROOT=$DOCROOT"
		return 0
	fi

	while [[ -d "$dir" && ! (-f "$dir/index.php" && (-f "$dir/settings.php" || -d "$dir/data")) ]]; do
		last_dir="$dir"
		dir=$(dirname "$dir")

		if test "$dir" = "$last_dir" || ! test -d "$dir"; then
			test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
		fi
	done

	if [[ -f "$dir/index.php" && (-f "$dir/settings.php" || -d "$dir/data") ]]; then
		DOCROOT="$dir"
	else
		test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
	fi

	return 0
}


#--
# Save found filesystem entries into FOUND.
#
# @param any paramter useable with find command
# @export FOUND Path Array
#--
function _find {
	FOUND=()
	local a=

	_require_program find

	while read -r a; do
		FOUND+=("$a")
	done <<< "$(find "$@" 2>/dev/null)"
}


#--
# Apply (perl) regular expression replace s/$2/$3/g on file $1
# @param regular expression
# @param file
#--
function _frx_replace {
	[[ -z "$2" ]] && _abort "invalid regular expression s/$2/$3/g"
	_require_program perl
	_require_file "$1"

	perl -i -pe "s/$2/$3/g" "$1"
}


#--
# Return saved value ($RKBASH_DIR/$APP/name.nfo).
#
# @param string name
# @global RKBASH_DIR
#--
function _get {
	local dir
	dir="$RKBASH_DIR"
	test "$dir" = "$HOME/.rkbash/$$" && dir="$HOME/.rkbash"
	dir="$dir/$(basename "$APP")"

	test -f "$dir/$1.nfo" || _abort "no such file $dir/$1.nfo"

	cat "$dir/$1.nfo"
}


#--
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
# For git parameter (e.g. [-b master --single-branch]) use global variable GIT_PARAMETER.
# Use ARG[docroot] to checkout into ARG[docroot] and link.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo test
#
# @param git url
# @param local directory (optional, default = basename $1 without .git)
# @param after_checkout (e.g. "./run.sh build")
# @global ARG[docroot] CONFIRM_CHECKOUT (if =1 use positive confirm if does not exist) GIT_PARAMETER
# shellcheck disable=SC2086
#--
function _git_checkout {
	local curr git_dir lnk_dir
	curr="$PWD"
	git_dir="${2:-$(basename "$1" | sed -E 's/\.git$//')}"

	if test -n "${ARG[docroot]}"; then
		lnk_dir="$2"
		git_dir="${ARG[docroot]}"

		if [[ -L "$lnk_dir" && "$(realpath "$lnk_dir")" = "$(realpath "$git_dir")" ]]; then
			_confirm "Update $git_dir (git pull)?" 1
		elif [[ ! -L "$lnk_dir" && ! -d "$lnk_dir" && ! -d "$git_dir" ]]; then
			_confirm "Checkout $1 to $git_dir (git clone)?" 1
		elif test -d "$git_dir"; then
			_abort "link to $git_dir missing ($lnk_dir)"
		elif test -L "$lnk_dir"; then
			_abort "$lnk_dir does not link to $git_dir"
		elif test -d "$lnk_dir"; then
			_abort "directory $lnk_dir already exists"
		fi
	elif test -d "$git_dir"; then
		_confirm "Update $git_dir (git pull)?" 1
	elif test -n "$CONFIRM_CHECKOUT"; then
		_confirm "Checkout $1 to $git_dir (git clone)?" 1
	fi

	if test "$CONFIRM" = "n"; then
		echo "Skip $1"
		return
	fi

	if test -d "$git_dir"; then
		_cd "$git_dir"
		echo "git pull $git_dir"
		git pull
		_git_submodule
		_cd "$curr"
	elif test -d "../../$git_dir/.git" && ! test -L "../../$git_dir"; then
		_ln "../../$git_dir" "$git_dir"
		_git_checkout "$1" "$git_dir"
	else
		echo -e "git clone $GIT_PARAMETER '$1' '$git_dir'\nEnter password if necessary"
		git clone $GIT_PARAMETER "$1" "$git_dir"

		if ! test -d "$git_dir/.git"; then
			_abort "git clone failed - no $git_dir/.git directory"
		fi

		if test -s "$git_dir/.gitmodules"; then
			_cd "$git_dir"
			_git_submodule
			_cd ..
		fi

		if test -n "$3"; then
			_cd "$git_dir"
			echo "run [$3] in $git_dir"
			$3
			_cd ..
		fi
	fi

	[[ -n "$lnk_dir" && ! -L "$lnk_dir" ]] && _ln "$git_dir" "$lnk_dir"

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
# shellcheck disable=SC2034
#--
function _github_latest {
	local vnum redir latest
	vnum=$($2 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/')
	redir=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")
	latest=$(basename "$redir" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+)\.?([0-9]*).*/\1\2/')

	if test -n "$latest"; then
		GITHUB_LATEST[$2]=$(basename "$redir")
		GITHUB_IS_LATEST[$2]=''

		if [[ -n "$vnum" && "$(echo "$vnum >= $latest" | bc -l)" == 1 ]]; then
			GITHUB_IS_LATEST[$2]=1
		fi
	fi
}


#--
# Update|Checkout submodule if .gitmodules exists
#--
function _git_submodule {
	test -s .gitmodules || return

	git submodule sync	# copy changes from .gitmodules to .git/config
	git submodule update --init --recursive --remote
	git submodule foreach "(git checkout master; git pull)"
}


#--
# Update git components in php/. Flag:
#
# 1: https://github.com/RolandKujundzic/rkphplib.git
#	2: rk@s1.dyn4.com:/data/git/php/phplib.git
# 4: sparse
#
# @param int flag (2^N, default=7)
#--
function _git_update_php {
	local flag version
	flag=$((${1:-7} + 0))

	_mkdir php
	_cd php

	# @ToDo $(_version php 2)
	version=8

	if test $((flag & 4)) -eq 4; then
		_require_program rks-git
		[[ $((flag & 1)) = 1 && ! -d rkphplib ]] && rks-git clone rkphplib --version="$version" --q1=y --q2=y
		[[ $((flag & 2)) = 2 && ! -d phplib ]] && rks-git clone phplib --version="$version" --q1=y --q2=y
	fi

	test $((flag & 1)) -eq 1 && _git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	test $((flag & 2)) -eq 2 && _git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib

	_cd ..
}


#--
# @deprecated use _git_update_php
# @param int flag (2^N, default=7)
#--
function _git_update {
	_msg "DEPRECATED: use _git_update_php"
  _git_update_php "$1"
}


#--
# Gunzip file.
#
# @param file
# @param ignore_if_not_gzip (optional)
#--
function _gunzip {
	test -f "$1" || _abort "no such gzip file [$1]"
	if test -z "$(file "$(realpath "$1")"  | grep 'gzip compressed data')"; then
		if test -z "$2"; then
			_abort "invalid gzip file [$1]"
		else 
			echo "$1 is not in gzip format - skip gunzip"
			return
		fi
	fi

	local target
	target="${1%*.gz}"

	if test -L "$1"; then
		echo "gunzip -c '$1' > '$target'"
		gunzip -c "$1" > "$target"
	else
		echo "gunzip $1"
		gunzip "$1"
	fi

	if ! test -f "$target"; then
		_abort "gunzip failed - no such file $target"
	fi
}


#--
# Gzip $1
# @param file path
#--
function _gzip {
	_require_file "$1"
	_msg "gzip $1"
	_require_program gzip
	gzip "$1" || _abort "gzip '$1'"
	_require_file "$1.gz"
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
# shellcheck disable=SC2009,SC2154 
#--
function _has_process {
	local rx flag process logfile_pid
	flag=$(($2 + 0))

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

	if [[ -z "${PROCESS[log]}" && ($((flag & 2)) = 2 || $((flag & 16)) = 16) ]]; then
		PROCESS[log]="$1.log"
	fi

	if test $((flag & 2)) = 2 && ! test -f "${PROCESS[log]}"; then
		_abort "no such logfile ${PROCESS[log]}"
	fi

	if test $((flag & 16)) = 16; then
		if test -s "${PROCESS[log]}" || test $((flag & 2)) = 2; then
			logfile_pid=$(head -3 "${PROCESS[log]}" | grep "PID=" | sed -e "s/PID=//" | grep -E '^[1-9][0-9]{0,4}$')

			if test -z "$logfile_pid"; then
				logfile_pid=$(grep -E '^[1-9][0-9]{0,4}$' "${PROCESS[log]}")
			fi

			if test -z "$logfile_pid"; then
				_abort "missing PID of [$1] in logfile ${PROCESS[log]}"
			fi
		else
			logfile_pid=-1
		fi
	fi
		
	if test -z "$logfile_pid"; then
		process=$(ps -aux | grep -E "$rx")
	else
		process=$(ps -aux | grep -E "$rx" | grep " $logfile_pid ")
	fi

	if [[ $((flag & 4)) = 4 && -z "$process" ]]; then
		_abort "no $1 process (rx=$rx, old_pid=$logfile_pid)"
	elif [[ $((flag & 8)) = 8 && -n "$process" ]]; then
		_abort "process $1 is already running (rx=$rx, old_pid=$logfile_pid)"
	fi
	
	PROCESS[pid]=$(echo "$process" | awk '{print $2}')
	PROCESS[start]=$(echo "$process" | awk '{print $9, $10}')
	PROCESS[command]=$(echo "$process" | awk '{print $11, $12, $13, $14, $15, $16, $17, $18, $19, $20}')

	# reset option
	PROCESS[log]=
}


#--
# Create .htaccess file in directory $1 if missing. 
# @param path to directory
# @param option (deny|auth:user:pass)
#--
function _htaccess {
	local htpasswd basic_auth

	if test "$2" = "deny"; then
		_append_txt "$1/.htaccess" "Require all denied"
	elif test "${2:0:5}" = "auth:"; then
		_split ":" "$2" >/dev/null
		test -z "${SPLIT[1]}" && _abort "empty username"
		test -z "${SPLIT[2]}" && _abort "empty password"

		htpasswd=$(realpath "$1")"/.htpasswd"
		basic_auth="AuthType Basic
AuthName \"Require Authentication\"
AuthUserFile \"$htpasswd\"
require valid-user"
		_append_txt "$1/.htaccess" "$basic_auth"

		_msg "add user ${SPLIT[1]} to $1/.htpasswd"
		htpasswd -cb "$1/.htpasswd" "${SPLIT[1]}" "${SPLIT[2]}" 2>/dev/null

		_chown "$1/.htpasswd" rk www-data
		_chmod 660 "$1/.htpasswd"
	else
		_abort "invalid second parameter use deny|auth:user:pass"
	fi

	_chown "$1/.htaccess" rk www-data
	_chmod 660 "$1/.htaccess"
}


#--
# Include shell script $1
# @param shell script path
# shellcheck disable=SC1090 
#--
function _include {
	_require_file "$1"
	_msg "include $1"
	source "$1" || _abort "source '$1'"
}


#--
# Install apache2 and mod php
#--
function _install_apache2 {
	_apt_update
	_apt_install "apache2 apache2-utils libapache2-mod-php"
}
	

#--
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir 
# @param string app url (optional)
# @global APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
#--
function _install_app {
	test -z "$1" && _abort "use _install_app . $2"
	test -z "$2" || _dl_unpack "$1" "$2"

	_require_dir "$1"
	_require_global APP_PREFIX

	_mkdir "$APP_PREFIX"

	local dir file entry

	for dir in $APP_DIR_LIST; do
		_mkdir "$(dirname "$APP_PREFIX/$dir")"
		_cp "$1/$dir" "$APP_PREFIX/$dir"
	done

	for file in $APP_FILE_LIST; do
		_mkdir "$(dirname "$APP_PREFIX/$file")"
		_cp "$1/$file" "$APP_PREFIX/$file" md5
	done

	for entry in $APP_SYNC; do
		_msg "rsync -av '$1/$entry' '$APP_PREFIX'/"
		$SUDO rsync -av "$1/$entry" "$APP_PREFIX"/ >/dev/null 2>/dev/null
	done

	_rm "$1"
}


#--
# Install mariadb server and client and php-mysql
#--
function _install_mariadb {
	_apt_update
	_apt_install 'mariadb-server mariadb-client php-mysql'
}
	

#--
# Install nginx and php-fpm
#--
function _install_nginx {
	_apt_update
	_apt_install 'nginx php-fpm'
}
	

#--
# Install node NODE_VERSION from latest binary package. 
# If you want to install|update node/npm use _node_version instead.
#
# @see _node_version
# @global NODE_VERSION
# shellcheck disable=SC2034
#--
function _install_node {
	_require_global NODE_VERSION
	local os_type curr_sudo

	os_type=$(_os_type)
	test "$os_type" = "linux" || _abort "Update node to version >= $NODE_VERSION - see https://nodejs.org/"

	_msg "Install node $NODE_VERSION"
	APP_SYNC="bin include lib share"
	APP_PREFIX="/usr/local"

	curr_sudo=$SUDO
	SUDO=sudo
	_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"
	SUDO=$curr_sudo
}


#--
# Install php and php packages
#--
function _install_php {
	_apt_update	
  _apt_install 'php-cli php-curl php-mbstring php-gd php-xml php-tcpdf php-json'
  _apt_install 'php-dev php-imap php-xdebug php-pear php-zip php-pclzip'
}


#--
# Install sqlite3 and php-sqlite3
#--
function _install_sqlite3 {
	_apt_update
	_apt_install 'sqlite3 php-sqlite3'
}
	

#--
# Export ip address as IP_ADDRESS (ip4) and IP6_ADDRESS (ip6) (and DYNAMIC_IP).
#
# @export IP_ADDRESS IP6_ADDRESS DYNAMIC_IP
# shellcheck disable=SC2034
#--
function _ip_address {
	local ip6_dyn host ping_ok
	_require_program ip

	IP_ADDRESS=$(ip route get 1 | grep -E ' src [0-9\.]+ uid ' | sed -e 's/.* src //' | sed -e 's/ uid.*//')
	if test -z "$IP_ADDRESS"; then
		IP_ADDRESS=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
	fi

	IP6_ADDRESS=$(ip -6 addr | grep 'scope global' | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')
	ip6_dyn=$(ip -6 addr | grep 'scope global temporary dynamic' | awk '{print $2}' | sed -e 's/\/[0-9]*$//')
	if test -n "$ip6_dyn"; then
		IP6_ADDRESS="$ip6_dyn"
		DYNAMIC_IP=1
	fi

	local ping4
	_require_program ping
  if ping -4 -c1 localhost &>/dev/null; then
    ping4="ping -4 -c 1"
  else
    ping4="ping -c 1"
  fi

	host=$(hostname)
	ping_ok=$($ping4 "$host" 2>/dev/null | grep "$IP_ADDRESS")

	if test -z "$ping_ok"; then
		ping_ok=$($ping4 "$host" 2>/dev/null | grep "127.0.")

		if test -z "$ping_ok"; then
			_abort "failed to detect IP_ADDRESS ($ping4 $host != $IP_ADDRESS)"
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

	grep -E "\[submodule \".*$1\"\]" .gitmodules | sed -E "s/\[submodule \"(.*$1)\"\]/\1/"
}


#--
# Abort if parameter is not integer
#
# @param number
#--
function _is_integer {
	local re='^[0-9]+$'

	if ! [[ $1 =~ $re ]] ; then
		_abort "[$1] is not integer"
	fi
}


#--
# Check if ip_address is ip4.
#
# @param ip_address
# @param 2^n flag (1 = ip can be empty)
#--
function _is_ip4 {
	local x flag=$(($2 + 0))

	[[ -z "$1" && $((flag & 1)) = 1 ]] && return

	x='\.[0-9]{1,3}'
	if test -z "$(echo "$1" | grep -E "^[0-9]{1,3}$x$x$x\$")"; then
		_abort "Invalid ip4 address [$1] use e.g. 32.123.7.38"
	fi
}


#--
# Check if ip_address is ip6.
#
# @param ip_address
# @param 2^n flag (1 = ip can be empty)
#--
function _is_ip6 {
	local flag x

	flag=$(($2 + 0))
	[[ -z "$1" && $((flag & 1)) = 1 ]] && return

	x='\:[0-9a-f]{1,4}'
	if test -z "$(echo "$3" | grep -E "^[0-9a-f]{1,4}$x$x$x$x$x$x$x\$")"; then
		_abort "Invalid ip6 [$1] use e.g. 2001:4dd1:4fa3:0:95b2:572a:1d5e:4df5"
	fi
}


#--
# Abort with error message. Process name is either
# apache|nginx|docker:N|port:N (N is port number) 
# or [n]ame. Example:
#
# if test _is_running apache; then
# if test _is_running port:80; then
# if test _is_running [m]ysql; then
#
# @param Process name or expression apache|ngnix|docker:N|port:N|[n]ame
# @os linux
# @return bool
# shellcheck disable=SC2009
#--
function _is_running {
	_os_type linux
	local rx out res
	res=0

	if test "$1" = 'apache'; then
		rx='[a]pache2.*k start'
	elif test "$1" = 'nginx'; then
		rx='[n]ginx.*master process'
	elif test "${1:0:7}" = 'docker:'; then
		rx="[d]ocker-proxy.* -host-port ${1:7}"
	elif test "${1:0:5}" = 'port:'; then
		out=$(netstat -tulpn 2>/dev/null | grep -E ":${1:5} .+:* .+LISTEN.*")
	else
		_abort "invalid [$1] use apache|nginx|docker:PORT|port:N|rx:[n]ame"
	fi

	test -z "$rx" || out=$(ps aux 2>/dev/null | grep -E "$rx")

	test -z "$out" && res=1
	return $res	
}


#--
# Join parameter ($2 or shift; echo "$*") with first parameter as delimiter ($1).
# If parameter count is 2 try if $2 is array.
#
# @beware no whitespace allowed, only single char delimiter 
#
# @example _join ';' 'a' 'x y' 83
# @example K=( a 'x y' 83); _join ';' K
#
# @param delimiter
# @param array|array parts 
# @echo 
#--
function _join {
	local out IFS

	IFS="$1"

	if test $# -eq 2; then
		if test "$2" != '_' && local -n array=$2 2>/dev/null; then
			out="${array[0]}"
			local i
			for (( i=1; i < ${#array[@]}; i++ )); do
				out="$out$1${array[i]}"
			done
		else
			out="${*:2}"
		fi
	else
  	out="${*:2}"
	fi

	echo "$out"
}


#--
# Query json file value. jq warpper.
#
# @param key
# @param json file (optional if JQ_FILE is set)
#--
function _jq {
	local KEY="$1"
	local FILE="${2:-$JQ_FILE}"

	test -z "$KEY" && _abort "empty json key"
	_require_file "$FILE"
	_require_program "jq" "jq"

	jq -r ".$KEY" "$FILE" || _abort "jq -r '.$KEY' '$FILE'"
}


#--
# If pid is file:path/to/process.pid try [head -3 path/to/process.pid | grep PID=] first
# otherwise assume file contains only pid. If pid is rx:REGULAR_EXPRESSION try
# [ps aux | grep -e "REGULAR_EXPRESSION"].
#
# @param pid [pid|file|rx]:...
# @param abort if process does not exist (optional)
# shellcheck disable=SC2009
#--
function _kill_process {
	local msg my_pid pid_file

	case $1 in
		file:*)
			pid_file="${1#*:}"

			if ! test -s "$pid_file"; then
				_abort "no such pid file $pid_file"
			fi

			my_pid=$(head -3 "$pid_file" | grep "PID=" | sed -e "s/PID=//")
			if test -z "$my_pid"; then
				my_pid=$(grep -E '^[1-9][0-9]{0,4}$' "$pid_file")
			fi
			;;
		pid:*)
			my_pid="${1#*:}";;
		rx:*)
			my_pid=$(ps aux | grep -E "${1#*:}" | awk '{print $2}');;
	esac

	if test -z "$my_pid"; then
		_abort "no pid found ($1)"
	fi

	if test -z "$(ps aux | awk '{print $2}' | grep -E '^[1-9][0-9]{0,4}$' | grep "$my_pid")"; then
		msg="no such pid $my_pid"

		test "${1:0:5}" = "file:" && msg="$msg - update ${1:5}" 
		test -z "$2" || _abort "$msg"
		echo "$msg"
	else
		echo "kill $my_pid"
		kill "$my_pid" || _abort "kill '$my_pid'"
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
#--
function _license {
	if [[ -n "$1" && "$1" != 'gpl-3.0' ]]; then
		_abort "unknown license [$1] use [gpl-3.0]"
	fi

	LICENSE=$1
	if test -z "$LICENSE"; then
		LICENSE="gpl-3.0"
	fi

	local lfile is_gpl3
	lfile="./LICENSE"

	if test -s "$lfile"; then
		is_gpl3=$(head -n 2 "$lfile" | tr '\n' ' ' | sed -E 's/\s+/ /g' | grep 'GNU GENERAL PUBLIC LICENSE Version 3')
		if test -n "$is_gpl3"; then
			echo "keep existing gpl-3.0 LICENSE ($lfile)"
			return
		fi

		_confirm "overwrite existing $lfile file with $LICENSE"
		if test "$CONFIRM" != "y"; then
			echo "keep existing $lfile file"
			return
		fi
	fi

	_wget "http://www.gnu.org/licenses/gpl-3.0.txt" "$lfile"
}

#--
# Link $2 to $1.
#
# @param source path
# @param link path
#--
function _ln {
	local target target_dir link_dir old_target
	_require_program realpath

	target=$(realpath "$1")
	test -z "$target" && _abort "no such directory [$1]"
	test "$2" = "$target" && _abort "ln -s '$target' '$2' # source=target"

	if test -L "$2"; then
		old_target=$(realpath "$2")

		if test "$target" = "$old_target"; then
			echo "Link $2 to $target already exists"
			return
		fi

		_rm "$2"
	fi

	link_dir=$(dirname "$2")
	link_dir=$(realpath "$link_dir")
	target_dir=$(dirname "$target")

	local tname lname cwd
	if test "$target_dir" = "$link_dir"; then
		cwd="$PWD"
		_cd "$target_dir"
		tname=$(basename "$1")
		lname=$(basename "$2")
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


#--
# Return $RKBASH_DIR/$1 create directory if missing.
# 
# @param log file name
# @return log file path
#--
function _log_file {
	_mkdir "$(dirname "$RKBASH_DIR/$1")" >/dev/null
	echo -n "$RKBASH_DIR/$1"
}
	

declare -Ai LOG_COUNT  # define hash (associative array) of integer
declare -A LOG_FILE  # define hash
declare -A LOG_CMD  # define hash
LOG_NO_ECHO=

#--
# Pring log message. If second parameter is set assume command logging.
# Set LOG_NO_ECHO=1 to disable echo output. Use LOG_LAST to append
# log file to abort message.
#
# @param message
# @param name (if set use $RKBASH_DIR/$name/$NAME_COUNT.nfo)
# @export LOG_NO_ECHO LOG_COUNT[$2] LOG_FILE[$2] LOG_CMD[$2] LOG_LAST
# @global RKBASH_DIR
# shellcheck disable=SC2086,SC2034
#--
function _log {
	test -z "$LOG_NO_ECHO" && echo -n "$1"
	
	if test -z "$2"; then
		test -z "$LOG_NO_ECHO" && echo
		return
	fi

	# assume $1 is shell command
	LOG_COUNT[$2]=$((LOG_COUNT[$2] + 1))
	LOG_FILE[$2]="$RKBASH_DIR/$2/${LOG_COUNT[$2]}.nfo"
	LOG_CMD[$2]=">>'${LOG_FILE[$2]}' 2>&1"
	LOG_LAST=

	if ! test -d "$RKBASH_DIR/$2"; then
		mkdir -p "$RKBASH_DIR/$2"
		if test -n "$SUDO_USER"; then
			chown -R $SUDO_USER.$SUDO_USER "$RKBASH_DIR" || _abort "chown -R $SUDO_USER.$SUDO_USER '$RKBASH_DIR'"
		elif test "$UID" = "0"; then
			chmod -R 777 "$RKBASH_DIR" || _abort "chmod -R 777 '$RKBASH_DIR'"
		fi
	fi

	local now
	now=$(date +'%d.%m.%Y %H:%M:%S')
	echo -e "# _$2: $now\n# $PWD\n# $1 ${LOG_CMD[$2]}\n" > "${LOG_FILE[$2]}"

	if test -n "$SUDO_USER"; then
		chown $SUDO_USER.$SUDO_USER "${LOG_FILE[$2]}" || _abort "chown $SUDO_USER.$SUDO_USER '${LOG_FILE[$2]}'"
	elif test "$UID" = "0"; then
		chmod 666 "${LOG_FILE[$2]}" || _abort "chmod 666 '${LOG_FILE[$2]}'"
	fi

	test -z "$LOG_NO_ECHO" && echo " ${LOG_CMD[$2]}"
	test -s "${LOG_FILE[$2]}" && LOG_LAST="${LOG_FILE[$2]}"
}


#--
# Run lynx. Keystroke file example: "key q\nkey y"
#
# @param url
# @param keystroke file (optional)
#--
function _lynx {
	_require_program lynx

	if test -z "$1"; then
		_abort "url parameter missing"
	fi

	if [[ -n "$2" && -s "$2" ]]; then
		lynx -cmd_script="$2" -dump "$1"
	else
		lynx -dump "$1"
	fi
}


#--
# Show where php string function needs to change to mb_* version.
# shellcheck disable=SC2034
#--
function _mb_check {
	_require_dir src
	local a mb_func

	echo -e "\nSearch all *.php files in src/ - output filename if string function\nmight need to be replaced with mb_* version.\n"
	echo -e "Type any key to continue or wait 5 sec.\n"
	read -r -n1 -t 5 ignore_keypress

	# do not use ereg*
	mb_func="parse_str split stripos stristr strlen strpos strrchr strrichr 
		strripos strrpos strstr strtolower strtoupper strwidth substr_count substr"

	for a in $mb_func; do
		grep -d skip -r --include=*.php "$a(" src | grep -v "mb_$a("
	done
}


#--
# Print md5sum of file (text if $2=1).
#
# @param file
# @param bool (optional: 1 = threat $1 as string)
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
# Merge "$APP"_ (or ../`basename "$APP"`) directory into $APP (concat *.inc.sh).
# Use 0_header.inc.sh, function.inc.sh, ... Z0_configuration.inc.sh, Z1_setup.inc.sh, Z_main.inc.sh.
# Set RKS_HEADER=0 to avoid rkbash.lib.sh loading. Use --static to include rkbash.lib.sh functions.
# 
# @example test.sh, test.sh_/ and test.sh_/*.inc.sh
# @example test.sh/, test.sh/test.sh and test.sh/*.inc.sh
#
# @global APP RKS_HEADER
# @param split dir (optional if $APP is used)
# @param output file (optional if $APP is used)
# shellcheck disable=SC2119,SC2086,SC2034,SC2120
#--
function _merge_sh {
	local a my_app mb_app sh_dir rkbash_inc tmp_app md5_new md5_old inc_sh scheck
	my_app="${1:-$APP}"
	sh_dir="${my_app}_"

	if test -n "$2"; then
		my_app="$2"
		sh_dir="$1"
	else
		_require_file "$my_app"
		mb_app=$(basename "$my_app")
		test -d "$sh_dir" || { test -d "$mb_app" && sh_dir="$mb_app"; }
	fi

	test "${ARG[static]}" = "1" && rkbash_inc=$(_merge_static "$sh_dir")

	_require_dir "$sh_dir"

	tmp_app="$sh_dir"'_'
	test -s "$my_app" && md5_old=$(_md5 "$my_app")
	echo -n "merge $sh_dir into $my_app ... "

	inc_sh=$(find "$sh_dir" -name '*.inc.sh' 2>/dev/null | sort)
	scheck=$(grep -E '^# shellcheck disable=' $inc_sh | sed -E 's/.+ disable=(.+)$/\1/g' | tr ',' ' ' | xargs -n1 | sort -u | xargs | tr ' ' ',')
	test -z "$scheck" || RKS_HEADER_SCHECK="shellcheck disable=SC1091,$scheck"

	if test -z "$rkbash_inc"; then
		_rks_header "$tmp_app" 1
	else
		_rks_header "$tmp_app"
		echo "$rkbash_inc" >> "$tmp_app"
	fi

	for a in $inc_sh; do
		tail -n+2 "$a" | grep -E -v '^# shellcheck disable=' >> "$tmp_app"
	done

	_add_abort_linenum "$tmp_app"

	md5_new=$(_md5 "$tmp_app")
	if test "$md5_old" = "$md5_new"; then
		echo "no change"
		_rm "$tmp_app" >/dev/null
	else
		echo "update"
		_mv "$tmp_app" "$my_app"
		_chmod 755 "$my_app"
	fi

	test -z "$2" && exit 0
}


#--
# Return include code
# @param script source dir
# shellcheck disable=SC2153,SC2086
#--
function _merge_static {
	local a rks_inc inc_sh
	inc_sh=$(find "$1" -name '*.inc.sh' 2>/dev/null | sort)

	for a in $inc_sh; do
		_rkbash_inc "$a"
		rks_inc="$rks_inc $RKBASH_INC"
	done

	for a in $(_sort $rks_inc); do
		tail -n +2 "$RKBASH_SRC/${a:1}.sh" | grep -E -v '^\s*#'
	done
}


#--
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param flag (optional, 2^0=abort if directory already exists, 2^1=chmod 777 directory, 2^2=message if directory exists)
# @global SUDO
#--
function _mkdir {
	local flag
	flag=$(($2 + 0))

	test -z "$1" && _abort "Empty directory path"

	if test -d "$1"; then
		test $((flag & 1)) = 1 && _abort "directory $1 already exists"
		test $((flag & 4)) = 4 && _msg "directory $1 already exists"
	else
		echo "mkdir -p $1"
		$SUDO mkdir -p "$1" || _abort "mkdir -p '$1'"
	fi

	test $((flag & 2)) = 2 && _chmod 777 "$1"
}


#--
# Mount $1 (e.g. /dev/sdb2) to $2 (e.g. /mnt)
#
# @param device
# @param directory (mount point)
# shellcheck disable=SC2086,SC2143
#--
function _mount {
	[[ -z "$(file -sL $1 | grep ' filesystem')" && -z "$(file -sL $1 | grep 'MBR boot sector')" ]] && \
		_abort "no filesystem on $1"

	if test -z "$(mount | grep -E "^$1 on $2")"; then
		if test -n "$(mount | grep -E "^$1 on ")"; then
			_confirm "umount $1 (and re-mount as $2)" 1
			test "$CONFIRM" = "y" || _abort "user abort"
			umount /dev/sdb2 || _abort "umount /dev/sdb2"
		fi

		_confirm "Mount $1 as $2"
		if test "$CONFIRM" = "y"; then
			mount $1 "$2" || _abort "mount $1 '$2'"
		fi

		test -z "$(mount | grep -E "^$1 on $2")" && _abort "failed to mount $1 as $2"
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
	if test -z "$2"; then
		echo "$1"
	else
		echo "$2" "$1"
	fi
}


#--
# Move files/directories. Target path directory must exist.
#
# @param source_path
# @param target_path
#--
function _mv {

	if test -z "$1"; then
		_abort "Empty source path"
	fi

	if test -z "$2"; then
		_abort "Empty target path"
	fi

	local pdir
	pdir=$(dirname "$2")
	if ! test -d "$pdir"; then
		_abort "No such directory [$pdir]"
	fi

	local AFTER_LAST_SLASH=${1##*/}

	if test "$AFTER_LAST_SLASH" = "*"
	then
		echo "mv $1 $2"
		mv "$1" "$2" || _abort "mv $1 $2 failed"
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
# shellcheck disable=SC2120
#--
function _my_cnf {
	local my_cnf mysql_sql
	my_cnf="$1"

	[[ -z "$SQL_PASS" || -z "$MYSQL" ]] || mysql_sql="$MYSQL"

	test -z "$my_cnf" && my_cnf=".my.cnf"
	test -s "$my_cnf" || return
	test -z "$(cat ".my.cnf" 2>/dev/null)" && return

	DB_PASS=$(grep password "$my_cnf" | sed -E 's/.*=\s*//g')
	DB_NAME=$(grep user "$my_cnf" | sed -E 's/.*=\s*//g')

	if [[ -n "$DB_PASS" && -n "$DB_NAME" && -z "$mysql_sql" ]]; then
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
# shellcheck disable=SC2086
#--
function _mysql_backup {
	local a dump daily_dump files
	dump="mysql_dump.$(date +"%H%M").tgz"
	daily_dump="mysql_dump.$(date +"%Y%m%d").tgz"
	files="tables.txt"

	test -f "tables.txt" && _abort "last dump failed or is still running"

	_cd "$1"

	echo "update $dump and $daily_dump"

	# dump structure
	echo "create_tables" > tables.txt
	_mysql_dump "create_tables.sql" "-d"
	files="$files create_tables.sql"

	for a in $(mysql $MYSQL_CONN -e 'show tables' -s --skip-column-names); do
		# dump table
		echo "$a" >> tables.txt
		_mysql_dump "$a.sql" "--extended-insert=FALSE --no-create-info=TRUE $a"
		files="$files $a.sql"
	done

	_create_tgz "$dump" "$files"
	_cp "$dump" "$daily_dump"
	_rm "$files"

	_cd
}


#--
# Export MYSQL_CONN (and if $1=1 MYSQL).
# If MYSQL_CONN is empty and DB_NAME and DB_PASS are set assume MYSQL_CONN="-h DBHOST -u DBUSER -pDBPASS DBNAME".
# If 1=$1 set MYSQL="[sudo] mysql -u root".
#
# @global MYSQL_CONN DB_NAME DB_PASS
# @export MYSQL_CONN (and MYSQL if $1=1)
# @param require root access (default = false)
# shellcheck disable=SC2086
#--
function _mysql_conn {

	# if $1=1 DB_NAME might not exist yet
	if test -z "$1"; then
		test -z "$DB_NAME" && _abort "$DB_NAME is not set"

		if test -z "$MYSQL_CONN"; then
			test -z "$DB_PASS" && _abort "neither MYSQL_CONN nor DB_NAME and DB_PASS are set"
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		fi

		test -z "$({ echo "USE $DB_NAME" | mysql $MYSQL_CONN 2>&1; } | grep 'ERROR 1045')" || \
			_abort "mysql connection for $DB_NAME string is invalid: $MYSQL_CONN"

		return
	fi

	# $1=1 - root access required
	if test -z "$MYSQL"; then
		if test -n "$MYSQL_CONN"; then
			MYSQL="mysql $MYSQL_CONN"
		elif test "$UID" = "0"; then
			MYSQL="mysql -u root"
		else
			MYSQL="sudo mysql -u root"
		fi
	fi

	test -z "$({ echo "USE mysql" | $MYSQL 2>&1; } | grep 'ERROR 1045')" || \
		_abort "admin access to mysql database failed: $MYSQL"
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
# @return bool (1 if already exists)
#--
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	_require_global DB_NAME DB_PASS
	_mysql_conn 1

	local has_user charset

	if { echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL >/dev/null 2>/dev/null; }; then
		_msg "keep existing database $DB_NAME"

		has_user=$(echo "SELECT user FROM user WHERE user='$DB_NAME' AND host='localhost'" | $MYSQL mysql 2>/dev/null)
		if test -z "$has_user"; then
			{ echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" | $MYSQL; } || \
				_abort "create database user $DB_NAME@localhost failed"
		fi

		return 1
	fi

	if test "$DB_CHARSET" = "utf8mb4"; then
		charset="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
	elif test "$DB_CHARSET" = "utf8"; then
		charset="DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci"
	elif test "$DB_CHARSET" = "latin1"; then
		charset="DEFAULT CHARACTER SET latin1 DEFAULT COLLATE latin1_german1_ci"
	else
		_confirm "Use charset utf8mb4?" 1
		test "$CONFIRM" = "y" && charset="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
	fi

	_msg "create mysql database $DB_NAME"
	{ echo "CREATE DATABASE $DB_NAME $charset" | $MYSQL; } || _abort "create database $DB_NAME failed"
	_msg "create mysql database user $DB_NAME"
	{ echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" | $MYSQL; } || \
		_abort "create database user $DB_NAME@localhost failed"

	return 0
}


#--
# Drop Mysql Database $1. Define MYSQL or "mysql -u root" is used.
#
# @param database name
# @global MYSQL (use 'mysql -u root' if empty)
# shellcheck disable=SC2153,SC2086
#--
function _mysql_drop_db {
	local name mysql
	mysql="$MYSQL"
	name="$1"

	if test -z "$mysql"; then
		test "$UID" = "0" && mysql="mysql -u root" || mysql="sudo mysql -u root"
	fi

	if { echo "SHOW CREATE DATABASE $name" | $mysql >/dev/null 2>/dev/null; }; then
		_confirm "Drop database $name?" 1
		test "$CONFIRM" = "y" || _abort "user abort"

		{ echo "DROP DATABASE $name" | $mysql; } || _abort "drop database $name failed"

		# drop user too if DB_NAME=DB_USER and DB_HOST=localhost
		test -z "$(echo "SELECT db FROM db WHERE user='$name' AND db='$name' AND host='localhost'" | $mysql mysql 2>/dev/null)" || \
			_mysql_drop_user $name
	else
		_msg "no such database $NAME"
		return
	fi
}


#--
# Drop all tables in database.
#
# @global RKBASH_DIR DB_NAME DB_PASS  
#--
function _mysql_drop_tables {
	_require_global RKBASH_DIR DB_NAME DB_PASS
	_confirm "Drop all tables in $DB_NAME" 1
  test "$CONFIRM" = "y" || return

	local tmp_dir drop_sql
	tmp_dir="$RKBASH_DIR/load_dump"
	drop_sql="$tmp_dir/$DB_NAME.sql"

	_mkdir "$tmp_dir"
	echo "SET FOREIGN_KEY_CHECKS = 0;" > "$drop_sql"
	echo "SELECT concat('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema = '$DB_NAME';" | \
		mysql -N -u "$DB_NAME" -p"$DB_PASS" "$DB_NAME" >> "$drop_sql" || _abort "create '$drop_sql' failed"
	echo "SET FOREIGN_KEY_CHECKS = 1;" >> "$drop_sql"
	mysql -u "$DB_NAME" -p"$DB_PASS" "$DB_NAME" < "$drop_sql" || _abort "drop all tables in $DB_NAME failed - see $drop_sql"
	_rm "$drop_sql"	
}


#--
# Drop Mysql User $1. Set MYSQL otherwise "mysql -u root" is used.
#
# @param name
# @param host (default = localhost)
# @global MYSQL (use 'mysql -u root' if empty)
# shellcheck disable=SC2153
#--
function _mysql_drop_user {
	local name host mysql
	mysql="$MYSQL"
	name="$1"
	host="${2:-localhost}"

	if test -z "$mysql"; then
		test "$UID" = "0" && mysql="mysql -u root" || mysql="sudo mysql -u root"
	fi

	if test -z "$(echo "SELECT user FROM user WHERE user='$name' AND host='$host'" | $mysql mysql 2>/dev/null)"; then
		_msg "no such user $name@$host"
		return
	else
		_confirm "Drop user $name@$host?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
		{ echo "DROP USER '$name'@'$host'" | $mysql mysql; } || _abort "drop user '$name'@'$host' failed"
	fi
}


#--
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options (or MYSQL_OPT)
# @global MYSQL_CONN or DB_(USER|HOST|NAME|PASS) MYSQL_OPT
# shellcheck disable=SC2086
#--
function _mysql_dump {
	local user host mycon myopt
	mycon="$MYSQL_CONN"
	myopt="${2:-$MYSQL_OPT}"

	if test -z "$mycon"; then
		if [[ -z "$DB_NAME" || -z "$DB_PASS" ]]; then
			_abort "mysql connection string MYSQL_CONN is empty"
		else
			user="${DB_USER:-$DB_NAME}"
			host="${DB_HOST:-localhost}"
			mycon="-h $host -u $user -p$DB_PASS $DB_NAME"
		fi
	fi

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	{ nice -n 10 ionice -c2 -n 7 \
		mysqldump --single-transaction --quick $mycon $myopt | grep -v -E -e '^/\*\!50013 DEFINER=' > "$1"; } || \
			_abort "mysqldump ... $myopt > $1 failed"
	echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	test -f "$1" || _abort "no such dump [$1]"
	test -z "$(tail -1 "$1" | grep "Dump completed")" && _abort "invalid mysql dump [$1]"
}


#--
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh. 
#
# @param dump_file (if empty try data/sql/mysqlfulldump.sql, setup/mysqlfulldump.sql)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# shellcheck disable=SC2086
#--
function _mysql_load {
	local dump tmp_dump
	dump="$1"

	if ! test -f "$dump"; then
		if test -s "data/sql/mysqlfulldump.sql"; then
			dump=data/sql/mysqlfulldump.sql
		elif test -s "setup/mysqlfulldump.sql"; then
			dump=setup/mysqlfulldump.sql
		else
			_abort "no such mysql dump [$dump]"
		fi

		_confirm "Load $dump?"
		if test "$CONFIRM" != "y"; then
			echo "Do not load $dump"
			return
		fi
	fi

	if test -z "$(tail -1 "$dump" | grep "Dump completed")"; then
		_abort "invalid mysql dump [$dump]"
	fi

	if test -n "$FIX_MYSQL_DUMP"; then
		echo "fix $dump"
		tmp_dump="$(dirname $dump)/_fix.sql"
		echo -e "SET FOREIGN_KEY_CHECKS=0;\nSTART TRANSACTION;\n" > "$tmp_dump"
		sed -e "s/^\/\*\!.*//" < "$dump" | sed -e "s/^INSERT INTO/INSERT IGNORE INTO/" >> "$tmp_dump"
		echo -e "\nCOMMIT;\n" >> "$tmp_dump"
		mv "$tmp_dump" "$dump"
	fi

	if test -f "restore.sh"; then
		echo "add $dump to restore.sh"
		echo "_restore $dump &" >> restore.sh
	else
		_mysql_conn
		echo "mysql ... < $dump"
		SECONDS=0
		mysql $MYSQL_CONN < "$dump" || _abort "mysql ... < $dump failed"
		echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
	fi
}


#--
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @param parallel_import (optional - use parallel import if set)
# @global MYSQL_CONN (call _mysql_conn for mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME")
# shellcheck disable=SC1091,SC2013,SC2016,SC2034
#--
function _mysql_restore {
	local a tmp_dir file import
	tmp_dir="/tmp/mysql_dump"
	file=$(basename "$1")

	_mkdir "$tmp_dir" 1
	_cp "$1" "$tmp_dir/$file"

	_cd "$tmp_dir"

	_extract_tgz "$file" "tables.txt"

	sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' create_tables.sql > create_tables.fix.sql

	if test -n "$(cmp -b create_tables.sql create_tables.fix.sql)"; then
		_mv create_tables.fix.sql create_tables.sql
	else
		_rm create_tables.fix.sql
	fi

	for a in $(cat tables.txt); do
		# load only create_tables.sql ... write other load commands to restore.sh
		_mysql_load "$a.sql"

		if [[ -n "$2" && "$a" = "create_tables" ]]; then
			_mysql_conn
			echo "create restore.sh"
			{
				echo -e "#!/bin/bash\n"
				echo -e "MYSQL_CONN=\"$MYSQL_CONN\"\n"
				echo 'function _restore {'
				echo '  mysql $MYSQL_CONN < $1 &> $1".log" && rm $1 || echo "import $1 failed"'
				echo '  echo "$1 import finished"'
				echo -e "}\n\n"
			} > restore.sh
			_chmod 755 restore.sh
		fi
	done

  if test -n "$2"; then
    echo "start table imports in background"  
    _include restore.sh

    _rm "create_tables.sql"
    import=1
    SECONDS=0

    while test "$import" = '1'; do
      import=0
      for a in $(cat tables.txt); do
        # sql file is removed after successfull import
        test -f "$a.sql" && import=1
      done

      sleep 10
    done

    echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
  fi

	_cd

	_rm "$tmp_dir"
}


#--
# Split php database connect string settings_dsn. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @param int don't abort (default = 0 = abort)
# @global DOCROOT PATH_RKPHPLIB
# @export DB_NAME (DB_USER) DB_PASS MYSQL DOCROOT
# @return bool
# shellcheck disable=SC2119,SC2120
#--
function _mysql_split_dsn {
	_my_cnf

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	if ! test -f "$1"; then
		test -z "$DOCROOT" && { _find_docroot "$PWD" "$2" || return 1; }

		if test -f "$DOCROOT/settings.php"; then
			_settings_php "$DOCROOT/settings.php"
		elif test -f "$DOCROOT/index.php"; then
			_settings_php "$DOCROOT/settings.php"
		fi
	else
		_settings_php "$1"
	fi

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	test -z "$2" && _abort "autodetect DB_NAME|PASS failed"
	return 1
}


#--
# Load settings.php via php and export SETTINGS_(DB_NAME|DB_PASS|DSN), PATH_(RKPHPLIB|PHPLIB) and DOCROOT.
# @param settings.php path
#	@export DB_USER DB_NAME DB_PASS
# shellcheck disable=SC2016,SC2034
#--
function _settings_php {
	local php_code

	IFS='' read -r -d '' php_code <<'EOF'
include(getenv('SETTINGS_PHP'));

if (defined('SETTINGS_DB_NAME') && defined('SETTINGS_DB_PASS')) {
	$login = defined('SETTINGS_DB_USER') ? SETTINGS_DB_USER : SETTINGS_DB_NAME;
	$name= SETTINGS_DB_NAME;
	$pass= SETTINGS_DB_PASS;
}
else if (defined('SETTINGS_DSN') && defined('PATH_RKPHPLIB')) {
	require(constant('PATH_RKPHPLIB').'ADatabase.class.php');
	$dsn = \rkphplib\ADatabase::splitDSN(SETTINGS_DSN);
	$login = $dsn['login'];
	$name = $dsn['name'];
	$pass = $dsn['password'];
}

if (!empty($name) && !empty($login) && !empty($pass)) {
	print "$login\n$name\n$pass";
}
EOF

	_require_file "$1"
	read -r -d "\n" DB_USER DB_NAME DB_PASS <<<"$(SETTINGS_PHP="$1" php -r "$php_code")"
}


#--
# Install nginx, php_fpm and php site
# shellcheck disable=SC2016,SC2012
#--
function _nginx_php_fpm {
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


#--
# Check node.js version. Install node and npm if missing. 
# Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v12.16.2 and NPM_VERSION=6.13.4 as default.
#
# @global NODE_VERSION NPM_VERSION
# @export NODE_VERSION NPM_VERSION
#--
function _node_version {
	test -z "$NODE_VERSION" && NODE_VERSION=v12.16.2
	test -z "$NPM_VERSION" && NPM_VERSION=6.14.4

	if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
		_install_node 
	fi

	if [[ $(_version node 1) -lt $(_version $NODE_VERSION 1) ]]; then
		_install_node
	fi

	if [[ $(_version npm 1) -lt $(_version $NPM_VERSION 1) ]]; then
		_msg "Update npm to latest"
		_sudo "npm i -g npm"
	fi
}


#--
# Copy module from node_module/$2 to $1 if necessary.
# Apply patch patch/npm2js/`basename $1`.patch if found.
#
# @param target path
# @param source path (node_modules/$2)
# shellcheck disable=SC2034
#--
function _npm2js {
	test -z "$2" && _abort "empty module path"
	[[ -f "node_modules/$2" || -d "node_modules/$2" ]] || _abort "missing node_modules/$2"

	_cp "node_modules/$2" "$1" md5

	local base
	base=$(basename "$1")
	if test -f "patch/npm2js/$base.patch"; then
		PATCH_LIST="$base"
		PATCH_DIR=$(dirname "$1")
		_patch patch/npm2js
	fi
}


#--
# Install npm module $1 (globally if $2 = -g)
#
# @sudo
# @param package_name
# @param npm_param (e.g. -g, --save-dev)
# shellcheck disable=SC2086
#--
function _npm_module {
	if ! command -v npm >/dev/null; then
		_node_version
  fi

	local extra_param
	if test "$1" = "ios-deploy"; then
		extra_param="--unsafe-perm=true --allow-root"
	fi

	if test "$2" = "-g"; then
		if test -d "/usr/local/lib/node_modules/$1"; then
			echo "node module $1 is already globally installed - updating"
			sudo npm update $extra_param -g "$1"
			return
		else
			echo "install node module $1 globally"
			sudo npm install $extra_param -g "$1"
			return
		fi
	fi

	if test -d "node_modules/$1"; then
		echo "node module $1 is already installed - updating"
		npm update $extra_param "$1"
	return
	fi

	npm install $extra_param "$1" $2
}


#--
# Print warning (green color message to stdout and stderr)
#
# @param message
#--
function _ok {
	echo -e "\033[0;32m$1\033[0m" 1>&2
}


#--
# Backup $1 as $1.orig (if not already done).
#
# @param path
# @param bool do not abort if $1 is missing (optional, default = 0 = abort)
#--
function _orig {
	if ! test -f "$1" && ! test -d "$1"; then
		test -z "$2" && _abort "missing $1"
		return 1
	fi

	local RET=0

	if test -f "$1.orig"; then
		_msg "$1.orig already exists"
		RET=1
	else
		_msg "create backup $1.orig"
		_cp "$1" "$1.orig"
	fi

	return $RET
}


#--
# Return linux, macos, cygwin if $1 is empty. 
# If $1 is set and != os_type abort otherwise return 0.
#
# @print string (abort if set and os_type != $1)
# @print linux|macos|cygwin if $1 is empty
# @return bool
#--
function _os_type {
	local os me

	_require_program uname
	me=$(uname -s)

	if [ "$(uname)" = "Darwin" ]; then
		os="macos"        
	elif [ "$OSTYPE" = "linux-gnu" ]; then
		os="linux"
	elif [ "${me:0:5}" = "Linux" ]; then
		os="linux"
	elif [ "${me:0:5}" = "MINGW" ]; then
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

# osx has no md5sum
test -z "$(command -v md5sum)" && _abort "install brew (https://brew.sh/)"

# osx bash is outdated
test -f "/usr/local/bin/bash" || _abort "brew install bash"

# enable brew bash
[[ "$BASH_VERSION" =~ 5. ]] || _abort 'change shebang to: #!/usr/bin/env bash'  

# osx has no realpath
test -z "$(command -v realpath)" && _abort "brew install coreutils"

test "$(echo -e "a_c\naa_b" | sort | xargs)" != "aa_b a_c" && \
	_abort "UTF-8 sort is broken - fix /usr/share/locale/${LC_ALL}/LC_COLLATE"


#--
# OSX /usr/bin/stat is incompatible with linux. Use stat function wrapper.
#
# @param -c
# @param -
# shellcheck disable=SC2012
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
		else
			_abort "ToDo: stat $*"
		fi
	else
		_abort "ToDo: stat $*"
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
# shellcheck disable=SC2086
#--
function _package_json {
	local a

	if ! test -f package.json; then
		echo "create: package.json"
		echo '{ "name": "ToDo", "version": "0.1.0", "title": "ToDo", "description": "ToDo", "repository": {} }' > package.json
	fi

	if ! test -f README.md; then
		echo "create: README.md - adjust content"
		echo "ToDo" > README.md
	fi

	if test -n "$1"; then
		echo "upgrade package.json"
		_npm_module npm-check-updates -g
		npm-check-updates -u
	fi

	for a in $NPM_PACKAGE_GLOBAL; do
		_npm_module "$a" -g
	done

	local run_install
	for a in $NPM_PACKAGE $NPM_PACKAGE_DEV; do
		if ! grep "$a" package.json >/dev/null; then
			run_install=1
		fi
	done

	if test -n "$run_install"; then
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
		_cd patch
		./patch.sh
		_cd ..
	fi
}


declare -A ARG
declare ARGV

#--
# Set ARG[name]=value if --name=value or name=value.
# If --name set ARG[name]=1. Set ARG[0], ARG[1], ... (num = ARG[#]) otherwise.
# (Re)Set ARGV=( $@ ). Don't reset ARG (allow default).
# Use _parse_arg "$@" to preserve whitespace.
#
# @param "$@"
# @export ARG (hash) ARGV (array)
# shellcheck disable=SC2034,SC1001
#--
function _parse_arg {
	ARGV=()

	local i n key val
	n=0
	for (( i = 0; i <= $#; i++ )); do
		ARGV[$i]="${!i}"
		val="${!i}"
		key=

		if [[ $val == "--"*"="* ]]; then
			key="${val/=*/}"
			key="${key/--/}"
			val="${val#*=}"
		elif [[ $val == "--"* ]]; then
			key="${val/--/}"
			val=1
		elif [[ $val =~ ^[a-zA-Z0-9_\.\-]+= ]]; then
			key="${val/=*/}"
			val="${val#*=}"
		fi

		if test -z "$key"; then
			ARG[$n]="$val"
			n=$(( n + 1 ))
		elif test -z "${ARG[$key]}"; then
			ARG[$key]="$val"
		else
			ARG[$key]="${ARG[$key]} $val"
		fi
	done

	ARG[#]=$n
}


#--
# Patch either PATCH_LIST and PATCH_DIR are set or $1/patch.sh exists.
# If $1/patch.sh exists it must export PATCH_LIST and PATCH_DIR (set PATCH_SOURCE_DIR = dirname $1).
# If $1 is file assume PATCH_SOURCE_DIR=dirname $1, PATCH_LIST=basename $1 and PATCH_DIR is either
# absoulte or relative path after 'conf/'.
# Apply patch if target file and patch file exist.
#
# @global PATCH_SOURCE_DIR PATCH_LIST PATCH_DIR
# @param patch file directory or patch source file (optional)
# shellcheck disable=SC1090
#--
function _patch {
	if [[ -n "$1" && -d "$1" ]]; then
		PATCH_SOURCE_DIR="$1"
	elif test -s "$1"; then
		PATCH_LIST=$(basename "$1" | sed -E 's/\.patch$//')
		PATCH_SOURCE_DIR=$(dirname "$1")
		if test -z "$PATCH_DIR"; then
			PATCH_DIR=$(echo "$PATCH_SOURCE_DIR" | grep 'conf/' | sed -E 's/^.*conf\///')
			test -d "/$PATCH_DIR" && PATCH_DIR="/$PATCH_DIR"
		fi
	elif test -f "$1/patch.sh"; then
		PATCH_SOURCE_DIR=$(dirname "$1")
		_include "$1/patch.sh"
	fi

	_require_program patch
	_require_dir "$PATCH_DIR"
	_require_dir "$PATCH_SOURCE_DIR"
	_require_global PATCH_LIST

	local a target
	for a in $PATCH_LIST; do
		test -f "$PATCH_DIR/$a" && target="$PATCH_DIR/$a" || target=$(find "$PATCH_DIR" -name "$a")

		if test -f "$PATCH_SOURCE_DIR/$a.patch" && test -f "$target"; then
			CONFIRM="y"
			_orig "$target" >/dev/null || _confirm "$target.orig already exists patch anyway?"
			if test "$CONFIRM" = "y"; then
				_msg "patch '$target' '$PATCH_SOURCE_DIR/$a.patch'"
				patch "$target" "$PATCH_SOURCE_DIR/$a.patch" || _abort "patch '$a.patch' failed"
			fi
		else
			_msg "skip $a.patch - missing either $PATCH_SOURCE_DIR/$a.patch or [$target]"
		fi
	done

	PATCH_DIR=
}


#--
# Create phpdocumentor documentation for php project in docs/phpdocumentor.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/phpdocumentor)
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

	test -n "$1" && SRC_DIR="$1"
	test -n "$2" && DOC_DIR="$2"

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
#   - script (buildin = RKBASH_DIR/php_server.php)
#	  - host (0.0.0.0)
#
# @call_before _parse_arg "$@" 
# @global RKBASH_DIR ARG
# shellcheck disable=SC2009
#--
function _php_server {
	_require_program php
	_mkdir "$RKBASH_DIR"

	local php_code=
IFS='' read -r -d '' php_code <<'EOF'
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
		echo "$php_code" > "$RKBASH_DIR/php_server.php"
		ARG[script]="$RKBASH_DIR/php_server.php"
	fi

	test -z "${ARG[port]}" && ARG[port]=15080
	test -z "${ARG[docroot]}" && ARG[docroot]="$PWD"
	test -z "${ARG[host]}" && ARG[host]="0.0.0.0"

	local log server_pid
	log="$RKBASH_DIR/php_server.log"

	if _is_running "port:${ARG[port]}"; then
		server_pid=$(ps aux | grep -E "[p]hp .+\:${ARG[port]}.+php_server.php" | awk '{print $2}')
		if test -z "$server_pid"; then
			_abort "Port ${ARG[port]} is already used"
		else
			_abort "PHP Server is already running on ${ARG[host]}:${ARG[port]}\n\nStop PHP Server: kill [-9] $server_pid"
		fi
	fi

	_confirm "Start buildin PHP standalone Webserver" 1
	test "$CONFIRM" = "y" || _abort "user abort"

	if test -z "${ARG[user]}"; then
		{ php -t "${ARG[docroot]}" -S ${ARG[host]}:${ARG[port]} "${ARG[script]}" >"$log" 2>&1 || \
			_abort "PHP Server failed - see: $log"; } &
	else
		{ sudo -H -u ${ARG[user]} bash -c "php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1" || \
			_abort "PHP Server failed - see: $log"; } &
		sleep 1
	fi

	server_pid=$(ps aux | grep -E "[p]hp .+\:${ARG[port]}.+php_server.php" | awk '{print $2}')
	test -z "$server_pid" && _abort "Could not determine Server PID"

	echo -e "\nPHP buildin standalone server started"
	echo "URL: http://${ARG[host]}:${ARG[port]}"
	echo "LOG: tail -f $log"
	echo "DOCROOT: ${ARG[docroot]}"
	echo "CMD: php -t '${ARG[docroot]}' -S ${ARG[host]}:${ARG[port]} '${ARG[script]}' >'$log' 2>&1"
	echo -e "STOP: kill $server_pid\n"
}


#--
# Export PHP_VERSION=MAJOR.MINOR
# 
# @export PHP_VERSION
# shellcheck disable=SC2034
#--
function _php_version {
	PHP_VERSION=$(php -v | grep -E '^PHP [0-9\.]+\-' | sed -E 's/PHP ([0-9]\.[0-9]).+$/\1/')
}


#--
# Check if port $2 on server $1 is reachable
#
# @param string ip or server name
# @param port
# @return bool
#--
function _port_reachable {
	if nc -zv -w2 "$1" "$2" 2>/dev/null; then
		return 0
	else
		return 1
	fi
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
# Show progress bar. Third parameter is Style;Label;Mesage (default = '1;Progress;').
# Use $1 or $PROGRESS_FILE to load progress value from file (use /dev/shm/...).
# Use $PROGRESS_MAX|STYLE|LABEL|MSG instead of $2 and $3. Styles:
#
# 1: |----
# 2: [###---]
# 3: ▇▇▇
# d31,d32,d33,d34,d35,d36: same as 3 but in dark  red|green|yellow|blue|purple|cyan
# l31,l32,l33,l34,l35,l36: same as 3 but in light red|green|yellow|blue|purple|cyan
# dialog: use dialog
# whiptail: use whiptail
#
# @example for n in $(seq 1 100); do sleep 0.01; _progress_bar $n; done
#
# @global PROGRESS_FILE PROGRESS_MAX
# @param value (<= end)
# @param end (default = 100)
# @param label (default = Progress:1 = Lable:Style)
#--
function _progress_bar {
	local label style msg max slm progress pg
	label="${PROGRESS_LABEL:-Progress}"
	style="${PROGRESS_STYLE:-1}"
	msg="$PROGRESS_MSG"
	max=${2:-$PROGRESS_MAX}
	slm="$style;$label;$msg"
	progress="${1:-0}"

	[[ -z "$progress" && -n "$PROGRESS_FILE" && -f "$PROGRESS_FILE" ]] && progress=$(cat "$PROGRESS_FILE")
	[[ "$progress" =~ ^[0-9]+$ ]] || _abort "invalid progress [$progress]"
	test -z "$max" && max=100
	test -z "$3" || slm="$3"

	IFS=";" read -ra pg <<< "$progress;$max;$slm"

	case ${pg[2]} in
		1|2|3|d31|d32|d33|d34|d35|d36|l31|l32|l33|l34|l35|l36)
			_progress_bar_printf "$progress;$max;$slm"
			;;
		dialog)
			progress=$(( (progress*100) / max ))
			echo -e "XXX\n$progress\n$label\n\n$msg\nXXX" | dialog --gauge "" 10 70 0
			;;
		whiptail)
			echo "ToDo ... whiptail"
			;;
	esac
}


#--
# Create custom progress bar with printf and \r.
# @param progress;max;style;label;message
#--
function _progress_bar_printf {
	local pg progress finished left fill empty
	IFS=";" read -ra pg <<< "$1"

	progress=$(( (pg[0] * 100) / pg[1] ))
	finished=$(( (progress * 4) / 10 ))
	left=$(( 40 - finished ))
	fill=$(printf "%${finished}s")
	empty=$(printf "%${left}s")

	local color="${pg[2]}"
	if [ "${color:0:2}" = "d3" ]; then
		color="0;${color:1}m"
		pg[2]="color_bar"
	elif [ "${color:0:2}" = "l3" ]; then
		color="1;${color:1}m"
		pg[2]="color_bar"
	fi

	local label="${pg[3]}"
	(( ccol=${#label}+1 ))

	printf "\n\e[A\e[K"

	case ${pg[2]} in
		1)
			printf "$label:  |${fill// /-}${empty// / } ${progress}%%"
			;;
		2)
			printf "$label:  [${fill// /\#}${empty// /-}] ${progress}%%"
			;;
		3)
			printf "$label:  ${fill// /▇}${empty// / } ${progress}%%"
			;;
		color_bar)
			printf "$label:  \e[${color}${fill// /▇}${empty// / }\e[0m ${progress}%%"
			;;
	esac

	local msg="${pg[4]}"
	local msg_len="${#msg}"
	printf "\n\e[K%s\e[A\e[%sD\e[%sC" "$msg" "$msg_len" "$ccol"
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
	local i len chars
	chars="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"
	len=${1:-8}

	if [[ -n "$2" && -n "$3" ]]; then
		chars="${chars:$2:$3}"
	fi

	for (( i = 0; i < len; i++ )); do
		echo -n "${chars:RANDOM%${#chars}:1}"
	done
	echo
}


#--
# realpath replacement on osx
#
# @param path
#--
function _realpath_osx {
	local realpath link

	_cd "$(dirname "$1")"
	link=$(readlink "$(basename "$1")")

	while [ "$link" ]; do
		_cd "$(dirname "$link")"
		link=$(readlink "$(basename "$1")")
	done

	realpath="$PWD/$(basename "$1")"

	_cd "$CURR"
	echo "$realpath"
}


#--
# Re-create database if inside docker.
#
# @param do_not_load_dump (optional, default = empty = load_dump)
# @export DB_NAME DB_PASS MYSQL_CONN
# shellcheck disable=SC2119
#--
function _recreate_docker_db {
	if grep 172.17 /etc/hosts >/dev/null; then
		echo "not inside docker - abort database recreate"
		return
	fi

	_mysql_split_dsn
	_mysql_create_db "$DB_NAME" "$DB_PASS"

	test -z "$1" && _mysql_load
}


#--
# Export remote ip adress REMOTE_IP and REMOTE_IP6.
#
# @export REMOTE_IP REMOTE_IP6
# shellcheck disable=SC2034
#--
function _remote_ip {
	_require_program curl

	local ip4_ip6
	ip4_ip6=$(curl -sSL --insecure 'https://dyn4.de/ip.php')

	REMOTE_IP=$(echo "$ip4_ip6" | awk '{print $1}')
	REMOTE_IP6=$(echo "$ip4_ip6" | awk '{print $2}')
}


#--
# Abort if directory does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
#--
function _require_dir {
	test -d "$1" || _abort "no such directory '$1'"
	test -z "$2" || _require_owner "$1" "$2"
	test -z "$3" || _require_priv "$1" "$3"
}


#--
# Abort if file does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
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
# @param name list (e.g. "GLOBAL", "GLOB1 GLOB2 ...", GLOB1 GLOB2 ...)
#--
function _require_global {
	local a has_hash bash_version
	bash_version=$(bash --version | grep -iE '.+bash.+version [0-9\.]+' | sed -E 's/^.+version ([0-9]+)\.([0-9]+)\..+$/\1.\2/i')

	for a in "$@"; do
		has_hash="HAS_HASH_$a"

		if (( $(echo "$bash_version >= 4.4" | bc -l) )); then
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
# shellcheck disable=SC2206
#--
function _require_owner {
	if ! test -f "$1" && ! test -d "$1"; then
		_abort "no such file or directory '$1'"
	fi

	local arr owner group
	arr=( ${2//:/ } )
	owner=$(stat -c '%U' "$1" 2>/dev/null)
	test -z "$owner" && _abort "stat -c '%U' '$1'"
	group=$(stat -c '%G' "$1" 2>/dev/null)
	test -z "$group" && _abort "stat -c '%G' '$1'"

	if [[ -n "${arr[0]}" && "${arr[0]}" != "$owner" ]]; then
		_abort "invalid owner - chown ${arr[0]} '$1'"
	fi

	if [[ -n "${arr[1]}" && "${arr[1]}" != "$group" ]]; then
		_abort "invalid group - chgrp ${arr[1]} '$1'"
	fi
}


#--
# Abort if file or directory privileges don't match.
#
# @param path
# @param privileges (e.g. 600)
#--
function _require_priv {
	test -z "$2" && _abort "empty privileges"
	local priv
	priv=$(stat -c '%a' "$1" 2>/dev/null)
	test -z "$priv" && _abort "stat -c '%a' '$1'"
	test "$2" = "$priv" || _abort "invalid privileges [$priv] - chmod -R $2 '$1'"
}


#--
# Abort if program (function) $1 does not exist (and $2 is not 1).
#
# @param program
# @param string default='' (abort if missing), 1=return false, apt:xxx (install xxx if missing)
# @return bool (if $2==1)
#--
function _require_program {
	local ptype
	ptype=$(type -t "$1")

	test "$ptype" = "function" && return
	command -v "$1" >/dev/null 2>&1 && return
	command -v "./$1" >/dev/null 2>&1 && return

	if test "${2:0:4}" = "apt:"; then
		_apt_install "${2:4}"
	elif test -z "$2"; then
		echo "No such program [$1]"
		exit 1
	else
		return 1
	fi
}


#--
# Abort if '$1 --version' is lowner than $2.
#
# @param app name
# @param app version
#--
function _require_version {
	_require_program "$1"
	local version
	version="$($1 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/')"
	if (( $(echo "$version < $2" | bc -l) )); then
		_abort "$1 --version < $2"
	fi
}


#--
# Change RKBASH_DIR to ~/.rkbash/$1 if directory is default. 
# Use $1 = reset to change to ~/.rkbash/$$.
# 
# @param optional ~/.rkbash subdirectory or reset
# @export RKBASH_DIR
#--
function _rkbash_dir {
	if [[ "$RKBASH_DIR" = "$HOME/.rkbash" && "$1" = 'reset' ]]; then
		RKBASH_DIR="$HOME/.rkbash/$$"
		return
	fi

	if [[ "$RKBASH_DIR" != "$HOME/.rkbash/$$" ]]; then
		:
	elif test -z "$1"; then
		RKBASH_DIR="$HOME/.rkbash"
	elif [[ "$1" != 'reset' ]]; then
		RKBASH_DIR="$HOME/.rkbash/$1"
		_mkdir "$RKBASH_DIR"
	fi
}
	

#--
# Export required $RKBASH_SRC/src/* functions as $RKBASH_INC
#
# @global RKBASH_SRC (default = .)
# @export RKBASH_INC RKBASH_INC_NUM
# @export_local _HAS_SCRIPT
# @param file path
# shellcheck disable=SC2034,SC2068
#--
function _rkbash_inc {
	local _HAS_SCRIPT
	declare -A _HAS_SCRIPT

	if test -z "$RKBASH_SRC"; then
		if test -s "src/abort.sh"; then
			RKBASH_SRC='src'
		else
			_abort 'set RKBASH_SRC'
		fi
	elif ! test -s "$RKBASH_SRC/abort.sh"; then
		_abort "invalid RKBASH_SRC='$RKBASH_SRC'"
	fi

	test -s "$1" || _abort "no such file '$1'"
	_rrs_scan "$1"

	RKBASH_INC=$(_sort ${!_HAS_SCRIPT[@]})
	RKBASH_INC_NUM="${#_HAS_SCRIPT[@]}"
}


#--
# Export required rkbash/src/* functions as ${!_HAS_SCRIPT[@]}.
#
# @global RKBASH_SRC
# @global_local _HAS_SCRIPT
# @param file path
#--
function _rrs_scan {
	local a func_list
	test -f "$1" || _abort "no such file '$1'"
	func_list=$(grep -E -o -e '(_[a-z0-9\_]+)' "$1" | xargs -n1 | sort -u | xargs)

	for a in $func_list; do
		if [[ -z "${_HAS_SCRIPT[$a]}" && -s "$RKBASH_SRC/${a:1}.sh" ]]; then
			_HAS_SCRIPT[$a]=1
			_rrs_scan "$RKBASH_SRC/${a:1}.sh"
		fi
	done
}


#--
function __abort {
	echo -e "\nABORT: $1\n\n"
	exit 1
}


#--
# Use for dynamic loading.
# @example _rkbash "_rm _mv _cp _mkdir"
# @global RKBASH_SRC = /path/to/rkbashlib/src
# @param function list
# shellcheck disable=SC1090,SC2086
#--
function _rkbash {
	test -z "$RKBASH_SRC" && RKBASH_SRC=../../rkbashlib/src
	test -d "$RKBASH_SRC" || RKBASH_SRC=../../../rkbashlib/src
	local a abort 

	abort=_abort
	test "$(type -t $abort)" = 'function' || abort=__abort

	[[ -d "$RKBASH_SRC" && -f "$RKBASH_SRC/abort.sh" ]] || \
		$abort "invalid RKBASH_SRC path [$RKBASH_SRC] - $APP_PREFIX $APP"

	for a in $1; do
		if ! test "$(type -t $a)" = "function"; then
			echo "load $a"
			_include "$RKBASH_SRC/${a:1}.sh" 
		else 
			echo "found $a"
		fi
	done
}


#--
# Prepare rks-app. Adjust APP_DESC if SYNTAX_HELP[$1|$1.$2] is set.
# Execute self_update or help action if $1 = self_update|help.
#
# @example _parse_arg "$@"; APP_DESC='...'; _rks_app "$0" "$@"
# @global APP_DESC SYNTAX_CMD SYNTAX_HELP
# @export APP CURR APP_DIR APP_PID (if not set)
# @param $0 $@
# shellcheck disable=SC2034,SC2119
#--
function _rks_app {
	local me p1 p2 p3
	me="$1"
	shift
	p1="$1"
	p2="$2"
	p3="$3"

	test -z "$me" && _abort "call _rks_app '$0' $*"
	test -z "${ARG[1]}" || p1="${ARG[1]}"
	test -z "${ARG[2]}" || p2="${ARG[2]}"
	test -z "${ARG[3]}" || p3="${ARG[3]}"

	if test -z "$APP"; then
		APP="$me"
		APP_DIR=$( cd "$( dirname "$APP" )" >/dev/null 2>&1 && pwd )
		CURR="$PWD"
		if test -z "$APP_PID"; then
			 export APP_PID="$$"
		elif test "$APP_PID" != "$$"; then
			 export APP_PID="$APP_PID $$"
		fi
	fi

	test -z "$APP_DESC" && _abort "APP_DESC is empty"
	test -z "${#SYNTAX_CMD[@]}" && _abort "SYNTAX_CMD is empty"
	test -z "${#SYNTAX_HELP[@]}" && _abort "SYNTAX_HELP is empty"

	[[ "$p1" =	'self_update' ]] && _merge_sh

	[[ "$p1" = 'help' ]] && _syntax "*" "cmd:* help:*"
	test -z "$p1" && return

	test -z "${SYNTAX_HELP[$p1]}" || APP_DESC="${SYNTAX_HELP[$p1]}"
	test -z "${SYNTAX_HELP[$p1.$p2]}" || APP_DESC="${SYNTAX_HELP[$p1.$p2]}"

	[[ -n "${SYNTAX_CMD[$p1]}" && "$p2" = 'help' ]] && _syntax "$p1" "help:"
	[[ -n "${SYNTAX_CMD[$p1.$p2]}" && "$p3" = 'help' ]] && _syntax "$p1.$p2" "help:"
}


#--
# Print script header header to file. Flag:
#
# 1 = load /usr/local/lib/rkbash.lib.sh
#
# @global RKS_HEADER (optional instead of flag) RKS_HEADER_SCHECK (shellcheck ...)
# @param filename
# @param int flag (2^n)
#--
function _rks_header {
	local flag header copyright
	copyright=$(date +"%Y")
	flag=$(($2 + 0))

	[ -z "${RKS_HEADER+x}" ] || flag=$((RKS_HEADER + 0))

	if test -f ".gitignore"; then
		copyright=$(git log --diff-filter=A -- .gitignore | grep 'Date:' | sed -E 's/.+ ([0-9]+) \+[0-9]+/\1/')" - $copyright"
	fi

	test $((flag & 1)) = 1 && \
		header='source /usr/local/lib/rkbash.lib.sh || { echo -e "\nERROR: source /usr/local/lib/rkbash.lib.sh\n"; exit 1; }'

	printf '\x23!/usr/bin/env bash\n\x23\n\x23 Copyright (c) %s Roland Kujundzic <roland@kujundzic.de>\n\x23\n\x23 %s\n\x23\n\n' \
		"$copyright" "$RKS_HEADER_SCHECK" > "$1"
	test -z "$header" || echo "$header" >> "$1"
}


#--
# Remove file or directory.
#
# @param path/to/entry
# @param int (optional - abort if set and path is invalid)
#--
function _rm {
	test -z "$1" && _abort "Empty remove path"

	if ! test -f "$1" && ! test -d "$1"; then
		test -z "$2" || _abort "No such file or directory '$1'"
	else
		_msg "remove '$1'"
		rm -rf "$1" || _abort "rm -rf '$1'"
	fi
}


#--
# Rsync $1 to $2. Apply rsync parameter $3 if set (e.g. --delete).
#
# @param source path e.g. user@host:/path/to/source
# @param target path default=[.]
# @param optional rsync parameter e.g. "--delete --exclude /data"
#--
function _rsync {
	local target="$2"
	test -z "$target" && target="."

	test -z "$1" && _abort "Empty rsync source"
	test -d "$target" || _abort "No such directory [$target]"

	local rsync="rsync -av $3 -e ssh '$1' '$2'"
	local error
	_log "$rsync" rsync
	eval "$rsync ${LOG_CMD[rsync]}" || error=1

	if test "$error" = "1"; then
		test -z "$(tail -4 "${LOG_FILE[rsync]}" | grep 'speedup is ')" && _abort "$rsync"
		test -z "$(tail -1 "${LOG_FILE[rsync]}" | grep "rsync error:")" || \
			_msg "[WARNING]: FIX rsync errors in ${LOG_FILE[rsync]}"
	fi
}


#--
# Abort if user is not root. If sudo cache time is ok allow sudo with $1 = 1.
#
# @param try sudo
#--
function _run_as_root {
	test "$UID" = "0" && return

	if test -z "$1"; then
		_abort "Please change into root and try again"
	else
		echo "sudo true - you might need to type in your password"
		sudo true 2>/dev/null || _abort "sudo true failed - Please change into root and try again"
	fi
}


#--
# Wrapper to scp. Check md5sum first - don't copy if md5sum is same.
# @param source
# @param target
# shellcheck disable=SC2029
#--
function _scp {
	local user host path md5 md5remote

	if [[ "$1" =~ ^(.+)@(.+):(/.+) ]]; then
		test -f "$2" && md5=$(_md5 "$2")
	elif [[ "$2" =~ ^(.+)@(.+):(/.+) ]]; then
		test -f "$1" && md5=$(_md5 "$1")
	else
		_abort "neither [$1] or [$2] are remote"
	fi

	user="${BASH_REMATCH[1]}"
	host="${BASH_REMATCH[2]}"
	path="${BASH_REMATCH[3]}"

	if test -z "$md5"; then
		md5remote=1
	else
		md5remote=$(ssh "$user@$host" "md5sum '$path'" 2>/dev/null | awk '{print $1}')
	fi

	if test "$md5" = "$md5remote"; then
		echo "$path at $host has not changed" 
	else
		echo "scp $1 $2"
		scp "$1" "$2" >/dev/null || _abort "scp $1 $2" 
	fi
}


#--
# Control service start|stop|restart|reload|enable|disable
# @param service name
# @param action
#--
function _service {
	test -z "$1" && _abort "empty service name"
	test -z "$2" && _abort "empty action"

	local is_active
	is_active=$(systemctl is-active "$1")

	if [[ "$is_active" != 'active' && ! "$2" =~ start && ! "$2" =~ able ]]; then
		_abort "$is_active service $1"
	fi

	if test "$2" = 'status'; then
		_ok "$1 is active"
		return
	fi

	_msg "systemctl $2 $1"
	_sudo "systemctl $2 $1"
}


#--
# Save value as $name.nfo (in $RKBASH_DIR/$APP).
#
# @param string name (required)
# @param string value
# @global RKBASH_DIR
#--
function _set {
	local dir

	dir="$RKBASH_DIR"
	test "$dir" = "$HOME/.rkbash/$$" && dir="$HOME/.rkbash"
	dir="$dir/$(basename "$APP")"

	_mkdir "$dir"
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$dir/$1.nfo"
}


#--
# Run shellcheck for *.sh files in directory $1 and subdirectories
# @param directory
# shellcheck disable=SC2034,SC2207
#--
function _shell_check {
	_require_dir "$1"
	local sh_files file
	sh_files=( $(find "$1" -name '*.sh' 2>/dev/null) )

	PROGRESS_MAX=${#sh_files[@]}
	PROGRESS_LABEL="shellcheck"
	for ((PROGRESS_VALUE=0; PROGRESS_VALUE < ${#sh_files[@]}; PROGRESS_VALUE++)); do
		file="${sh_files[$PROGRESS_VALUE]}"
		PROGRESS_MSG="$file"
		_progress_bar "$PROGRESS_VALUE"
		shellcheck "$file" &>/dev/null || _abort "shellcheck $file"
	done
}


#--
# Show list with $linebreak entries per line.
#
# @param list
# @param linebreak
# @param label (optional)
#--
function _show_list {
	local i a
	i=0

	if test -n "$3"; then
		echo ""
		_label "$3"
	fi

	for a in $1; do
		i=$((i+1))
		echo -n "$a "

		n=$((i%$2))
		test "$n" = "0" && echo ""
	done

	echo ""
}


#--
# Sort (unique) whitespace list. No whitespace in list elements allowed.
# @param $@ list elements
#--
function _sort {
	echo "$@" | xargs -n1 | sort -u | xargs
}


#--
# Split string "$2" at "$1" (export as $SPLIT[@]).
# @param delimter
# @param string (or /dev/stdin if unset)
# @export array SPLIT
# @echo
#--
function _split {
	local txt
	test -z "${2+x}" && txt=$(cat /dev/stdin) || txt="$2"

	IFS="$1" read -ra SPLIT <<< "$txt"
	echo "${SPLIT[@]}"
}


#--
# Split shell script $1 into *.inc.sh functions in $1_. Header is named 0_header.inc.sh
# and footer is name Z_main.inc.sh. Inverse of _merge_sh.
#
# @param path to shell script
# @global RKBASH_DIR
#--
function _split_sh {
	_require_file "$1"
	local output_dir
	output_dir="$(basename "$1")_"
	test -d "$output_dir" && _rm "$output_dir" >/dev/null
	_mkdir "$output_dir"

  local split_awk
IFS='' read -r -d '' split_awk <<'EOF'
BEGIN{ fn = "_OUT_/split_1.inc.sh"; n = 1; open = 0; }
{
	if (substr($0,1,3) == "#--") {
		if (open) {
			open = 0
		}
		else {
			close (fn)
			n++
			fn = "_OUT_/split_" n ".inc.sh"
			open = 1
		}
	}

	print > fn
}
EOF

	_require_global RKBASH_DIR
	_msg "Split $1 into"
	_mkdir "$RKBASH_DIR"
	echo -e "$split_awk" | sed -E "s/_OUT_/$output_dir/g" >"$RKBASH_DIR/split_sh.awk"
	awk -f "$RKBASH_DIR/split_sh.awk" "$1"

	local a func
	for a in "$output_dir"/*.inc.sh; do
		func=$(grep -E '^function [a-zA-Z0-9_]+ \{' "$a" | sed -E 's/function ([a-zA-Z0-9_]+) \{/\1/')

		if test -z "$func"; then
			if test "$a" = "$output_dir/split_1.inc.sh"; then
				func="0_header"
			else
				func="Z_main"
				echo -e "#!/bin/bash\n" > "$output_dir/$func.inc.sh"
			fi
		else
			echo -e "#!/bin/bash\n" > "$output_dir/$func.inc.sh"
		fi

		_msg "  $output_dir/$func.inc.sh"
		head -n -1 "$a" >> "$output_dir/$func.inc.sh"
		tail -1 "$a" | sed '/^$/d' >> "$output_dir/$func.inc.sh"
		_rm "$a" >/dev/null
	done
}


#--
# If query is longer than 60 chars return "${1:0:60} ...".
# @param query
# @echo 
#--
function _sql_echo {
	local query
	query="$1"
	test ${#query} -gt 60 && query="${query:0:60} ..."
	echo -n "$query"
}


#--
# Run sql execute query (no result).
#
# @param sql query
# @param flag (1=execute sql without confirmation)
# @global SQL
#--
function _sql_execute {
	local query="$1"
	test -z "$query" && _abort "empty sql execute query"
	_require_global SQL

	if test "$2" = "1"; then
		echo "execute sql query: $(_sql_echo "$query")"
		$SQL "$query" || _abort "$query"
	else
		_confirm "execute sql query: $(_sql_echo "$query")? " 1
		test "$CONFIRM" = "y" && { $SQL "$query" || _abort "$query"; }
	fi
}


#--
# Print sql select result table.
#
# @global SQL
# @param type query
#--
function _sql_list {
	local query="$1"
	test -z "$query" && _abort "empty query in _sql_list"
	_require_global SQL

	$SQL "$query" || _abort "$query"
}


#--
# Load sql dump $1 (ask). Based on rks-db - implement custom _sql_load if missing.
# If flag=1 load dump without confirmation.
#
# @param sql dump
# @param flag
# shellcheck disable=SC2034
#--
function _sql_load {
	_require_program "rks-db"
	_require_file "$1"

	test "$2" = "1" && AUTOCONFIRM=y
	_confirm "load sql dump '$1'?" 1
	test "$CONFIRM" = "y" && rks-db load "$1" --q1=n --q2=y >/dev/null
}


declare -A SQL_PARAM
declare -A SQL_SEARCH

#--
# Return processed query string. Insert SQL_PARAM hash.
# Use SQL_PARAM[SEARCH] string to replace WHERE_SEARCH|AND_SEARCH tag.
# Use SQL_SEARCH hash to create SQL_PARAM[SEARCH].
#
# @global SQL_SEARCH (hash) SQL_PARAM (hash)
# @param string query
# @return string
# shellcheck disable=SC2068
#--
function _sql_querystring {
	if test "${#SQL_SEARCH[@]}" -gt 0; then
		SQL_PARAM[SEARCH]=

		local val key
		for key in ${!SQL_SEARCH[@]}; do
			val="${SQL_SEARCH[$key]}"

			if [[ -z "$val" || -z "${val//%/}" || -z "${val//\*/}" ]]; then
				:
			elif [[ "${val: -1}" = "%" || "${val:0:1}"  = "%" ]]; then
				SQL_PARAM[SEARCH]="${SQL_PARAM[SEARCH]} AND $key LIKE '$val'"
			elif [[ "${val: -1}" = "*" || "${val:0:1}"  = "*" ]]; then
				SQL_PARAM[SEARCH]="${SQL_PARAM[SEARCH]} AND CONVERT($key USING utf8mb4) LIKE '${val//\*/%}'"
			else
				SQL_PARAM[SEARCH]="${SQL_PARAM[SEARCH]} AND $key='$val'"
			fi
		done
	fi

	local query="$1"
	if test -n "${SQL_PARAM[SEARCH]}"; then
		query="${query//WHERE_SEARCH/WHERE 1=1 ${SQL_PARAM[SEARCH]}}"
		query="${query//AND_SEARCH/${SQL_PARAM[SEARCH]}}"
		SQL_PARAM[SEARCH]=
	fi

	local a
	for a in WHERE_SEARCH AND_SEARCH; do
		query="${query//$a/}"
	done

	for a in "${!SQL_PARAM[@]}"; do
		query="${query//\'$a\'/\'${SQL_PARAM[$a]}\'}"
	done

	test -z "$query" && _abort "empty query in _sql"
	echo "$query"
}


declare -A SQL_COL

#--
# Run sql select query. Save result of select query to SQL_COL. 
# Add SQL_COL[_all] (=STDOUT) and SQL_COL[_rows].
#
# BEWARE: don't use `_sql_select ...` or $(_sql_select) - SQL_COL will be empty (subshell execution)
#
# @global SQL SQL_COL (hash)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @return boolean (if type=select - false = no result)
# shellcheck disable=SC2034
#--
function _sql_select {
	local dbout lnum line1 line2 query i ckey cval
	query="$1"
	test -z "$query" && _abort "empty query in _sql_select"
	_require_global SQL

	dbout=$($SQL "$query" || _abort "$query")
	lnum=$(echo "$dbout" | wc -l)

	SQL_COL=()
	SQL_COL[_all]="$dbout"
	SQL_COL[_rows]=$((lnum - 1))

	if test "$lnum" -eq 2; then
		line1=$(echo "$dbout" | head -1)
		line2=$(echo "$dbout" | tail -1)

		IFS=$'\t' read -ra ckey <<< "$line1"
		IFS=$'\t' read -ra cval <<< "$line2"

		for (( i=0; i < ${#ckey[@]}; i++ )); do
			SQL_COL[${ckey[$i]}]="${cval[$i]}"
		done

		return 0  # true single line result
	elif test "$lnum" -lt 2; then
		return 1  # false = no result
	else
		_abort "_sql select: multi line result ($lnum lines)\nUse _sql list ..."
	fi
}


SQL=
declare -A SQL_QUERY

#--
# Run _sql[list|execute|select]. Query is either $2 or SQL_QUERY[$2] (if set). 
# If $1=execute ask if query $2 should be execute (default=y) or skip. 
# Set SQL (default SQL="rks-db query") and SQL_QUERY (optional).
# See _sql_querystring for parameter and search parameter replace.
# See _sql_select for SQL_COL results.
#
# BEWARE: don't use `_sql select ...` or $(_sql select) - SQL_COL will be empty (subshell execution)
#
# @global SQL SQL_QUERY (hash)
# @export SQL (=rks-db query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @return boolean (if type=select - false = no result)
#--
function _sql {
	if test -z "$SQL"; then
		if test -s "/usr/local/bin/rks-db"; then
			SQL='rks-db query'
		else
			_abort "set SQL="
		fi
	fi

	local action query
	action="$1"
	query="$2"

	if [[ "$1" =~ ^(list|execute|select)_([a-z]+)$ ]]; then
		action="${BASH_REMATCH[1]}"
		query="$1"
		test -z "${SQL_QUERY[$query]}" && _abort "invalid action $action - no such query key $query"
	fi

	test -z "${SQL_QUERY[$query]}" || query="${SQL_QUERY[$query]}"
	query=$(_sql_querystring "$query")

	if test "$action" = "select"; then
		_sql_select "$query"
	elif test "$action" = "execute"; then
		_sql_execute "$query" "$3"
	elif test "$action" = "list"; then
		_sql_list "$query"
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute|list or ACTION_QKEY"
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
# @global RKBASH_DIR 
# shellcheck disable=SC2012
#--
function _sql_transaction {
	local flag sql_dir st et sql_dump tables acf i
	flag=$(($2 + 0))
	sql_dir="$1"
	st="START TRANSACTION;"
	et="COMMIT;"

	_require_global RKBASH_DIR
	_require_dir "$sql_dir"
	_mkdir "$RKBASH_DIR/sql_transaction"

	if test -s "$sql_dir/tables.txt"; then
		tables=( "$(cat "$sql_dir/tables.txt")" )
	else
		tables=( "$(ls "$sql_dir/"*_*.sql | sed -E 's/^.+?\/([a-z0-9_]+)\.sql$/\1/i')" )
		st="$st\nSET FOREIGN_KEY_CHECKS=0;"
		et="SET FOREIGN_KEY_CHECKS=1;\n$et"
	fi

	test ${#tables[@]} -lt 1 && _abort "table list is empty"
	test $((flag & 32)) -eq 32 && acf=y

	if test $((flag & 1)) -eq 1; then	
		sql_dump="$RKBASH_DIR/sql_transaction/drop.sql"
		echo -e "$st\n" >"$sql_dump"
		for ((i = ${#tables[@]} - 1; i > -1; i--)); do
			echo "DROP TABLE IF EXISTS ${tables[$i]};" >>"$sql_dump"
		done 
		echo -e "\n$et" >>"$sql_dump"

		AUTOCONFIRM=$acf
		_confirm "Drop ${#tables[@]} tables (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi

	if test $((flag & 2)) -eq 2; then	
		sql_dump="$RKBASH_DIR/sql_transaction/create.sql"
		echo -e "$st\n" >"$sql_dump"
		for ((i = 0; i < ${#tables[@]}; i++)); do
			cat "$sql_dir/${tables[$i]}.sql" >>"$sql_dump"
		done
		echo -e "\n$et" >>"$sql_dump"

		AUTOCONFIRM=$acf
		_confirm "Create tables (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi

	test $((flag & 4)) -eq 4 && _sql_transaction_load "$sql_dir" alter $acf
	test $((flag & 8)) -eq 8 && _sql_transaction_load "$sql_dir" update $acf
	test $((flag & 16)) -eq 16 && _sql_transaction_load "$sql_dir" insert $acf
}


#--
# Helper function. Load $1.
#
# @parma sql directory path
# @param name (alter|insert|update)
# @param autoconfirm
# @global RKBASH_DIR
# shellcheck disable=SC2034
#--
function _sql_transaction_load {
	local sql_dump
	sql_dump="$RKBASH_DIR/sql_transaction/$2.sql"
	_rm "$sql_dump" >/dev/null

	if test -s "$1/$2.sql"; then
		_cp "$1/$2.sql" "$sql_dump"
	elif test -d "$1/$2"; then
		cat "$1/$2/*.sql" > "$sql_dump"
	fi

	if test -s "$sql_dump"; then
		AUTOCONFIRM="$3"
		_confirm "Execute $2 queries (load $sql_dump)?"
		test "$CONFIRM" = "y" && _sql_load "$sql_dump" 1
	fi
}


#--
# Copy content from www_src to www.  and *.js files from src/javascript.
#
# @global SRC2WWW_FILES SRC2WWW_DIR SRC2WWW_RKJS_DIR SRC2WWW_RKJS_FILES
#--
function _src2www_copy {
	local a

	for a in $SRC2WWW_FILES $SRC2WWW_DIR; do
		cp -r "www_src/$a" www/
	done

	if test -n "$SRC2WWW_RKJS_FILES"; then
		_require_global SRC2WWW_RKJS_DIR
		for a in $SRC2WWW_RKJS_FILES; do
			cp "$SRC2WWW_RKJS_DIR/$a" www/js/
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
	_cp www_src/header.html www/index.html

	test -f www_src/app_header.html && cat www_src/app_header.html >>www/index.html
	cat www_src/main.html >>www/index.html
	test -f www_src/app_footer.html && cat www_src/app_footer.html >>www/index.html

	local a

	for a in www_src/*.inc.html; do
		cat "$a" >> www/index.html
	done

	if test -f www_src/main.js; then
		{
			echo '<div id="app_main" style="display:none">'
			cat www_src/main.html
			echo '</div><script>'
			cat www_src/main.js
			echo '</script>'
		} >>www/index.html
	fi

	cat www_src/footer.html >> www/index.html
}


#--
# Create ssh key authentication for server $1 (rk@server.tld).
# @param user@domain.tld
# shellcheck disable=SC2086
#--
function _ssh_auth {
	echo "create ssh keys for password less authentication"

	if ! test -f ~/.ssh/id_rsa.pub; then
		echo "creating local public+private key: ~/.ssh/id_rsa[.pub] - type 3x ENTER"
		ssh-keygen -t rsa
	fi

	local ssh_ok
	ssh_ok=$(ssh -o 'PreferredAuthentications=publickey' $1 "echo" 2>&1)

	if test -n "$ssh_ok"; then
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
# @os linux
#--
function _stop_http {
	_os_type linux

	if ! _is_running port:80; then
		_warn "no service on port 80"
		return
	fi

	if _is_running docker:80; then
		_warn "ignore docker service on port 80"
		return
	fi

	if _is_running nginx; then
		_service nginx stop
	elif _is_running apache; then
		_service apache2 stop
	fi
}


#--
# Switch to sudo mode. Switch back after command is executed.
#
# @global LOG_CMD[sudo] 
# @param command
# @param optional flag (1=try sudo if normal command failed)
# shellcheck disable=SC2034
#--
function _sudo {
	local curr_sudo exec flag
	curr_sudo="$SUDO"

	# ToDo: unescape $1 to avoid eval. Example: use [$EXEC] instead of [eval "$EXEC"]
	# and [_sudo "cp 'a' 'b'"] will execute [cp "'a'" "'b'"].
	exec="$1"

	# change $2 into number
	flag=$(($2 + 0))

	if test "$USER" = "root"; then
		_log "$exec" sudo
		eval "$exec ${LOG_CMD[sudo]}" || _abort "$exec"
	elif test $((flag & 1)) = 1 && test -z "$curr_sudo"; then
		_log "$exec" sudo
		eval "$exec ${LOG_CMD[sudo]}" || \
			( echo "try sudo $exec"; eval "sudo $exec ${LOG_CMD[sudo]}" || _abort "sudo $exec" )
	else
		SUDO=sudo
		_log "sudo $exec" sudo
		eval "sudo $exec ${LOG_CMD[sudo]}" || _abort "sudo $exec"
		SUDO="$curr_sudo"
	fi

	LOG_LAST=
}


#--
# Dump database on $1:$2. Require rks-db on both server.
# @param ssh e.g. user@domain.tld
# @param docroot or docroot/dump.sql
# shellcheck disable=SC2029,SC2012
#--
function _sync_db {
	local dir base last_dump ls_last_dump
	base=$(basename "$2")
	dir=$(dirname "$2")

	_require_program rks-db

	test -s "$base.gz" && _confirm "Use existing dump $base?" 1

	if test "$CONFIRM" = "y"; then
		last_dump="$base"
	elif test "${base: -4}" = ".sql"; then
		_msg "Create database dump $1:$2"
		ssh "$1" "cd '$dir' && rks-db dump '$base' --gzip --q1=y --q2=n --q3=n >/dev/null" || \
			_abort "ssh '$1' && cd '$dir' && rks-db dump '$base'"

		_msg 'Download dump'
		scp "$1:$2.gz" . || _abort "scp '$1:$2.gz' ."
		ssh "$1" "rm '$2.gz'" || _abort "ssh '$1' && rm '$2.gz'"
		last_dump="$base"
	else
		_msg "Create database dump in $1:$2/data/.sql"
		ssh "$1" "cd '$2' && rks-db dump --q1=y --q2=n --q3=n >/dev/null" || _abort "ssh '$1' && cd '$2' && rks-db dump"

		_msg 'Download dump'
		_rsync "$1:$2/data/.sql" "data/" >/dev/null

		ls_last_dump='data/.sql/mysql_dump_'$(date +'%Y%m%d')
		last_dump=$(ls "$ls_last_dump"* | tail -1)
	fi

	_msg "Import dump $last_dump"
	rks-db load "$last_dump" >/dev/null
}


#--
# Create php file with includes from source directory.
#
# @param source directory
# @param output file
# @global PATH_RKPHPLIB
# shellcheck disable=SC2028
#--
function _syntax_check_php {
	local a php_files php_bin
	php_files=$(find "$1" -type f -name '*.php')
	php_bin=$(grep -R -E '^#\!/usr/bin/php' "bin" | grep -v 'php -c skip_syntax_check' | sed -E 's/\:\#\!.+//')

	_require_global PATH_RKPHPLIB

	{
		echo -e "<?php\n\ndefine('APP_HELP', 'quiet');\ndefine('PATH_RKPHPLIB', '$PATH_RKPHPLIB');\n"
		echo -e "function _syntax_test(\$php_file) {\n  print \"\$php_file ... \";\n  include_once \$php_file;"
		echo -n '  print "ok\n";'
		echo -e "\n}\n"
	} >"$2"

	for a in $php_files $php_bin
	do
		if test -z "$(head -1 "$a" | grep 'php -c skip_syntax_check')"; then
			echo "_syntax_test('$a');" >> "$2"
		fi
	done
}


declare -A SYNTAX_CMD
declare -A SYNTAX_HELP

#--
# Abort with SYNTAX: message. Usually APP=$0.
# If $1 = "*" show join('|', ${!SYNTAX_CMD[@]}).
# If APP_DESC(_2|_3|_4) is set output APP_DESC\n\n(APP_DESC_2\n\n ...).
#
# @declare SYNTAX_CMD SYNTAX_HELP
# @global SYNTAX_CMD SYNTAX_HELP APP APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4 $APP_PREFIX 
# @param message
# @param info (e.g. cmd:* = show all SYNTAX_CMD otherwise show cmd|help:[name] = SYNTAX_CMD|SYNTAX_HELP[name])
#--
function _syntax {
	local a msg old_msg desc base syntax
	msg=$(_syntax_cmd "$1") 
	syntax="\n\033[1;31mSYNTAX:\033[0m"

	for a in $2; do
		old_msg="$msg"

		if test "${a:0:4}" = "cmd:"; then
			test "$a" = "cmd:" && a="cmd:$1"
			msg="$msg$(_syntax_cmd_other "$a")"
		elif test "${a:0:5}" = "help:"; then
			test "$a" = "help:" && a="help:$1"
			msg="$msg$(_syntax_help "${a:5}")"
		fi

		test "$old_msg" != "$msg" && msg="$msg\n"
	done

	test "${msg: -3:1}" = '|' && msg="${msg:0:-3}\n"

	base=$(basename "$APP")
	if test -n "$APP_PREFIX"; then
		echo -e "$syntax $(_warn_msg "$APP_PREFIX $base $msg")" 1>&2
	else
		echo -e "$syntax $(_warn_msg "$base $msg")" 1>&2
	fi

	for a in APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4; do
		test -z "${!a}" || desc="$desc${!a}\n\n"
	done
	echo -e "$desc" 1>&2

	exit 1
}


#--
# Return SYNTAX_CMD
# @param syntax message
#--
function _syntax_cmd {
	local a rx msg keys prefix
	keys=$(_sort "${!SYNTAX_CMD[@]}")
	msg="$1\n" 

	if test -n "${SYNTAX_CMD[$1]}"; then
		msg="${SYNTAX_CMD[$1]}\n"
	elif test "${1: -1}" = "*" && test "${#SYNTAX_CMD[@]}" -gt 0; then
		if test "$1" = "*"; then
			rx='^[a-zA-Z0-9_]+$'
		else
			prefix="${1:0:-1}"
			rx="^${1:0:-2}"'\.[a-zA-Z0-9_\.]+$'
		fi

		msg=
		for a in $keys; do
			grep -E "$rx" >/dev/null <<< "$a" && msg="$msg|${a/$prefix/}"
		done
		msg="${msg:1}\n"
	elif [[ "$1" = *'.'* && -n "${SYNTAX_CMD[${1%%.*}]}" ]]; then
		msg="${SYNTAX_CMD[${1%%.*}]}\n"
	fi

	echo "$msg"
}


#--
# Return additional SYNTAX_CMD information
# @param 
#--
function _syntax_cmd_other {
	local a rx msg keys base
	keys=$(_sort "${!SYNTAX_CMD[@]}")
	rx="$1"

	test "${rx:4}" = "*" && rx='^[a-zA-Z0-9_]+$' || rx="^${rx:4:-2}"'\.[a-zA-Z0-9_]+$'

	base=$(basename "$APP")
	for a in $keys; do
		grep -E "$rx" >/dev/null <<< "$a" && msg="$msg\n$base ${SYNTAX_CMD[$a]}"
	done

	echo "$msg"
}


#--
# Return SYNTAX_HELP information
# @param 
#--
function _syntax_help {
	local a rx msg keys prefix
	keys=$(_sort "${!SYNTAX_HELP[@]}")

	if test "$1" = '*'; then
		rx='^[a-zA-Z0-9_]+$'
	elif test "${1: -1}" = '*'; then
		rx="^${rx: -2}"'\.[a-zA-Z0-9_\.]+$'
	fi

	for a in $keys; do
		if test "$a" = "$1"; then
			msg="$msg\n${SYNTAX_HELP[$a]}"
		elif test -n "$rx" && grep -E "$rx" >/dev/null <<< "$a"; then
			prefix=$(sed -E 's/^[a-zA-Z0-9_]+\.//' <<< "$a")
			msg="$msg\n$prefix: ${SYNTAX_HELP[$a]}\n"
		fi
	done

	[[ -n "$msg" && "$msg" != "\n$APP_DESC" ]] && echo -e "$msg"
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
# @param string name (use /dev/stdin if not set)
# shellcheck disable=SC2120
#--
function _trim {
	local input
	test -z "${1+x}" && input=$(cat /dev/stdin) || input="$1"
	echo -e "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}


#--
# Replace text in file or append text to file.
# Ask (default = y) and backup first. 
# For replace use s/orig/replace/ or s#orig#replace#g 
# otherwise $1 will be appended to $2.
#
# @param sed replace expression (-E) or append text
# @param file
#--
function _update_file {
	_require_file "$2"

	if [[ "${1:0:1}" = 's' && ( "${1:1:1}" = '/'  || "${1:1:1}" = '#' ) ]]; then
		_confirm "Apply replace $1\nto $2" 1
		if test "$CONFIRM" = 'y'; then
			_backup_file "$2"
			sed -i -E "$1" "$2"
		fi
	else
		_confirm "Append '$2'\nto $2" 1
		if test "$CONFIRM" = 'y'; then
			_backup_file "$2"
			echo "$1" >> "$2"
		fi
	fi
}

#--
# Link /bin/sh to /bin/shell.
#
# @abort
# @param abort message
#--
function _use_shell {
	test -L "/bin/sh" || _abort "no /bin/sh link"
	test -f "/bin/$1" || _abort "no such shell /bin/$1"

	if test -n "$(diff -u /bin/sh "/bin/$1")"; then
		_rm /bin/sh
		_cd /bin
		_ln "$1" sh
		_cd "$CURR" 
	fi
}


#--
# Return program version nn[.mm.kk]
# If $1 is not version number '$1 --version' must be supported
# If $2=1 convert nn.mm.kk into number e.g. 3.0.8 = 30008, 14.22.72 = 142272 
# If $2=2 return main version (nn)
# If $2=4 return main.sub version (nn.mm)
#
# @param program name or version number (nn.mm.kk)
# @param optional flag
# @print int
# shellcheck disable=SC2183,SC2046
#--
function _version {
	local flag version
	flag=$(($2 + 0))

	if [[ "$1" =~ ^v?[0-9\.]+$ ]]; then
		version="$1"
	elif command -v "$1" &>/dev/null; then
		version=$({ $1 --version || _abort "$1 --version"; } | head -1 | grep -E -o 'v?[0-9]+\.[0-9\.]+')
	fi

	version="${version/v/}"

	[[ "$version" =~ ^[0-9\.]+$ ]] || _abort "version detection failed ($1)"

	if [[ $((flag & 1)) = 1 ]]; then
		if [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%d%02d" $(echo "$version" | tr '.' ' ')
		elif [[ "$version" =~ ^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			printf "%d%02d%02d" $(echo "$version" | tr '.' ' ')
		else
			_abort "failed to convert $version to number"
		fi
	elif [[ $((flag & 2)) ]]; then
		echo -n "${version%%.*}"
	elif [[ $((flag & 4)) ]]; then
		echo -n "${version%.*}"
	else
		echo -n "$version"
	fi
}


#--
# @example x="Error\nInfo" && echo -e "$(_warn_msg "$x")"
# @param multiline
# @return multiline with first line in red
#--
function _warn_msg {
	local line first
	while IFS= read -r line; do
		if test "$first" = '1'; then
			echo "$line"
		else
			echo '\033[0;31m'"$line"'\033[0m'
			first=1
		fi
	done <<< "$@"
}


#--
# Print warning (red color message to stdout and stderr)
#
# @param message
#--
function _warn {
	echo -e "\033[0;31m$1\033[0m" 1>&2
}


#--
# Link php/rkphplib to /webhome/.php/rkphplib if $1 & 1=1.
# Link php/phplib to /webhome/.php/phplib if $1 & 2=2.
#
# @param int flag
# shellcheck disable=SC2128
#--
function _webhome_php {
	local i dir flag git_dir
	flag=$(($1 + 0))

	test $((flag & 1)) -eq 1 && git_dir=( "rkphplib" )
	test $((flag & 2)) -eq 2 && git_dir=( "$git_dir" "phplib" )

	_mkdir php
	_cd php 

	for ((i = 0; i < ${#git_dir[@]}; i++)); do
 		dir="${git_dir[$i]}"
		_require_dir "/webhome/.php/$dir"

		if test -d "$dir"; then
			_cd "$dir"
			git pull
			_cd ..
		else
			ln -s "/webhome/.php/$dir" "$dir" || _abort "ln -s '/webhome/.php/$dir' '$dir'"
		fi
	done

	_cd ..
}


#--
# Make directory $1 read|writeable for webserver.
#
# @param directory path
#--
function _webserver_rw_dir {
	test -d "$1" || _abort "no such directory $1"
	local me server_user

	if test -s "/etc/apache2/envvars"; then
		server_user=$(grep -E '^export APACHE_RUN_USER=' /etc/apache2/envvars | sed -E 's/.*APACHE_RUN_USER=//')
	fi

	if [[ -n "$server_user" && "$server_user" = "$(stat -c '%U' "$1")" ]]; then
		echo "directory $1 is already owned by webserver $server_user"
		return
	fi

	_chmod 770 "$1"

	me="$USER"
	test -z "$SUDO_USER" || me="$SUDO_USER"

	_chown "$1" "$me" "$server_user"
}


#--
# Download URL with wget. Autocreate target path.
#
# @param url
# @param save as default = autodect, use "-" for stdout
#--
function _wget {
	local save_as

	test -z "$1" && _abort "empty url"
	_require_program wget

	save_as=${2:-$(basename "$1")}
	if test -s "$save_as"; then
		_confirm "Overwrite $save_as" 1
		if test "$CONFIRM" != "y"; then
			echo "keep $save_as - skip wget '$1'"
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
		_mkdir "$(dirname "$2")"
		echo "download $1 to $2"
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
	fi

	local new_files
	if test -z "$2"; then
		if ! test -s "$save_as"; then
			new_files=$(find . -amin 1 -type f)
			test -z "$new_files" && _abort "Download $1 failed"
		fi
	elif ! test -s "$2"; then
		_abort "Download $2 to $1 failed"
	fi
}


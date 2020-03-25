#!/bin/bash

declare -A _SQL_PARAM
declare -A _SQL_SEARCH

#--
# Return processed query string. Insert _SQL_PARAM hash.
# Use _SQL_PARAM[SEARCH] string to replace WHERE_SEARCH|AND_SEARCH tag.
# Use _SQL_SEARCH hash to create _SQL_PARAM[SEARCH].
#
# @global _SQL_SEARCH (hash) _SQL_PARAM (hash)
# @param string query
# @return string
#--
function _sql_querystring {
	local QUERY="$1"

	if test "${#_SQL_SEARCH[@]}" -gt 0; then
		_SQL_PARAM[SEARCH]=

		local val; local key;
		for key in ${!_SQL_SEARCH[@]}; do
			val="${_SQL_SEARCH[$key]}"

			if [[ -z "$val" || "$val" = "%" ]]; then
				:
			elif [[ "${val: -1}" = "%" || "${val:0:1}"  = "%" ]]; then
				SLIST_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND $a LIKE '$val'" 
			elif [[ "${val: -1}" = "*" || "${val:0:1}"  = "*" ]]; then
				SLIST_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND CONVERT($a USING utf8mb4) LIKE '${val//*/%}'" 
			else
				SLIST_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND $a='${SLIST[$a]}'" 
			fi
		done
	fi

	if ! test -z "${_SQL_PARAM[SEARCH]}"; then
		QUERY="${QUERY//WHERE_SEARCH/WHERE 1=1 ${_SQL_PARAM[SEARCH]}}"
		QUERY="${QUERY//AND_SEARCH/${_SQL_PARAM[SEARCH]}}"
		_SQL_PARAM[SEARCH]=
	fi

	local a

	for a in WHERE_SEARCH AND_SEARCH; do
		QUERY="${QUERY//$a/}"
	done

	for a in "${!_SQL_PARAM[@]}"; do
		QUERY="${QUERY//\'$a\'/\'${_SQL_PARAM[$a]}\'}"
	done

	test -z "$QUERY" && _abort "empty query in _sql"

	echo "$QUERY"
}


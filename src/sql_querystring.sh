#!/bin/bash

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


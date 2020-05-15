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
# shellcheck disable=SC2068
#--
function _sql_querystring {
	if test "${#_SQL_SEARCH[@]}" -gt 0; then
		_SQL_PARAM[SEARCH]=

		local val  key
		for key in ${!_SQL_SEARCH[@]}; do
			val="${_SQL_SEARCH[$key]}"

			if [[ -z "$val" || -z "${val//%/}" || -z "${val//\*/}" ]]; then
				:
			elif [[ "${val: -1}" = "%" || "${val:0:1}"  = "%" ]]; then
				_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND $key LIKE '$val'"
			elif [[ "${val: -1}" = "*" || "${val:0:1}"  = "*" ]]; then
				_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND CONVERT($key USING utf8mb4) LIKE '${val//\*/%}'"
			else
				_SQL_PARAM[SEARCH]="${_SQL_PARAM[SEARCH]} AND $key='$val'"
			fi
		done
	fi

	local query="$1"
	if ! test -z "${_SQL_PARAM[SEARCH]}"; then
		query="${query//WHERE_SEARCH/WHERE 1=1 ${_SQL_PARAM[SEARCH]}}"
		query="${query//AND_SEARCH/${_SQL_PARAM[SEARCH]}}"
		_SQL_PARAM[SEARCH]=
	fi

	local a
	for a in WHERE_SEARCH AND_SEARCH; do
		query="${query//$a/}"
	done

	for a in "${!_SQL_PARAM[@]}"; do
		query="${query//\'$a\'/\'${_SQL_PARAM[$a]}\'}"
	done

	test -z "$query" && _abort "empty query in _sql"
	echo "$query"
}


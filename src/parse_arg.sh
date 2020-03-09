#!/bin/bash

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


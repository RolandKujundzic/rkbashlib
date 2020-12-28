#!/bin/bash

#--
# Filter git status with rks-filter diff
# @param directory list
#--
function _git_status {
	local a change files

	_require_program 'rks-filter'

  for a in $1; do
		files="$files $(git status | grep "$a/" | sed -E 's#^.+src/#src/#')"
	done

	for a in $files; do
    change=$(git diff --color=always "$a" | rks-filter diff | \
      sed -E -e 's#diff .+##' -e 's#index .+##' -e 's#\-\-\- .+##' -e 's#\+\+\+ .+##' | xargs | \
      sed -E -e 's/[^a-z0-9]//gi' -e 's/1m//g')
  
    if test -z "$change"; then
      _ok "$a"
    else
      git diff --color=always "$a" | rks-filter diff
    fi
  done
}


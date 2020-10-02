#!/bin/bash

#--
# Abort git pull if longer than 30 sec
#--
function _git_pull {
	timeout 30 git pull >/dev/null || _abort "timeout 30 git pull # in $PWD"
}


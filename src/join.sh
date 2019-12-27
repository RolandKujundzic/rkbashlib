#!/bin/bash

#--
# Join parameter with first parameter as delimiter.
# @echo 
#--
function _join {
  local IFS="$1"
  echo "${*:2}" # same as: shift; echo "$*";
}


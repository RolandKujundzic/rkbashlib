#!/bin/bash

#------------------------------------------------------------------------------
# Check if ip_address is ip4.
#
# @param ip_address
# @require _abort 
#------------------------------------------------------------------------------
function _is_ip4 {
  local is_ip4=`echo "$1" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'`

  if test -z "$is_ip4"; then
    _abort "Invalid ip4 address [$1] use e.g. 32.123.7.38"
  fi
}


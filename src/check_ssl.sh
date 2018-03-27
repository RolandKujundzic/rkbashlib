#!/bin/bash

#------------------------------------------------------------------------------
# Print ssl public key status (in /etc/letsencrypt/live/).
# 
# @export ENDDATE
# @param string domain
# @print valid, missing or expired
#------------------------------------------------------------------------------
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


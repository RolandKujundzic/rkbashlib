#!/bin/bash

#------------------------------------------------------------------------------
function _check_ssl_certificate {
  if ! test -f "live/$1/fullchain.pem"; then
    _abort "No such domain $1"
  fi

  ENDDATE=`openssl x509 -enddate -noout -in live/$1/fullchain.pem`  # e.g. notAfter=Nov 12 10:38:00 2017 GMT
  export ENDDATE=${ENDDATE:9}
  CERT_STATUS=$(php -r 'print strtotime(getenv("ENDDATE")) > time() + 3600 * 24 * 14 ? "valid" : "expired";')
}


#------------------------------------------------------------------------------
function _create_ssl_certificate {

  if test -z "$1" || test -z "$2"; then
    _syntax "create [sub.]domain.tld path/to/docroot"
  fi

  if ! test -d "$2"; then
    _abort "invalid document root $2"
  fi

  if test -f "live/$1/fullchain.pem"; then
    _check_ssl_certificate $1

    if test "$CERT_STATUS" = "valid"; then
      echo "$1 has $CERT_STATUS certificate: $ENDDATE"
      return
    fi
  fi

  echo -e "\ncreate|update ssl certificate for $1:"
  certbot --webroot --webroot-path $2 --keep-until-expiring -d $1 certonly
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

APP=$0
APP_DESC="Create lets_encrypt SSL certificate"

_run_as_root
_cd /etc/letsencrypt

case $1 in
check)
  if test -z "$2"; then
    _syntax "check [sub.]domain.tld"
  fi

  _check_ssl_certificate $2
  echo -e "\n$CERT_STATUS: $ENDDATE\n"
  ;;
create)
  _create_ssl_certificate
  ;;
*)
  _syntax "[create|check]"
esac


#!/bin/bash

#------------------------------------------------------------------------------
# Stop webserver (apache2, nginx) on port 80 if running.
# Ignore docker webservice on port 80.
#
# @require is_running
#------------------------------------------------------------------------------
function _stop_http {
  if test "$(_is_running PORT 80)" != "PORT_running"; then
    echo "no service on port 80"
    return
  fi 

  if test "$(_is_running DOCKER_PORT_80)" = "DOCKER_PORT_80_running"; then
    echo "ignore docker service on port 80"
    return
  fi

  if test "$(_is_running NGINX)" = "NGINX_running"; then
    echo "stop nginx"
    sudo service nginx stop
    return
  fi

  if test "$(_is_running APACHE2)" = "APACHE2_running"; then
    echo "stop apache2"
    sudo service apache2 stop
    return
  fi
}

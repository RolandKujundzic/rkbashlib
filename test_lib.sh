#!/bin/bash
# shellcheck disable=SC1091,SC2034

source lib/rkbash.lib.sh || { echo "ERROR: source lib/rkbash.lib.sh"; exit 1; }


#--
# M A I N
#--

_install_node remove
_node_current

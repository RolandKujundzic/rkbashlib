#!/bin/bash

NO_ABORT=1

_msg "\ncheck privileges of non existing file xyz" -e
_require_priv xyz 755 
_msg "check privileges of ./run.sh ... " -n
_require_priv run.sh 755 && _msg "ok" || _msg "error" 
_msg "done" -e

NO_ABORT=

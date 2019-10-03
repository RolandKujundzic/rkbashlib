#!/bin/bash

#------------------------------------------------------------------------------
# Clean apt installation.
#
# @require _abort _run_as_root
#------------------------------------------------------------------------------
function _apt_clean {
	_run_as_root
	apt -y clean || _abort "apt -y clean"
	apt -y autoclean || _abort "apt -y autoclean"
	apt -y install -f || _abort "apt -y install -f"
	apt -y autoremove || _abort "apt -y autoremove"
}


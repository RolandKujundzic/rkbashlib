#!/bin/bash

#--
# Run test.
#--
function _test {
	if test -f "test/run.php"; then
		php test/run.php
	fi
}


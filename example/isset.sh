#!/bin/bash

function isset {
	[ -z ${1+x} ] && echo "\$1 is unset" || echo "\$1='$1'"
}

isset
isset 0
isset ""
isset "abc"

#!/bin/bash

#--
#
#--
function _spinner {
	_abort "ToDo ..."

while :; do
	for s in / - \\ \|; do
		printf "\r$s"
		sleep .1
	done
done
}


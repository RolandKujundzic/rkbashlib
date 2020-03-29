#!/bin/bash

pipe=/dev/shm/rkscript.example.pipe

if [[ ! -p $pipe ]]; then
    echo "Reader not running"
    exit 1
fi


if [[ "$1" ]]; then
    echo "$1" >$pipe
else
    echo "Hello from $$" >$pipe
fi

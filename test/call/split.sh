#!/bin/bash

_split ";" "13;John;Doe"
echo "_SPLIT=(${_SPLIT[@]})=(${_SPLIT[0]}|${_SPLIT[1]}|${_SPLIT[2]})"

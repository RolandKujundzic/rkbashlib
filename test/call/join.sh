#!/bin/bash

ARR=( "a a" " bbb " "cc\ncc" )

_join ":" ${ARR[@]}
_join ":" ARR
_join ":" "ARR"
_join ":" "some string"

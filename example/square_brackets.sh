#!/bin/bash

echo "classic expression (no logical operators)"
[ "abc" == "abc" ] && echo "y" || echo "n"
[ "12" -ge 12 ]    && echo "y" || echo "n"
[ -s "x.sh" ]      && echo "y" || echo "n"
# invalid: [ 0 || 1 ] valid: if [ -s "x.sh" ] || [ -s "y.sh" ]; then ...

echo "extended expression (allows logical operators, ==, <=, >=, !=, <, >)"
[[ "abc" == "xbc" ]] && echo "y" || echo "n"
[[ "12" < 12 ]]      && echo "y" || echo "n"
[[ -s "?.sh" ]]      && echo "y" || echo "n"
[[ -s "x.sh" || -s "y.sh" ]]   && echo "y" || echo "n"


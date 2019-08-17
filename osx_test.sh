#!/bin/bash

echo -e "\nTest OSX compatibility wrapper"

. src/abort.sh
. src/osx.sh

echo -e "\nshow last modification, user, group and permissions of $0"
stat -c '%Y' $0
stat -c '%U' $0
stat -c '%G' $0
stat -c '%a' $0

echo -e "\nshow realpath of $0 and abc"
realpath $0
realpath abc

echo -e "\nshow md5sum of $0"
md5sum $0

echo -e "\ndone.\n"

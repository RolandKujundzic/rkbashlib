#!/bin/bash
#
# subshell: ( BASH_CODE )
# command grouping: { BASH_CODE; } - BEWARE: requires ";" before }
#

echo "start"

echo "subshell ( ... BASH_CODE ... ) example"
# ( code; ... code ) will invoke subshell - exit will apply only to subshell 
test "$UID" = "0" && ( echo -n "i am "; echo "root"; exit 0 ) || ( echo -n "i am not "; echo "root" )

echo "command grouping { ... BASH_CODE ... } example"
# { code; ... code; } will group commands - exit will apply
test "$UID" = "0" && { echo -n "i am "; echo "root"; exit 0; } || { echo -n "i am not "; echo "root"; }

echo "done."

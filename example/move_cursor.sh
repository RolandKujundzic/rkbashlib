#!/bin/bash


#--
# \033[<L>;<C>H			position the cursor at line L and column C (or \033[<L>;<C>f)
# \033[<N>A					move the cursor up N lines
# \033[<N>B					move the cursor down N lines
# \033[<N>C					move the cursor forward N columns
# \033[<N>D					move the cursor backward N columns
# \033[2J						clear the screen, move to (0,0)
# \033[K						erase to end of line
# \033[s						save cursor position
# \033[u						restore cursor position
#
# \033[ or \e[
#--

# display status with \033[* cursor command - see tput.sh
echo "Abort with [Ctrl]+[C]"

while :; do
	printf "\033[K"; echo "Status 1: $RANDOM"
	printf "\033[K"; echo "Status 2: $RANDOM"
	printf "\033[K"; echo "Status 3: $RANDOM"
	sleep 0.2
	printf "\033[3A"
done

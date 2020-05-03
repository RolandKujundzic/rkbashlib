# rkscript
Shell script library. More than 150 functions (04/2020).

## Examples

Include lib/rkscript.sh to use the library.

```sh
#!/bin/bash

source lib/rkscript.sh

_run_as_root

# other wrapper functions are: _rm, _mkdir, _chown, ...
_cp "does not exist.txt" "no such directory/test.txt"
```

Take a look at the src directory to see what is available.
Here is another example.

```sh
#!/bin/bash

source lib/rkscript.sh

_confirm "Do you want to continue?"
test "$CONFIRM"="y" || _abort "i quit"
```

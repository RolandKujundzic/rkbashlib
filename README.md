# rkbashlib
Bash script library. More than 170 functions (08/2020).

## Examples

Include [/usr/local/]lib/rkbash.lib.sh to use the library.

```sh
#!/bin/bash

source lib/rkbash.lib.sh

_run_as_root

# other wrapper functions are: _rm, _mkdir, _chown, ...
_cp "does not exist.txt" "no such directory/test.txt"
```

Take a look at the src directory to see what is available.
Here is another example.

```sh
#!/bin/bash

source lib/rkbash.lib.sh

_confirm "Do you want to continue?"
test "$CONFIRM"="y" || _abort "i quit"
```

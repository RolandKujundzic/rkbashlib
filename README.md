# rkscript
Collection of shell script snipplets (functions).

## Examples

Include lib/rkscript.sh to use the function collection.

```sh
. lib/rkscript.sh

_run_as_root

# other wrapper functions are: _rm, _mkdir, _chown, ...
_cp "does not exist.txt" "no such directory/test.txt"
```

Take a look at the src directory to see what is available.
Here is another example.

```sh
. lib/rkscript.sh

_confirm "Do you wan't to continue?"
test "$CONFIRM"="y" || _abort "i quit"
```

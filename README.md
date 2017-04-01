# rkscript
Collection of shell script snipplets (functions).

## Examples

Create run.sh shell script with abort and syntax function.

```sh
./merge2run "abort syntax"
```

Content of run.sh

```sh
#!/bin/bash
MERGE2RUN="abort syntax"


#------------------------------------------------------------------------------
# Abort with error message.
#
# @param abort message
#------------------------------------------------------------------------------
function _abort {
  echo -e "\nABORT: $1\n\n" 1>&2
  exit 1
}


#------------------------------------------------------------------------------
# Abort with SYNTAX: message.
#
# @global APP, APP_DESC
# @param message
#------------------------------------------------------------------------------
function _syntax {
  echo -e "\nSYNTAX: $APP $1\n" 1>&2

  if ! test -z "$APP_DESC"; then
    echo -e "$APP_DESC\n\n" 1>&2
  else
    echo 1>&2
  fi

  exit 1
}
```

## Mix rkscript functions with custom code

Create directory sh/run. Example:

* sh/run/custom.sh
* sh/run/syntax.sh
* sh/run/main.sh

```sh
#!/bin/bash
# (re)build with: /path/to/rkscript/merge2run "abort syntax custom.sh main.sh"
MERGE2RUN="abort syntax custom.sh main.sh"

#
# Only abort is from rkscript. Include custom.sh, syntax.sh and main.sh from sh/run/. 
#

```

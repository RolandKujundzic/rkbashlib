#!/bin/bash

. ../lib/rkscript.sh || exit 1
. testHelper.sh || exit 1

APP="$0"

_rm out
_mkdir out/a

echo -e "#!/bin/bash\necho 'test'" > out/test.sh
echo "test 1" > out/test1.txt
echo "test 2" > out/a/test2.txt

_ls_out
_chmod 755 out/*.sh 
_ls_out
_chmod 660 out/*.txt
_ls_out
_chmod 777 out/a
_ls_out

_compare_ok


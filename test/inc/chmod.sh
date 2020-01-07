#!/bin/bash

_mkdir "out/a" >/dev/null

echo -e "#!/bin/bash\necho 'test'" > out/test.sh
echo "test 1" > out/test1.txt
echo "test 2" > out/a/test2.txt

ls_out
_chmod 755 out/*.sh 

ls_out
_chmod 660 out/*.txt

ls_out
_chmod 777 out/a


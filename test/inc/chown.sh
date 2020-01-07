#!/bin/bash

echo "a" > out/a.txt
echo "b c" > out/b\ c.txt

ls_out
_chown out rk www-data 


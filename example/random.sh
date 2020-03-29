#!/bin/bash

# select random number from [1 ... 100]
RND=`shuf -i 1-100 -n 1`
F=0`bc -l <<< "scale=2; $RND/100"`
echo "RND=$RND F=$F"

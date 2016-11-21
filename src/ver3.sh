#!/bin/bash

#------------------------------------------------------------------------------
# Convert nn.mm.kk into nnmmkk (with leading zeros) 
# e.g. 3.10.8 = 031008, 14.22.72 = 142272 
# 
# @param version number (nn.mm.kk)
# @print int
#------------------------------------------------------------------------------
function ver3 {
	printf "%02d%02d%02d" $(echo "$1" | tr '.' ' ')
}


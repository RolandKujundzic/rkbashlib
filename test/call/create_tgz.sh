#!/bin/bash

AUTOCONFIRM=yy
_create_tgz "out/test.tgz" "../README.md ../LICENSE"
ls out/*.tgz
_create_tgz "out/test.tgz" "../README.md ../LICENSE"
ls out/*.tgz

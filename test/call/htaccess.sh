#!/bin/bash

_htaccess "out" "deny"
_htaccess "out" "deny"
_htaccess "out" "auth:john:my secret"
_htaccess "out" "auth:john:other secret"

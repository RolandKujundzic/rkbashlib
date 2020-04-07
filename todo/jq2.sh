#!/bin/bash

declare -A JP=([name]='Roland')
AGE=48

read -r -d '' JSON <<'EOF'
{
	"name": "${JP[name]}",
	"age": "$AGE"
}
EOF

echo -e "$JSON"

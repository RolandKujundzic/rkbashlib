#!/bin/bash

#--
# Split shell script $1 into *.inc.sh functions in $1_. Header is named 0_header.inc.sh
# and footer is name Z_main.inc.sh. Inverse of _merge_sh.
#
# @param path to shell script
#--
function _split_sh {
	_require_file "$1"
	local OUTPUT_DIR=`basename $1`"_"
	test -d "$OUTPUT_DIR" && _rm "$OUTPUT_DIR" >/dev/null
	_mkdir "$OUTPUT_DIR" >/dev/null

  local SPLIT_AWK=
IFS='' read -r -d '' SPLIT_AWK <<'EOF'
BEGIN{ fn = "_OUT_/split_1.inc.sh"; n = 1; open = 0; }
{
	if (substr($0,1,3) == "#--") {
		if (open) {
			open = 0
		}
		else {
			close (fn)
			n++
			fn = "_OUT_/split_" n ".inc.sh"
			open = 1
		}
	}

	print > fn
}
EOF

	_msg "Split $1 into"
	_mkdir "$RKSCRIPT_DIR" >/dev/null
	echo -e "$SPLIT_AWK" | sed -E "s/_OUT_/$OUTPUT_DIR/g" >"$RKSCRIPT_DIR/split_sh.awk"
	awk -f "$RKSCRIPT_DIR/split_sh.awk" "$1"

	local a; local func;
	for a in "$OUTPUT_DIR"/*.inc.sh; do
		func=`grep -E '^function [a-zA-Z0-9_]+ \{' $a | sed -E 's/function ([a-zA-Z0-9_]+) \{/\1/'`

		if test -z "$func"; then
			if test "$a" = "$OUTPUT_DIR/split_1.inc.sh"; then
				func="0_header"
			else
				func="Z_main"
				echo -e "#!/bin/bash\n" > "$OUTPUT_DIR/$func.inc.sh"
			fi
		else
			echo -e "#!/bin/bash\n" > "$OUTPUT_DIR/$func.inc.sh"
		fi

		_msg "  $OUTPUT_DIR/$func.inc.sh"
		head -n -1 "$a" >> "$OUTPUT_DIR/$func.inc.sh"
		tail -1 "$a" | sed '/^$/d' >> "$OUTPUT_DIR/$func.inc.sh"
		_rm "$a" >/dev/null
	done
}


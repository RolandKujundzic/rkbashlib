#!/bin/bash

#--
# Split shell script $1 into *.inc.sh functions in $1_. Header is named 0_header.inc.sh
# and footer is name Z_main.inc.sh. Inverse of _merge_sh.
#
# @param path to shell script
# @global RKBASH_DIR
#--
function _split_sh {
	_require_file "$1"
	local output_dir
	output_dir="$(basename "$1")_"
	test -d "$output_dir" && _rm "$output_dir" >/dev/null
	_mkdir "$output_dir" >/dev/null

  local split_awk
IFS='' read -r -d '' split_awk <<'EOF'
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

	_require_global RKBASH_DIR
	_msg "Split $1 into"
	_mkdir "$RKBASH_DIR" >/dev/null
	echo -e "$split_awk" | sed -E "s/_OUT_/$output_dir/g" >"$RKBASH_DIR/split_sh.awk"
	awk -f "$RKBASH_DIR/split_sh.awk" "$1"

	local a func
	for a in "$output_dir"/*.inc.sh; do
		func=$(grep -E '^function [a-zA-Z0-9_]+ \{' "$a" | sed -E 's/function ([a-zA-Z0-9_]+) \{/\1/')

		if test -z "$func"; then
			if test "$a" = "$output_dir/split_1.inc.sh"; then
				func="0_header"
			else
				func="Z_main"
				echo -e "#!/bin/bash\n" > "$output_dir/$func.inc.sh"
			fi
		else
			echo -e "#!/bin/bash\n" > "$output_dir/$func.inc.sh"
		fi

		_msg "  $output_dir/$func.inc.sh"
		head -n -1 "$a" >> "$output_dir/$func.inc.sh"
		tail -1 "$a" | sed '/^$/d' >> "$output_dir/$func.inc.sh"
		_rm "$a" >/dev/null
	done
}


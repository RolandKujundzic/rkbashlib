#!/bin/bash


#--
#
#--
function _jq {
	local KEY="$1"
	local FILE="${2:-$JQ_FILE}"
	local VALUE

	test -z "$KEY" && _abort "empty json key"
	#_require_file "$FILE"
	#_require_program "jq" "jq"

	if test "${KEY: -1}" = "="; then
		KEY="${KEY:0:-1}"
		VALUE="$2"
		FILE="${3:-$JQ_FILE}"
		local PATH; local PREFIX; local SUFFIX; local EXPR; local i; local a

		IFS="." read -ra PATH <<< "$KEY"
		if test ${#PATH[@]} -le 1; then
			EXPR=". + {$KEY: \"$VALUE\"}"
		else
			for (( i=0; i < ${#PATH[@]} - 1; i++)); do
				a="${PATH[$i]}"
				PREFIX="$PREFIX{ $a: {} | "
				SUFFIX="$SUFFIX}"
			done

			i=$(( ${#PATH[@]} - 1 ))
			EXPR=". + $PREFIX{${PATH[$i]}: \"$VALUE\"}$SUFFIX"
		fi

		if ! test -s "$FILE" && test "${#JQ_JSON}" -ge 2; then
			echo "§§: $EXPR"
			echo "$JQ_JSON" | /usr/bin/jq '.' # "$EXPR"
			echo ":§§"
		else
			echo "ToDo ..."
		fi
	else
		if ! test -s "$FILE" && test "${#JQ_JSON}" -ge 2; then
			echo -e "$JQ_JSON" | jq -r ".$KEY"
		else
		        jq -r ".$KEY" $FILE # || _abort "jq -r '.$KEY' '$FILE'"
		fi
	fi
}



#--
#
#--
function test_transform {
	INPUT='{
"things": [
     {
        "name": "foo",
        "params": [
           {
             "type": "t1",
              "key": "key1",
              "value": "val1"
           },
           {
              "type": "t1",
              "key": "category",
              "value": "thefoocategory"
           }
        ]
      },
      {
        "name": "bar",
        "params": [
           {
             "type": "t1",
             "key": "key1",
             "value": "val1"
           },
           {
             "type": "t1",
             "key": "category",
             "value": "thebarcategory"
           }
        ]
     }
  ]
}'

	echo -e "\ntest_transform:\n"
	# echo -e "$INPUT" | jq '.'
	echo -e "$INPUT" | jq '.things | .[] | {name: .name, category: .params | .[] | select(.key=="category") | .value}'
	echo -e "\ntest_transform done.\n"
}


#--
#
#--
function test_add_key {
	A=". + {foo: \"something\"} + {bar: \"other\"}"
	B='. + {yet: "another value"}'
	C='. + {hash: {} | {key: "value"}}'

	echo -e "\ntest_add_key:\n"

	JSON=`echo '{"hello": "world"}' | jq "$A"`
	JSON=`echo "$JSON" | jq "$B"`
	JSON=`echo "$JSON" | jq "$C"`

	echo "$JSON"
	echo -e "\ntest_add_key done.\n"
}


#--
#
#--
function test_jq {
	echo -e "\ntest_jq:\n"

	JQ_FILE=
	JQ_JSON='{ "firstname": "Hans", "lastname": "Meiser", "car": { "color": "blue" } }'

	_jq "firstname"
	JQ_JSON=`_jq "age=" "48"`
	_jq "car.doors"
#_jq "firstname=" "Hans Peter"
#_jq "car.doors=" "4/5"
#_jq "car.color=" "yellow"

# echo '{"hello": "world"}' | jq --arg foo bar '. + {foo: $foo}'
	echo -e "\ntest_jq done.\n"
}


test_transform
test_add_key
test_jq



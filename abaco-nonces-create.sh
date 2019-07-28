#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION] [ACTORID]

Creates a nonce for an actor. Default maximum uses is -1
(unlimited). Access levels are READ, EXECUTE, and UPDATE.

Options:
  -h	show help message
  -z    api access token
  -d    short nonce description
  -m    maximum uses
  -l    access level
  -v	verbose output
  -V    very verbose output
"

#function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() {
    echo "$HELP"
    exit 0
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/abaco-common.sh"
tok=
maxuses=-1
level=EXECUTE
description=

while getopts ":hl:m:z:d:Vv" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    m) # maxUses
        maxuses=${OPTARG}
        ;;
    l) # access level
        level=${OPTARG}
        ;;
    d) # optional description
        description=${OPTARG}
        ;;
    v) # verbose
        verbose="true"
        ;;
    V) # verbose
        very_verbose="true"
        ;;
    h | *) # print help text
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]]; then
    verbose="true"
fi

actor_id="$1"

if [ -z "${actor_id}" ]; then
    echo "Please provide an actor id."
    usage
fi

data="{\"maxUses\":\"${maxuses}\", \"level\":\"${level}\", \"description\":\"${description}\"}"
curlCommand="curl -XPOST -sk -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" --data '$data' '$BASE_URL/actors/v2/${actor_id}/nonces'"

function filter() {
    #    eval $@ | jq -r '.result | .[] | [.name, .id, .status] | @tsv' | column -t
    eval $@ | jq -r '.result | [.id, .maxUses, .remainingUses, .level] | "\(.[0]) \(.[1]) \(.[2]) \(.[3])"' | column -t
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

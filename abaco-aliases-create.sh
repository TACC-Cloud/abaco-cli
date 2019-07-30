#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION] [ACTORID] [ALIAS]

Create an alias for an actor.

Options:
  -h	show help message
  -z    oauth access token
  -p    skip pre-flight check of actor and alias
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
preflight=1

function do_preflight() {
    resp1=$(${DIR}/abaco ls -v ${1} | jq -r .result)
    if [[ "$resp1" == "null" ]]; then
        die "Actor ${1} was not found"
    fi
    resp2=$(${DIR}/abaco aliases ls ${2} | jq -r .result)
    if [[ "$resp2" != "null" ]]; then
        die "Alias ${2} already exists"
    fi
}

while getopts ":hpvz:V" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    p) # no preflight
        preflight=0
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
alias_str="$2"

if ((preflight)); then
    do_preflight ${actor_id} ${alias_str}
fi

if [ -z "${alias_str}" ] || [ -z "${actor_id}" ]; then
    echo "Please specify an actor ID followed by an alias"
    usage
fi

data="{\"actorId\":\"${actor_id}\", \"alias\":\"${alias_str}\"}"
curlCommand="curl -XPOST -sk -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" --data '$data' '$BASE_URL/actors/v2/aliases'"

function filter() {
    #    eval $@ | jq -r '.result | .[] | [.name, .id, .status] | @tsv' | column -t
    eval $@ | jq -r '.result | [.alias, .actorId, .owner] | "\(.[0]) \(.[1]) \(.[2])"' | column -t
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

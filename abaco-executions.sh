#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID] [EXECUTIONID]

Returns list of execution IDs for the provided actor or description 
of execution if execution ID provided.

Options:
  -h	show help message
  -z    api access token
  -v	verbose output
  -V    very verbose output
"

#function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/abaco-common.sh"
tok=

while getopts ":hvz:V" o; do
    case "${o}" in
        z) # custom token
            tok=${OPTARG}
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
shift $((OPTIND-1))
actor="$1"
execution="$2"

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]];
then
    verbose="true"
fi

if [ -z "$actor" ]; then
    echo "Please specify actor"
    usage
fi

if [ -z "$execution" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/executions'"
else
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2/$actor/executions/$execution'"
fi

function filter_list() {
	eval $@ | jq -r '.result | .executions | .[] | [.id, .status] | "\(.[0]) \(.[1])"' | column -t
}

function filter_description() {
#    eval $@ | jq -r '.result | [.workerId, .status] | @tsv' | column -t
    eval $@ | jq -r '.result | [.workerId, .status] | "\(.[0]) \(.[1])"' | column -t
}

if [[ "$very_verbose" == "true" ]];
then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    if [ -z "$execution" ]; then
        filter_list $curlCommand
    else
        filter_description $curlCommand
    fi
fi

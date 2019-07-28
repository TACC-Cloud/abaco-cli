#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]...
       ${THIS} [OPTION]... [ACTORID]

Count (or purge) messages in an actor's mailbox

Options:
  -h	show help message
  -z    oauth access token
  -X    purge all messages
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
purge=0

while getopts ":hvXz:V" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    X) # purge
        purge=1
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
actor="$1"

if [ ! -z "$tok" ]; then TOKEN=$tok; fi

if [[ "$very_verbose" == "true" ]]; then
    verbose="true"
fi

if [ -z "$actor" ]; then
    die "Actor identifier or alias is required."
fi

if !((purge)); then
    curlCommand="curl -XGET -sk -H \"Authorization: Bearer ${TOKEN}\" '${BASE_URL}/actors/v2/${actor}/messages'"
else
    curlCommand="curl -XDELETE -sk -H \"Authorization: Bearer ${TOKEN}\" '${BASE_URL}/actors/v2/${actor}/messages'"
fi

function filter_count() {
    info "Message count"
    eval $@ | jq -r .result.messages
}

function filter_purge() {
    info "Purging messages..."
    eval $@ | jq -r .result.msg
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    if ((purge)); then
        filter_purge $curlCommand
    else
        filter_count $curlCommand
    fi
fi

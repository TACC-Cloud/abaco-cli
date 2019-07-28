#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID]

Executes the actor with provided ID and returns execution ID. Message (-m)
is required and can be string or JSON.

Options:
  -h	show help message
  -z    oauth access token
  -Z    authorization nonce
  -m	value of actor env variable \$MSG
  -q	query string to pass to actor env
  -x    send as a synchronous execution
  -v	verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() {
    echo "$HELP"
    exit 0
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/abaco-common.sh"
tok=
xnonce=

while getopts ":hm:q:vxz:Z:V" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    Z) # abaco nonce
        xnonce=${OPTARG}
        ;;
    m) # msg to pass to actor environment as $MSG
        msg=${OPTARG}
        ;;
    q) # query string to pass to actor environment
        query=${OPTARG}
        ;;
    x) # synchronous execution
        synchronous="true"
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

actor="$1"
if [ -z "$actor" ]; then
    echo "Please give an actor ID at the end of the command"
    usage
fi

if [ -z "$msg" ]; then
    echo "Please give a message (eg. "execute yourself") with the -m flag."
    usage
fi

syncargs=
if [[ "$synchronous" == "true" ]]; then
    syncargs="_abaco_synchronous=true"
    if [[ ! -z "${query}" ]]; then
        syncargs="&${syncargs}"
    fi
fi

# Do not send Bearer token - Instead, send the x-nonce parameter
auth_header="-H \"Authorization: Bearer $TOKEN\""
nonceargs=
if [[ ! -z "${xnonce}" ]]; then
    auth_header=
    nonceargs="x-nonce=${xnonce}"
    if [[ ! -z "${query}" ]] || [[ ! -z "${syncargs}" ]]; then
        nonceargs="&${nonceargs}"
    fi
fi

# check if $msg is JSON; if so, add JSON header
if $(is_json "$msg"); then
    curlCommand="curl -sk ${auth_header} -XPOST -H \"Content-Type: application/json\" -d '$msg' '$BASE_URL/actors/v2/${actor}/messages?${query}${syncargs}${nonceargs}'"
else
    msg="$(single_quote "$msg")"
    curlCommand="curl -sk ${auth_header} -XPOST --data \"message=${msg}\" '$BASE_URL/actors/v2/${actor}/messages?${query}${syncargs}${nonceargs}'"
fi

function filter() {
    local output="$(eval $@ | jq -r '.result')"
    echo $output | jq -r '.executionId'
    echo $output | jq -r '.msg'
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

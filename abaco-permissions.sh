#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID]

Updates and lists user permissions for a given actor. If a user
and access level is provided, permissions are updated; otherwise,
the current permissions are listed. Valid access levels are NONE,
READ, EXECUTE, and UPDATE.

Options:
  -h    show help message
  -z    oauth access token
  -u    update this user's permission
  -p    permission level
  -v    verbose output
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

while getopts ":hvu:p:z:V" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    u) # user to update permissions
        user=${OPTARG}
        ;;
    p) # permission level
        permission=${OPTARG}
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
    echo "Please specify actor ID"
    usage
fi

# POST if both user and permission provided
# GET if neither provided
# throw error if only one provided
if [ ! -z "$user" ] && [ ! -z "$permission" ]; then
    data="{\"user\": \"${user}\", \"level\": \"${permission}\"}"
    curlCommand="curl -X POST -sk -H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\" --data '$data' 'https://api.sd2e.org/actors/v2/${actor}/permissions'"
elif [ -z "$user" ] && [ -z "$permission" ]; then
    curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" 'https://api.sd2e.org/actors/v2/${actor}/permissions'"
else
    echo "Please specify both a user (-u) and a permission level (-p) to update permissions for actor $actor"
    usage
fi

function filter() {
    eval $@ | jq -r '.result | to_entries[] | [.key, .value] | "\(.[0]) \(.[1])"' | column -t
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID] [IMAGE]

Updates an actor. State status and actor name
cannot be changed. Actor ID and Docker image
required.

Options:
  -h	show help message
  -z    oauth access token
  -e    set environment variables (key=value)
  -E    read environment variables from json file
  -p    add privileged status
  -f    force update
  -u    use actor uid
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

privileged="false"
stateless="true"
force="false"
use_uid="false"
tok=

# the s and S opts are here to swallow them when passed - we do not allow
# toggling between stateless and stateful via an update operation
while getopts ":he:E:pfsSuvz:V" o; do
    case "${o}" in
    z) # custom token
        tok=${OPTARG}
        ;;
    e) # default environment (command line key=value)
        env_args[${#env_args[@]}]=${OPTARG}
        ;;
    E) # default environment (json file)
        env_json=${OPTARG}
        ;;
    p) # privileged
        privileged=true
        ;;
    f) # force
        force=true
        ;;
    s) # stateless
        stateless="true"
        ;;
    S) # stateful!
        stateless="false"
        ;;
    u) # use uid
        use_uid=true
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
actorid="$1"
image="$2"

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]]; then
    verbose="true"
fi

# fail if no actorid or image
if [ -z "$actorid" ] || [ -z "$image" ]; then
    echo "Please specify an actor ID and a Docker image"
    usage
fi

# default env
# check env vars json file (exists, have contents, be json)
file_default_env=
if [ ! -z "$env_json" ]; then
    if [ ! -f "$env_json" ] || [ ! -s "$env_json" ] || ! $(is_json $(cat $env_json)); then
        die "$env_json is not valid. Please ensure it exists and contains valid JSON."
    fi
    file_default_env=$(cat $env_json)
fi
# build command line env vars into json
args_default_env=$(build_json_from_array "${env_args[@]}")
#combine both
default_env=$(echo "$file_default_env $args_default_env" | jq -s add)

# WORKAROUND - fetch stateless from actor records.
# TODO - File Issue: Stateless should not be mandatory for an update operation
stateless=$(${DIR}/abaco ls -v ${actorid} | jq -r .result.stateless)

# curl command
# \"stateless\":\"${stateless}\",
data="{\"stateless\":\"${stateless}\", \"image\":\"${image}\", \"privileged\":${privileged}, \"force\":${force}, \"useContainerUid\":${use_uid}, \"defaultEnvironment\":${default_env}}"
curlCommand="curl -X PUT -sk -H \"Authorization: Bearer $TOKEN\"  -H \"Content-Type: application/json\" --data '$data' '$BASE_URL/actors/v2/${actorid}'"

function filter() {
    #    eval $@ | jq -r '.result | [.name, .id] | @tsv' | column -t
    eval $@ | jq -r '.result | [.name, .id] |  "\(.[0]) \(.[1])"' | column -t
}

if [[ "$very_verbose" == "true" ]]; then
    echo "Calling $curlCommand"
fi

if [[ "$verbose" == "true" ]]; then
    eval $curlCommand
else
    filter $curlCommand
fi

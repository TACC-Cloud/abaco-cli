#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [ACTORID] (NONCE_ID)

Create, list, and delete nonces for a given actor. A nonce has
a level of READ, EXECUTE, or UPDATE and a specific number of uses.

Options:
  -h    show help message
  -z    api access token
  -l    update this user's permission
  -p    permission level
  -v    verbose output
  -V    very verbose output
"

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
shift $((OPTIND-1))

if [ ! -z "$tok" ]; then TOKEN=$tok; fi
if [[ "$very_verbose" == "true" ]];
then
    verbose="true"
fi

echo "Support for nonces is not yet implemented"
exit 0

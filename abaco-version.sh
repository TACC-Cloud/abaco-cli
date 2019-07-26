#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [IMAGE]

Reports the Abaco CLI and service versions.

Options:
-h    show help message
-v    verbose (JSON) output
"

#displayonly

# function usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
function usage() {
    echo "$HELP"
    exit 0
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${DIR}/abaco-common.sh"

verbose=0

while getopts ":hn:e:E:pfsSuvz:V" o; do
    case "${o}" in
    v) # verbose
        verbose=1
        ;;
    h | *) # print help text
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

cli_version=$(cat ${DIR}/VERSION)
curlCommand="curl -sk -H \"Authorization: Bearer $TOKEN\" '$BASE_URL/actors/v2?limit=1'"
abaco_version=$(eval $curlCommand | jq -r .version)

if ((verbose)); then
    echo -e "{\n  \"cli\": \"${cli_version}\",\n  \"abaco\": \"${abaco_version}\"\n}"
else
    echo -e "cli: ${cli_version}\nabaco: ${abaco_version}"
fi

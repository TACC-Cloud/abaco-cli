#!/bin/bash

if [[ ! -x $(which jq) ]]; then
    echo "Error: jq was not found."
    echo "This CLI requires jq. Please install it first."
    echo " - https://stedolan.github.io/jq/download/"
    exit 1
fi

tapis_cli_avail=0
if [[ "${ABACO_ENABLE_AUTO_REFRESH}" == "1" ]]; then
    if ! ((tapis_cli_avail)); then
        if [[ -z "${TAPIS_CLI_PATH}" ]] || [[ -d "${TAPIS_CLI_PATH}" ]]; then
            TAPIS_CLI_PATH=$(dirname $(which auth-tokens-refresh))
        fi
        if [[ -f ${TAPIS_CLI_PATH}/auth-tokens-refresh ]]; then
            tapis_cli_avail=1
            export tapis_cli_avail
        fi
    fi
fi
export tapis_cli_avail

git_cli_avail=0
ABACO_USE_GIT_CLI=1
if [[ "${ABACO_USE_GIT_CLI}" == "1" ]]; then
    if ! ((git_cli_avail)); then
        if [[ -z "${GIT_CLI_PATH}" ]] || [[ -d "${GIT_CLI_PATH}" ]]; then
            GIT_CLI_PATH=$(dirname $(which git))
        fi
        if [[ -f ${GIT_CLI_PATH}/git ]]; then
            git_cli_avail=1
            export git_cli_avail
        fi
    fi
fi
export git_cli_avail

AGAVE_AUTH_CACHE=
if [ ! -z "${AGAVE_CACHE_DIR}" ] && [ -d "${AGAVE_CACHE_DIR}" ]; then
    if [ -f "${AGAVE_CACHE_DIR}/current" ]; then
        AGAVE_AUTH_CACHE="${AGAVE_CACHE_DIR}/current"
    fi
else
    AGAVE_AUTH_CACHE="$HOME/.agave/current"
fi
if [ ! -f "${AGAVE_AUTH_CACHE}" ]; then
    echo "Error: API credentials are not configured."
    exit 1
fi

function build_json_from_array() {
    local myarray=("$@")
    local var_count=${#myarray[@]}

    if [ $var_count -eq 0 ]; then
        echo "{}"
        exit 0
    fi

    local last_index=$((${#myarray[@]} - 1))
    local json="{"
    for i in $(seq 0 $last_index); do
        local key_value=${myarray[$i]}
        local key=${key_value%=*}
        local value=${key_value#*=}

        # add key-value pair
        json="${json}\"$key\":\"$value\""

        # if last pair, close with curly brace
        # otherwise, add comma for next value
        if [ $i -eq $last_index ]; then
            json="${json}}"
        else
            json="${json}, "
        fi
    done

    echo "$json"
}

function is_json() {
    echo "$@" | jq -e . >/dev/null 2>&1
}

function single_quote() {
    local str="$1"
    local first_char="$(echo "$str" | head -c 1)"
    if ! [ "$first_char" == "'" ]; then
        str="'$str'"
    fi
    echo "$str"
}

function die() {

    echo "[CRITICAL] $1"
    exit 1

}

function warn() {

    echo "[WARNING] $1"

}

function info() {

    echo "[INFO] $1"

}

function refresh_access_token() {
    if ((tapis_cli_avail)); then
        echo "Refreshing..."
        auth-tokens-refresh -q
    fi
}

refresh_access_token

BASE_URL=$(jq -r .baseurl ${AGAVE_AUTH_CACHE})
CLIENT_SECRET=$(jq -r .apisecret ${AGAVE_AUTH_CACHE})
CLIENT_KEY=$(jq -r .apikey ${AGAVE_AUTH_CACHE})
USERNAME=$(jq -r .username ${AGAVE_AUTH_CACHE})
TOKEN=$(jq -r .access_token ${AGAVE_AUTH_CACHE})
TENANTID=$(jq -r .tenantid ${AGAVE_AUTH_CACHE})
if [[ ! -z "${DOCKER_HUB_ORG}" ]]; then
    REGISTRY_USERNAME=${DOCKER_HUB_ORG}
else
    REGISTRY_USERNAME=${USERNAME}
fi

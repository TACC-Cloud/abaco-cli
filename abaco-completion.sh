#!/usr/bin/env bash

_abaco() {
    COMPREPLY=()
    local prev cur
    cur=${COMP_WORDS[COMP_CWORD]}

    local commands="list create delete update permissions workers submit executions logs deploy init version messages"

    COMPREPLY=($(compgen -W "$commands" -- $cur))

    return 0
}

complete -F _abaco abaco

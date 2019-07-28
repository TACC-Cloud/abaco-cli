#!/usr/bin/env bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [COMMAND] [OPTION]...

Create and manage Abaco actor nonces (per-actor tokens). Options vary by
command; use -h flag after command to view usage details.

Commands:
  list, ls                      list nonces
  create                        create a nonce
  delete, remove, rm            delete a nonce
"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
list | ls)
    shift
    bash $DIR/abaco-nonces-list.sh "$@"
    ;;

create | make)
    shift
    bash $DIR/abaco-nonces-create.sh "$@"
    ;;

delete | remove | rm)
    shift
    bash $DIR/abaco-nonces-delete.sh "$@"
    ;;

*)
    shift
    echo "$HELP"
    exit 0
    ;;
esac

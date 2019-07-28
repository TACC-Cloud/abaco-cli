#!/usr/bin/env bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [COMMAND] [OPTION]...

Create and manage Abaco actor aliases (i.e. nicknames). Options vary by
command; use -h flag after command to view usage details.

Commands:
  create                        create an alias
  delete, remove, rm            delete a alias
  list, ls                      list an alias or aliases
"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
list | ls)
    shift
    bash $DIR/abaco-aliases-list.sh "$@"
    ;;

create | make)
    shift
    bash $DIR/abaco-aliases-create.sh "$@"
    ;;

delete | remove | rm)
    shift
    bash $DIR/abaco-aliases-delete.sh "$@"
    ;;

# permissions | share)
#     shift
#     bash $DIR/abaco-aliases-permissions.sh "$@"
#     ;;

*)
    shift
    echo "$HELP"
    exit 0
    ;;
esac

#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [IMAGE]

Initializes a new Abaco actor project.

Options:
  -h    show help message
  -n    project name (e.g. my_new_actor)
  -l    language (default: python3)
"

function usage() { echo "$HELP"; exit 0; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/abaco-common.sh"

function slugify {
  $DIR/slugify.py "${1}"
}

name=
repo=
lang=
tenant=

while getopts ":hl:n:i:" o; do
    case "${o}" in
        n) # name
            name=${OPTARG}
            ;;
        l) # language
            lang=${OPTARG}
            ;;
        h | *) # print help text
            usage
            ;;
    esac
done
shift $((OPTIND-1))
repo="$1"

if [ -z "${name}" ]
then
  usage
fi

# URL-safen name
safename=`slugify "${name}"`
if [ "$safename" != "$name" ]
then
  info "Making project name URL safe: $safename"
  name="$safename"
fi

# Ensure directory $name is doens't exist yet
if [ ! -d "$name" ]
then
  mkdir -p "$name"
else
  die "Project directory $name exists."
fi

# Template language - default Python2
if [ -z "${lang}" ]
then
  lang="python3"
  info "Defaulting to Python 3.6"
fi

# set repo to name if not passed by user
# else, check user-passed repo is valid (slugify)
if [ -z "${repo}" ]
then
  repo=${name}
else
  saferepo=$(slugify $repo)
  if [ "$saferepo" != "$repo" ]
  then
    info "Making repo name URL safe: $saferepo"
    repo="$saferepo"
  fi
fi

# Get tenant ID
if [ -f "$HOME/.agave/current" ]
then
  tenant=${TENANTID}
else
  die "Can't determine TACC Cloud tenant"
fi

# Copy in template
if [ -d "$DIR/templates/$tenant/$lang" ]
then
  if [ ! -f "$DIR/templates/$tenant/$lang/placeholder" ]
  then
    cp -R ${DIR}/templates/${tenant}/${lang}/ ${name}/
  else
    die "Template support for $lang is not yet implemented."
  fi
else
  rm -rf ${name}
  die "Error creating project directory $name"
fi

# Template out the reactor.rc file
cat << EOF > "${name}/reactor.rc"
# Reactor mandatory settings
REACTOR_NAME=${name}
# REACTOR_DESCRIPTION=
# REACTOR_ALIAS=reactor-nickname

# Docker settings
DOCKER_HUB_ORG=your_docker_registory_uname
DOCKER_IMAGE_TAG=${repo}
DOCKER_IMAGE_VERSION=0.1
EOF

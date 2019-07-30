#!/bin/bash

THIS=$(basename $0)
THIS=${THIS%.sh}
THIS=${THIS//[-]/ }

HELP="
Usage: ${THIS} [OPTION]... [IMAGE]

Initializes an Abaco actor project in a new directory.

Options:
  -h    show help message
  -n    project name (e.g. my-actor-name)
  -d    project description
  -l    project type (python3)
  -O    registry username/organization (${USER})
  -B    base path (current directory)
"

function usage() {
  echo "$HELP"
  exit 0
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/abaco-common.sh"

function slugify() {
  $DIR/slugify.py "${1}"
}

name=
description=
repo=
lang=
tenant=
uorg=${USER}
basepath="./"

while getopts ":hl:n:B:d:i:O:" o; do
  case "${o}" in
  n) # name
    name=${OPTARG}
    ;;
  d) # description
    description=${OPTARG}
    ;;
  l) # language
    lang=${OPTARG}
    ;;
  B) # basepath
    basepath=${OPTARG}
    ;;
  O) # container reg username or org
    uorg=${OPTARG}
    ;;
  h | *) # print help text
    usage
    ;;
  esac
done
shift $((OPTIND - 1))
repo="$1"

if [ -z "${name}" ]; then
  usage
fi

# URL-safen name
safename=$(slugify "${name}")
if [ "$safename" != "$name" ]; then
  info "Making project name URL safe: $safename"
  name="$safename"
fi

# Ensure directory $name is doens't exist yet
if [ ! -d "${basepath}/${name}" ]; then
  mkdir -p "${basepath}/${name}"
else
  die "Directory $name exists at ${basepath}"
fi

# Template language - default Python2
if [ -z "${lang}" ]; then
  lang="python3"
  info "Defaulting to Python 3"
fi

# set repo to name if not passed by user
# else, check user-passed repo is valid (slugify)
if [ -z "${repo}" ]; then
  repo=${name}
else
  saferepo=$(slugify $repo)
  if [ "$saferepo" != "$repo" ]; then
    info "Making repo name URL safe: $saferepo"
    repo="$saferepo"
  fi
fi

# Get tenant ID
if [ -f "${AGAVE_AUTH_CACHE}" ]; then
  tenant=${TENANTID}
else
  die "Can't determine TACC.cloud tenant"
fi

# Copy in template
if [ -d "$DIR/templates/$tenant/$lang" ]; then
  if [ ! -f "$DIR/templates/$tenant/$lang/placeholder" ]; then
    cp -R ${DIR}/templates/${tenant}/${lang}/ ${basepath}/${name}/
  else
    die "Template support for ${lang} is not yet implemented."
  fi
else
  rm -rf ${name}
  die "Error creating project directory ${name}"
fi

# Template out the reactor.rc file
cat <<EOF >"${basepath}/${name}/reactor.rc"
# Reactor mandatory settings
REACTOR_NAME=${name}
REACTOR_DESCRIPTION="${description}"
REACTOR_PRIVILEGED=
REACTOR_USE_UID=
REACTOR_STATEFUL=

# Docker settings
DOCKER_HUB_ORG=${uorg}
DOCKER_IMAGE_TAG=${repo}
DOCKER_IMAGE_VERSION=0.0.1
EOF

if ((git_cli_avail)); then
  info "Initializing ${name} as git repo..."
  OWD=${PWD}
  cd ${basepath}/${name} && git init && cd ${OWD}
fi

info "Complete: ${basepath}${name}"
exit 0

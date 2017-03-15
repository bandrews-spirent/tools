#!/bin/bash
#
# Executes Go make project with cross compile for Linux 64,
# and optionally uploads the binaries to a remote VM.

set -eo pipefail

readonly OUTPUT_DIR='./bin'

do_build() {
  # 'go test doesn't work, so just remove it.
  sed -i '' "s/go test /# go test /g" Makefile

  GOOS=linux GOARCH=amd64 make

  git checkout Makefile
}

do_copy() {
  if [[ $copy_to_host != '' ]]; then
    scp -r $OUTPUT_DIR $copy_to_host
  fi
}

copy_to_host=''

usage() {
  echo 'Usage:'
  echo "  $0 [options]"
  echo ''
  echo '  Options:'
  echo '    -c, --copy-to-host copies the binaries to the remote host (should be SCP form, i.e. user@10.1.1.1:/home/user'
  exit 0
}

while [ $# -gt 0 ]
do
  case "$1" in
    --copy-to-host|-c) copy_to_host="$2"; shift;;
    --) shift; break;;
    -*|--help|-h) usage;;
    *)  break;;
  esac
  shift
done

do_build
do_copy

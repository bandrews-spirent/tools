#!/bin/bash

# Rebase master on top of given branch.

set -e

do_rebase() {
  git fetch upstream
  git checkout master
  git pull upstream master
  git checkout "$branch"
  git rebase master
}

if [ "$#" -ne 1 ]; then
  echo "usage: $0 branch" >&2
  exit 1
fi

branch=$1
do_rebase
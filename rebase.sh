#!/bin/bash

# Rebase main on top of given branch.

set -e

do_rebase() {
  git fetch upstream
  git checkout main
  git pull upstream main
  git checkout "$branch"
  git rebase main
}

if [ "$#" -ne 1 ]; then
  echo "usage: $0 branch" >&2
  exit 1
fi

branch=$1
do_rebase

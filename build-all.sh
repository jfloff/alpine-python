#!/bin/bash
repo='jfloff/alpine-python'
bold="$(tput bold)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
reset="$(tput sgr0)"

build_with_status () {
  tag="$1"

  echo -n "Building $tag:"
  docker build . -t $tag &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "$bold$green GOOD$reset"
  else
    echo "$bold$red BAD$reset"
    exit 1
  fi
}

# quiet versions
pushd() { builtin pushd $1 > /dev/null; }
popd() { builtin popd > /dev/null; }

# Move to where the script is
HERE="$(dirname $(readlink -f $0 || realpath $0))"
cd $HERE

# Find all the top-level dirs
for version in $(find -maxdepth 1 -not -name '.*' -type d -printf '%P\n'); do
  pushd $version

  # Build the flat version
  build_with_status $repo:$version

  # Build any sub-versions
  for subtype in $(find -maxdepth 1 -not -name '.*' -type d -printf '%P\n'); do
    pushd $subtype
    build_with_status $repo:$version-$subtype
    popd
  done

  popd
done

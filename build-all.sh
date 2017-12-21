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
  if [[ $? -ne 0 ]]; then
    echo "$bold$red BUILD FAILED$reset"
    exit 1
  fi

  echo 'print("something")' | docker run --rm -i $tag &> /dev/null
  if [[ $? -ne 0 ]]; then
    echo "$bold$red TEST FAILED$reset"
    exit 1
  else
    echo "$bold$green SUCCESS$reset"
  fi
}

# quiet versions
pushd() { builtin pushd $1 > /dev/null; }
popd() { builtin popd > /dev/null; }

# Move to where the script is
HERE="$(dirname $(readlink -f $0 || realpath $0))"
cd $HERE

# Find all the top-level dirs
for version in $(find -maxdepth 1 -not -name '.*' -type d -printf '%P\n' | sort); do
  pushd $version
  build_with_status $repo:$version
  popd
done

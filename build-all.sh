#!/bin/bash
repo='jfloff/alpine-python'
bold="$(tput bold)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
reset="$(tput sgr0)"

build_with_status () {
  tag="$1"

  printf "${b}Building ${tag} ... "
  docker build . -t $tag &> /dev/null
  if [[ $? -ne 0 ]]; then
    printf "\n${bold}${red}BUILD FAILED${reset}"
    exit 1
  fi

  echo 'print("something")' | docker run --rm -i $tag &> /dev/null
  if [[ $? -ne 0 ]]; then
    printf "${bold}${red}TEST FAILED${reset}"
    exit 1
  else
    printf "${bold}${green}SUCCESS${reset}"
  fi
  printf "\n"
}

# quiet versions
pushd() { builtin pushd $1 > /dev/null; }
popd() { builtin popd > /dev/null; }

# Move to where the script is
HERE="$( cd "$(dirname "$0")" ; pwd -P )"
cd "$HERE"

# Find all the top-level dirs
for version in $(find -maxdepth 1 -not -name '.*' -type d -printf '%P\n' | sort); do
  pushd $version
  build_with_status $repo:$version
  popd
done

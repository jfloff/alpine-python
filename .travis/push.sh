#!/bin/bash
set -o errexit

PUSH=1


if [[ "$TRAVIS_BRANCH" == "master" ]]; then
  if [[ -z "$DOCKER_USERNAME" || -z "$DOCKER_PASSWORD" ]]; then
    echo "Skipping Docker push, no credentials specified."
    PUSH=0
  else
    echo "$DOCKER_PASSWORD" | sudo docker login -u "$DOCKER_USERNAME" --password-stdin
  fi

    if [[ "$PUSH" -eq 1 ]]; then
      echo "Pushing $repo:$version$type"
      sudo docker push $repo:$version$type
    else
      echo "Would have pushed as $repo:$version$type"
    fi

    if [[ "$latest" == "$version" ]]; then
      if [[ "$PUSH" -eq 1 ]]; then
        echo "Pushing this one as latest$type!"
        sudo docker tag $repo:$version$type $repo:latest$type
        sudo docker push $repo:latest$type
      else
        echo "Would have pushed as $repo:latest$type"
      fi
    fi

  fi
fi

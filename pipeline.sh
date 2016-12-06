#!/bin/bash

export APP_VERSION=1.1.$SNAP_PIPELINE_COUNTER

clone() {
  repository=$1

  echo "Removing '$repository'..."
  rm -rf $repository
  git clone git@github.com:smbc-digital/$repository.git
}

build() {
  clone "iag-webapp"
  clone "iag-contentapi"
  clone "aws-provisioning"

  pushd iag-webapp
  make publish
  popd

  pushd iag-contentapi
  make publish
  popd

  pushd aws-provisioning
  RESOURCE=beanstalk APPLICATION=iag make publish
  popd
}

deploy() {
  clone "aws-provisioning"
  pushd aws-provisioning
  APPLICATION=iag make beanstalk
  popd
}

handle_command() {

  case "$1" in
    build)
      build
      ;;
    deploy)
      deploy
      ;;
  *)
    echo Invalid Option "'$1'"!
    echo "Available options are: <build/deploy>"
    exit 1
  esac
}

handle_command "$@"

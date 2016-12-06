#!/bin/bash

export APP_VERSION=1.1.$SNAP_PIPELINE_COUNTER

clone_repos() {
  rm -rf iag-webapp
  rm -rf iag-contentapi
  rm -rf aws-provisioning

  echo "Cloning repositories.."
  git clone git@github.com:smbc-digital/iag-webapp.git
  git clone git@github.com:smbc-digital/iag-contentapi.git
  git clone git@github.com:smbc-digital/aws-provisioning.git
}

build() {
  clone_repos

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

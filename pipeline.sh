#!/bin/bash
set -e

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
  make build
  popd

  pushd iag-contentapi
  make build
  popd
}

publish() {
  pushd iag-webapp
  make tag
  make push
  popd

  pushd iag-contentapi
  make tag
  make push
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

smoke_test() {
  pushd aws-provisioning
  APPLICATION=iag BUSINESS-ID=healthystockport make smoke-test
  APPLICATION=iag BUSINESS-ID=stockportgov make smoke-test
  popd
}

handle_command() {

  case "$1" in
    build)
      build
      ;;
    publish)
      publish
      ;;
    deploy)
      deploy
      ;;
    smoke-test)
      smoke_test
      ;;
  *)
    echo Invalid Option "'$1'"!
    echo "Available options are: <build/publish/deploy/smoke-test>"
    exit 1
  esac
}

handle_command "$@"

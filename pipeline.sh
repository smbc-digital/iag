#!/bin/bash
set -e

export APPLICATION=iag
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
  RESOURCE=beanstalk make publish
  popd
}

deploy() {
  clone "aws-provisioning"
  pushd aws-provisioning
  make beanstalk
  popd
}

install() {
  pip install virtualenv
	virtualenv -p /usr/bin/python3 venv
	source venv/bin/activate
	pip install -r requirements.txt
}

smoke_test() {
  pushd aws-provisioning
  install
  python src/smoketest.py iag $APP_VERSION healthystockport
  python src/smoketest.py iag $APP_VERSION stockportgov
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

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

smoke_test() {
  pushd aws-provisioning
  BUSINESS_ID=healthystockport make smoke-test
  BUSINESS_ID=stockportgov make smoke-test
  popd
}

ui_test() {
  APEX_DOMAIN=smbctest.com
  clone "iag-webapp"
  pushd iag-webapp/test/StockportWebappTests/UI
  npm cache clear
  npm install
  popd

  pushd iag-webapp
  export UI_TEST_HOST=http://$ENVIRONMENT-$APPLICATION-healthystockport.$APEX_DOMAIN
  echo "Running ui tests on '$UI_TEST_HOST'"
  make ui-test

  export UI_TEST_HOST=http://$ENVIRONMENT-$APPLICATION-stockportgov.$APEX_DOMAIN
  echo "Running ui tests on '$UI_TEST_HOST'"
  make ui-test
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
    ui-test)
      ui_test
      ;;
  *)
    echo Invalid Option "'$1'"!
    echo "Available options are: <build/publish/deploy/smoke-test/ui-test>"
    exit 1
  esac
}

handle_command "$@"

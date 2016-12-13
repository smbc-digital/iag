#!/bin/bash
set -e

export APPLICATION=iag
export APP_VERSION=1.1.$SNAP_PIPELINE_COUNTER

__clone() {
  repository=$1

  echo "Removing '$repository'..."
  rm -rf $repository
  git clone git@github.com:smbc-digital/$repository.git
}

__publish() {
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

__deploy() {
  pushd aws-provisioning
  make beanstalk
  popd
}

__smoke_test() {
  pushd aws-provisioning
  BUSINESS_ID=healthystockport make smoke-test
  BUSINESS_ID=stockportgov make smoke-test
  popd
}

__ui_test() {
  pushd iag-webapp/test/StockportWebappTests/UI
  npm cache clear
  npm install
  popd

  __run_ui_test "healthystockport"
  __run_ui_test "stockportgov"
}

__run_ui_test() {
  APEX_DOMAIN=smbctest.com
  pushd iag-webapp
  export BUSINESS_ID=$1
  export UI_TEST_HOST=http://$ENVIRONMENT-$APPLICATION-$BUSINESS_ID.$APEX_DOMAIN
  echo "Running ui tests on '$UI_TEST_HOST'"
  make ui-test
  popd
}

build() {
  __clone "iag-webapp"
  __clone "iag-contentapi"
  __clone "aws-provisioning"

  pushd iag-webapp
  make build
  popd

  pushd iag-contentapi
  make build
  popd

  pushd aws-provisioning
  RESOURCE=beanstalk make build
  popd

  __publish
}

integration() {
    export ENVIRONMENT=int
    __clone "aws-provisioning"
    __clone "iag-webapp"
    __deploy
    __smoke_test
    __ui_test
}

qa() {
    export ENVIRONMENT=qa
    __clone "aws-provisioning"
    __deploy
    __smoke_test
}

stage() {
    export ENVIRONMENT=stage
    __clone "aws-provisioning"
    __deploy
    __smoke_test
}

prod() {
    export ENVIRONMENT=prod
    __clone "aws-provisioning"
    __deploy
    __smoke_test
}

handle_command() {

  case "$1" in
    build)
      build
      ;;
    integration)
      integration
      ;;
    qa)
      qa
      ;;
    stage)
      stage
      ;;
    prod)
      prod
      ;;
  *)
    echo Invalid Option "'$1'"!
    echo "Available options are: <build/integration/qa/stage/prod>"
    exit 1
  esac
}

handle_command "$@"

git clone git@github.com:smbc-digital/iag-webapp.git
git clone git@github.com:smbc-digital/iag-contentapi.git
git clone git@github.com:smbc-digital/aws-provisioning.git

pushd iag-webapp
make build
export APP_VERSION=1.1.$SNAP_PIPELINE_COUNTER
make tag
popd

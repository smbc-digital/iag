git clone git@github.com:smbc-digital/iag-webapp.git
git clone git@github.com:smbc-digital/iag-contentapi.git
git clone git@github.com:smbc-digital/aws-provisioning.git

export APP_VERSION=1.1.$SNAP_PIPELINE_COUNTER

pushd iag-webapp
make package
popd

pushd iag-contentapi
make package
popd

pushd aws-provisioning
RESOURCE=beanstalk APPLICATION=iag make publish
popd

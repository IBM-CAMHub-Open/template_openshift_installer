#/bin/bash

curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.2.0/openshift-install-linux-4.2.0.tar.gz | sudo tar xz -C /usr/local/bin/ --exclude=README.md
sudo curl -s  https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.2.0/openshift-client-linux-4.2.0.tar.gz | sudo tar xz -C /usr/local/bin/ --exclude=README.md

export AWS_ACCESS_KEY_ID=${1}
export AWS_SECRET_ACCESS_KEY=${2}

openshift-install create manifests --dir=${3}
if [ $? -ne 0 ]; then
	exit 1
fi

infra_id=$(grep -Eo 'infrastructureName.*' ${3}/manifests/cluster-infrastructure-02-config.yml | sed 's/^.*: //')
sed -i "s/${infra_id}/${4}/g" ${3}/manifests/cluster-infrastructure-02-config.yml
sed -i "s/${infra_id}/${4}/g" ${3}/.openshift_install_state.json

rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml
rm -f openshift/99_openshift-cluster-api_worker-machineset-*

openshift-install create ignition-configs --dir=${3}
if [ $? -ne 0 ]; then
	exit 1
fi

sudo yum install -y -q install python3
pip3 install awscli --upgrade --user
export PATH=$PATH:~/.local/bin

aws s3 cp ${3}/bootstrap.ign s3://${5}/bootstrap.ign --acl public-read
if [ $? -ne 0 ]; then
	exit 1
fi

aws s3 cp ${3}/master.ign s3://${5}/master.ign --acl public-read
if [ $? -ne 0 ]; then
	exit 1
fi

aws s3 cp ${3}/worker.ign s3://${5}/worker.ign --acl public-read
if [ $? -ne 0 ]; then
	exit 1
fi
#/bin/bash

openshift-install wait-for bootstrap-complete --dir=${1} --log-level info
if [ $? -ne 0 ]; then
	exit 1
fi

export KUBECONFIG=${1}/auth/kubeconfig


# Replace the default ingress operator; use loadbalancer provisioned in terraform.
echo "Replacing default ingress controller to prevent OCP from creating AWS resources."
if [ $(oc get ingresscontrollers -n openshift-ingress-operator | awk 'NR>1{print $1}' | wc -l) -ne 0 ]; then
    until oc delete ingresscontroller default -n openshift-ingress-operator
    do
        sleep 5
    done
fi
until oc create -f ${1}/ingresscontroller-default.yaml
do
    sleep 1 # OCP will try and recreate original if we do not replace ASAP
done


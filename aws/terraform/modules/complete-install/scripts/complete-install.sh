#/bin/bash

export KUBECONFIG=${1}/auth/kubeconfig

echo "Waiting 2 minutes for workers to initialize."
sleep 120 

while [ $(oc get csr | grep Approved,Issued | wc -l) -lt $((${2}*2)) ]; do
    if [ $(oc get csr | grep Pending | wc -l) -ne 0 ]; then
        oc get csr | grep Pending | sed 's/\s.*$//' | xargs oc adm certificate approve
    fi
     sleep 5
done

echo "Waiting 2 minutes for Operators to initialize."
sleep 120 

# Keep recreating the ingresscontroller until able to connect to Authentication Operator
while [ $(oc get clusteroperator | grep Unknown | wc -l) -ne 0 ]; do
    echo "Restarting the Ingresscontroller Operator..."
    oc delete ingresscontroller default -n openshift-ingress-operator
    oc create -f ${1}/ingresscontroller-default.yaml
    sleep 60
done
echo "Authentication Operator is reachable."

openshift-install --dir=${1} wait-for install-complete
if [ $? -ne 0 ]; then
	exit 1
fi
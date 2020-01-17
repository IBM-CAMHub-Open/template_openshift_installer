#/bin/bash

install_dir=${1}
total_nodes=${2}

export KUBECONFIG=${install_dir}/auth/kubeconfig

if ! [ -f "${install_dir}/.install_complete" ]; then  #fresh install
    echo "Waiting for all nodes to register in cluster..."
    while [ $(oc get csr | grep -P '^(?=.*system:node)(?=.*Approved,Issued)' | wc -l) -lt ${total_nodes} ]; do 
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
        oc create -f ${install_dir}/ingresscontroller-default.yaml
        sleep 60
    done
    echo "Authentication Operator is reachable."

    openshift-install --dir=${install_dir} wait-for install-complete
    if [ $? -ne 0 ]; then
        exit 1
    fi

    touch ${install_dir}/.install_complete

elif [ $(oc get nodes --no-headers | wc -l) -lt ${total_nodes} ]; then #scale up
    echo "Adding nodes..."
    while [ $(oc get nodes --no-headers | wc -l) -lt ${total_nodes} ]; do 
        if [ $(oc get csr | grep Pending | wc -l) -ne 0 ]; then
            oc get csr | grep Pending | sed 's/\s.*$//' | xargs oc adm certificate approve
        fi
        sleep 60
    done

    echo "Bootstrap CSRs approved, waiting 30 seconds for remaining node CSRs..."
    sleep 60 
    oc get csr | grep Pending | sed 's/\s.*$//' | xargs oc adm certificate approve

fi

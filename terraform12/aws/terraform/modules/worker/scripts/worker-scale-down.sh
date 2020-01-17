#/bin/bash

install_dir=${1}
private_ip=${2}

export KUBECONFIG=${install_dir}/auth/kubeconfig

if [ -f "${install_dir}/.install_complete" ]; then
    echo "Scaling down ${private_ip}..."
    node_name=$(oc get nodes -o wide | grep ${private_ip} | sed 's/\s.*$//')
    oc adm cordon ${node_name}
    oc adm drain ${node_name} --force --delete-local-data --ignore-daemonsets
    oc delete nodes ${node_name}
fi
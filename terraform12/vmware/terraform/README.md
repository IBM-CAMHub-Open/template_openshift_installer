# OpenShift Container Platform Enterprise Installer

The OpenShift Container Platform Enterprise Installer Terraform template will provision several 
virtual machines, install prerequisites and install an enterprise HA-ready version of OpenShift 
Container Platform within you VMware Hypervisor enviroment.

The template installs the following components of a OpenShift Container Platform:

- Bootstrap Node which can be deleted once the cluster is running.
- Control Plane Nodes (aka master nodes that contains etcd cluster - minimum 3 nodes) 
- Compute Nodes (aka worker nodes - minimum 2 nodes)
- Infrastructure Node

Refer to [OCP Install Page](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html) 
on more details on how OCP 4.2 installer works on VMware. 

## Infrastrucure node

The infrastructure node created by the template drives the installation and configuration of the OCP cluster. 
The infrastructure node acts as web server, DHCP server, DNS server, load balancer, NFS server and 
bastion server for the OCP cluster nodes.
 
The infrastructure node contains:

- Openshift installer server and client CLI. Uses these CLI to generate the install files and monitor the installation.
- Apache Web Server to serve the ignition files (on port 8080) to the OCP cluster nodes during node boot process.
- dnsmasq based DHCP and DNS server to provide private IP addresses to the OCP nodes and to hold the cluster [DNS entries](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-dns-user-infra_installing-vsphere).
- HA Proxy to load balance the api and app URL calls to control and compute nodes on ports 80/443, 22623 and 6443.
- NFS server used for OCP image registry storage (minimum sotrage is 100 GB). Uses the second disk in the machine as NFS storage.
- Firewall is set up to allow the [following ports](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-network-user-infra_installing-vsphere)
- OC CLI to work with the created OCP cluster nodes. You can use the default kubeconfig located on infrastructure node at /installer/auth/kubeconfig to execute the OC CLI commands.

Since infrastrucure node acts as bastion server for the OCP cluster, you can login to the OCP cluster nodes 
from the infrastructure nodes using the private key in ~/.ssh/id_rsa_ocp as user core.

### Infrastrucure node network requirements

Infrastrucure node requires two network interfaces. One in the private network and one in the public network.
The private and the public network are NATed using iptables and the infrastructure node acts as a gateway for
for the OCP cluster nodes which are created in the private network. Since any virtual machines in a VMware network
can request an IP address from DHCP server in that network, to avoid IP and cluster collision there 
can be only one OCP cluster installation per private network. 

## How the template installation works

The template first creates the infrastructure node (RHEL 7.4 or higher) with a public and private interface. Then downloads,
installs and configures Apache Web Server, dnsmasq, HAProxy, NFS packages, Openshift installer server and 
client CLI and OC CLI. To download these infrastructure node will require internet connection.

Openshift installer CLI is then used to generate the necessary [installation files](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-initializing-manual_installing-vsphere),
and, [kubernetes manifest and ignition files](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-user-infra-generate-k8s-manifest-ignition_installing-vsphere).
The generated ignition files are placed in the web server's root location. Firewall is configured on the infratructure node
to allow all the necessary port documented by OCP installation guide including ssh port (22), nfs port (2049) and web server port (8080).

The template then creates the bootstrap node using the generated ignition file. The ignitions file is input 
to VMware RHCOS 4.2 template as vapp properties. Once bootstrap node is up, the template first creates control node and 
then creates compute nodes using the respective ignition files (which are also input to VMware RHCOS 4.2
template as vapp properties). At the end of each step the dnsmasq DNS and HAProxy load balancer are updated with the DHCP generated IP and 
corresponding host/URL values. 

Finally template sets up the [NFS storage for image repository](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-operators-config_installing-vsphere) 
and completes the installation.

## System Requirements

### Hardware requirements

This template will setup the following hardware minimum requirements:

| Node Type | CPU Cores | Memory (mb) | Disk 1 | Disk 2 | Number of hosts | 
|------|:-------------:|:----:|:-----:|:-----:|:-----:|
| Bootstrap (can be removed) | 4 | 16384 | 120 | n/a | 1 |
| Control Plane (master) | 4 | 16384 | 120 | n/a | 3 |
| Compute | 2 | 8192 | 120 | n/a | 2 |
| Infrastructure | 4 | 8192 | 200 | 100 | 1 |

### Network requirements

Requires two networks - a public and a one private network. OCP nodes must be on private network. 
Only one OCP cluster can be in one private network. Infrastructure node requires internet access.

In order to allow access to the OCP console, you must add an entry in your public DNS that maps the 
infrastructure node's public IP to the .apps.<OCP_CLUSTER_NAME>.<OCP_DOMAIN_NAME>. Alternately you can also
adding the following IP to hosts mapping in your local etc hosts files.

***INFRA_NODE_PUBLIC_IP*** console-openshift-console.apps.<OCP_CLUSTER_NAME>.<OCP_DOMAIN_NAME>

***INFRA_NODE_PUBLIC_IP*** oauth-openshift.apps.<OCP_CLUSTER_NAME>.<OCP_DOMAIN_NAME>

### Supported operating systems and platforms

The following operating systems and platforms are supported.

- Red Hat Enterprise Linux (RHEL) 7.4 or later for Infrastructure node
- RHCOS 4.2 for OCP boot, control and compute nodes
- VMware Tools must be enabled in the image for VMWare template.
- sudo User and password must exist and be allowed for use.
- Refer to [vSphere infrastructure requirements](https://docs.openshift.com/container-platform/4.2/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-infrastructure_installing-vsphere) for more vSphere requirements.

## OpenShift Container Platform Versions

| OpenShift Version | GitTag Reference|
|------|:-------------:|
| 4.2 | 4.2 |

## Template input data types and parameters

### Input Data Types

Piror to deploying the template you must create the data objects for the following data types.

| Data Type | Description |
|------|-------------|
| vSphere Managed Inventory Definition | vSphere Managed Inventory Objects that are used in virtual machine creation. `Template used must be RHEL 7.4 or higher.` |
| OpenShift Container Platform Infrastructure Node on VMware | Defines the cpu, datastore, memory, and storage capacity of an OCP Infrastructure node on vSphere. |
| OpenShift Container Platform 4.2 Bootstrap Node on VMware | Defines the cpu, memory, and storage capacity of an OCP Bootstrap node on vSphere. |
| OpenShift Container Platform Control Plane Node on VMware | Defines the cpu, number of node, memory, and storage capacity of an OCP Control Plane node on vSphere. |
| OpenShift Container Platform 4.2 Compute Node on VMware | Defines the cpu, number of compute node, memory, and storage capacity of an OCP compute node on vSphere. |

### Input Parameters

When you deploy this template the UI will also display the parameters that are pre-filled from the 
above created data objects. The following table lists only those input parameters that are not part of the data
objects.

| Input Parameter | Description |
|------|-------------|
| Infrastructure Node Hostname | Hostname of the infrastructure node. |
| Infrastructure Node Public IP Address | Infrastructure Node Public IP Address. This IP address must have a mapping to the OCP cluster app URL in your DNS or in your local etc hosts file. |
| OCP Cluster Name | A unique name that identifies each OCP cluster. The combination of this cluster name and the OCP domain name creates a cluster domain, that will be used by OCP cluster nodes and the URLs. |
| OCP Base Domain Name | Domain name for the OCP cluster. The combination of cluster name and this domain name creates a cluster domain, that will be used by OCP cluster nodes and the URLs. |
| OCP Cluster VMs Template Name (RHCOS 4.2 image template) | Name of the VM template to clone to create VMs for the cluster. |
| OCP Version | OCP Version. Default is 4.2.0 |
| Base64 encoded OCP image pull secret | Base64 encoded OCP image pull secret. You can obtain this from your Red Hat account page. The encoded string must not have newline (use base64 -w0). |
| Private Network name for infrastructure and OCP cluster VM | Private vSphere Network name for infrastructure and OCP cluster VM. |
| vSphere cluster Name | vSphere cluster name inside the vSphere data center. |

## Template output parameters

The following parameters are output by the template.

| Output Parameter | Description |
|------|-------------|
| OCP Console URL | Console URL that can be used to access the OCP cluster. You must either have a DNS mapping for this URL to the infrastrucutre node IP address or a local entry in etc hosts file.|
| Console Password for kubeadmin | Console password for kubeadmin user. |
| Boot Node IP Address | IP of bootstrap node. This can be deleted after cluster is up. |
| Control plane Node IP Address | IP address of control plane nodes. You can login to these VMs from Infrastructure node as user `core` and the key displayed in `OCP Cluster VM Private Key` |
| Compute IP Address | IP address of compute nodes. You can login to these VMs from Infrastructure node as user `core` and the key displayed in `OCP Cluster VM Private Key` |
| OCP Cluster VM Private Key (base64 encoded) | Base64 encoded private key to login to the boot, control and compute nodes from Infrastructure node as user `core`. The encoded string must not have newline (use base64 -w0). |



  

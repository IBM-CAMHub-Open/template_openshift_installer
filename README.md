# OpenShift Container Platform Enterprise Installer
The OpenShift Container Platform Enterprise Installer Terraform template and inline modules will provision several virtual machines, install prerequisites and install an enterprise HA-ready version of OpenShift Container Platform within you vmWare Hypervisor enviroment.

This template will install and configure an enterprise HA-ready version of OpenShift Container Platform.

# Environment scenarios

The components of a OpenShift Container Platform include:

- Master Nodes
- Etcd Nodes (can share the host with Master Nodes)
- Compute Nodes (Minimum 3 for installing glusterfs)
- Infrastructure Node
- Load Balancer Node (HA only)

The following table describes an example environment for a single master (with a single etcd instance running as a static pod on the same host), one node for hosting user applications, and one node for hosting dedicated infrastructure ( ***Minimal Topology*** )

| Host Name | Component/Role(s) to Install |
|------|------|
| master.example.com | Master and etcd |
| node.example.com | Compute node |
| infra-node.example.com | Infrastructure node |

The following describes an example environment for three masters using the native HA method:, one HAProxy load balancer, three etcd hosts, two nodes for hosting user applications, and two nodes for hosting dedicated infrastructure:

| Host Name | Component/Role(s) to Install |
|------|------|
| master1.example.com | Master (clustered using native HA) and node |
| master2.example.com | Master (clustered using native HA) and node |
| master3.example.com | Master (clustered using native HA) and node |
| lb.example.com | HAProxy to load balance API master endpoints |
| etcd1.example.com | etcd |
| etcd2.example.com | etcd |
| etcd3.example.com | etcd |
| node1.example.com | Compute node |
| node2.example.com | Compute node |
| infra-node1.example.com | Dedicated infrastructure node |
| infra-node2.example.com | Dedicated infrastructure node |

For more information and examples, please check: https://docs.openshift.com/container-platform/3.11/install/example_inventories.html#overview


## OpenShift Container Platform Versions

| OpenShift Version | GitTag Reference|
|------|:-------------:|
| 3.11 | 3.11 |

## System Requirements

### Hardware requirements

OpenShift Container Platform must meet the following requirements:
<https://docs.openshift.com/container-platform/3.11/install/prerequisites.html#hardware>

This template will setup the following hardware minimum requirements:

| Node Type | CPU Cores | Memory (mb) | Disk 1 | Disk 2 | Number of hosts | 
|------|:-------------:|:----:|:-----:|:-----:|:-----:|
| Master | 4 | 16384 | 100 | n/a | 1 |
| Compute | 1 | 8192 | 100 | 100 (for glusterfs) | 1 |
| Etcd  | 1 | 8192 | 100 | n/a | 1 |
| Infrastructure | 1 | 8192 | 100 | n/a | 1 |
| Load Balancer | 1 | 8192 | 100 | n/a | 1 |

For minimum directory space requirements, i.e. /var/ or /usr/local/bin/, 
please refer to https://docs.openshift.com/container-platform/3.11/install/prerequisites.html#hardware

### Supported operating systems and platforms

The following operating systems and platforms are supported.

***Red Hat Enterprise Linux (RHEL) 7.4 or later***

- VMware Tools must be enabled in the image for VMWare template.
- Sudo User and password must exist and be allowed for use.
- SELinux must be enabled. 
https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3.1/html/installation_guide/chap-enabling_selinux
- Minimum recommended kernel version is '3.10.0-862.14.4'

# Highly Available OpenShift Deployment on AWS
This Terraform configurations uses the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html) to prepare VMs and deploy [OpenShift](https://www.openshift.com/) on them.

This [template](https://github.com/IBM-CAMHub-Open/template_icp_aws/tree/master/templates) provisions a highly-available cluster with Openshift 4.2. This template can be executed using [IBM Cloud Automation Manager](https://www.ibm.com/support/knowledgecenter/en/SS2L37/product_welcome_cloud_automation_manager.html).

## Executing the template
The following sections describe how to execute this template using [IBM Cloud Automation Manager](https://www.ibm.com/support/knowledgecenter/en/SS2L37/product_welcome_cloud_automation_manager.html).

In your IBM Cloud Automation Manager navigate to Library > Templates > Starterpack > IBM Cloud Private highly-available cluster in AWS and select Deploy operation. Fill the following input parameters and deploy the template.

### Input Variables

#### AWS
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Key Pair Name |  | Name of the EC2 key pair. |
| Key Pair Private Key |  | Base64 encoded private key file contents of the EC2 key pair. |
| S3 Bucket |  | The s3 bucket name that will store the ignition files required for OPENSHIFT cluster nodes.

#### Redhat
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Redhat Pull Secret | | Base64 encoded Redhat Pull Secret. Used to pull Openshift related install files.

#### Network
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Region | us-east-2 | AWS region to deploy your ICP cluster nodes. The AWS selected region should have at least 3 availability zones. |
| Availability Zones | [a, b, c] | The availability zone letter identifier in the above selected region. The AWS selected region should have at least 3 availability zones. |
| Cluster Name | openshift-cluster | OPENSHIFT cluster prefix. Used to prefix a randon string used to name and tag VPC and other AWS resources created for OPENSHIFT nodes. | 
| Public Domain Name |  | The domain entered must be in the Route53 public hosted zone. |
| VPC CIDR | 10.0.0.0/16 | The CIDR block for the VPC | 
| Public Subnet CIDRs | [10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24], | Used for the bastion, bootstrap nodes and the public facing load balancers. You must provide one for each availability zone. | 
| Private Subnet CIDRs | [ 10.0.20.0/24, 10.0.21.0/24, 10.0.22.0/24], | Used for the OpenShift cluster nodes, and private load balancers. You must provide one for each availability zone. | 

#### Bastion
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Create/Destroy Bastion | Create | Create or destroy bastion for the OpenShift install.  Required for installation. Can be removed after if no longer required after successful installation. | 
| Instance Type | t2.micro | List of Recommended Instance types. | 
| Disk Size (GiB) | 50 | Enter size of root disk in gibibytes | 

#### Bootstrap
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Create/Destroy Bastion | Create | Create or destroy bastion for the OPENSHIFT install.  Required for installation. Can be removed after if no longer required after successful installation. | 
| Instance Type | t2.micro | List of Recommended Instance types. | 
| Disk Size (GiB) | 50 | Enter size of root disk in gibibytes | Create or destroy bootstrap for the OpenShift install.  Required for installation.  Should be removed after successful installion. | 

#### Control Plane 
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Number of Master Nodes | 3 | Enter a valid number of master nodes - between 3 and 100.
| Instance Type | m4.xlarge | List of Recommended Instance types. | 
| Disk Size (GiB) | 120 | Enter size of root disk in gibibytes. | 

#### Compute Nodes
| Parameter | Default Value | Description |
| :-------------- |:--------------| :-----|
| Number of Worker Nodes | 3 | Enter a valid number of master nodes - between 2 and 100.
| Instance Type | m4.large | List of Recommended Instance types. | 
| Disk Size (GiB) | 120 | Enter size of root disk in gibibytes. | 

### Output Variables
| Parameter | Description |
| :-------------- | :-----|
| OpenShift Cluster Name | Generated OpenShift Cluster Name (Provided cluster name with a random character string attached). |
| Bastion Public IP | Bastion Host IP address.  If the Bastion was destroyed on a subsequent Plan/Apply it will contain the string "destroyed" |
| Bootstrap Public IP | If the bootstrap was destroyed on a subsequent Plan/Apply it will contain the string "destroyed" |
| OpenShift Web Console | URL that can be logged into using the install provided user and password. |
| kubeadmin User | Default user to log into the OpenShift web-console. |
| kubeadmin Password | Default password for the kubeadmin user. |
| kubeconfig | To access the cluster as the system:admin user when using 'oc', Save the kubeconfig output to a file i.e. __kubeconfig__ then run 'export KUBECONFIG=__kubeconfig__ |

### Data Objects Created
This template creates the following data objects that can be used in other templates like [IBM Multicloud Manager](https://github.com/IBM-CAMHub-Open/template_mcm_install) or in service composition like [ICP cluster with klusterlet on Amazon EC2](https://github.com/IBM-CAMHub-Open/servicelibrary/tree/master/Services/ICP/ICP_on_AmazonEC2/ICP_cluster_and_MCM_Klusterlet) 

| Data Object Type | Description |
| :-------------- | :-----|
| bastionhost | Bastion host details that can be used in other templates to connect to Openshift cluster using bation host. |

## Installation Procedure
The installer automates the install procedure described [here](https://docs.openshift.com/container-platform/4.2/installing/installing_aws_user_infra/installing-aws-user-infra.html).


### License and Maintainer
Copyright IBM Corp. 2019

Template Version - 4.2.0
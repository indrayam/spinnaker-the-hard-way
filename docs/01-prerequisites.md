# Pre-requisites

This tutorial assumes you have access to programmable infrastructure, either self-hosted or using public cloud. I decided to run it on my internal OpenStack cluster. You can follow this along on any Public Cloud provider offering IaaS. [Digital Ocean](https://www.digitalocean.com/) would be a good choice.

![Spinnaker Distributed Install](https://storage.googleapis.com/us-east-4-anand-files/misc-files/spinnaker-distributed-install.png)

Here are the prerequisites and/or assumptions for the rest of the Labs:

- Spinnaker will be installed on Kubernetes
- Kubernetes Cluster is already available. My setup highlights:
  - One VM acting as Control Plane Master (4vCPUx8GB)
  - 9 Cluster Nodes (4vCPUx8GB) each running Ubuntu 16.04
  - Kubernetes version: 1.13.3 version
- Use an additional VM (2vCPUx4GB) running Ubuntu 16.04 for the following purposes: 
  - Running Halyard
  - Running TCP Proxy (Nginx) for my Kubernetes Cluster
  - Run NFS Server for Minion installation

Let's talk about the additional VM. You can choose to install Halyard, TCP Proxy (Nginx) and NFS Server each on a separate VM. However, I decided to keep it simple and use a single VM for that. So when I refer to VM running Nginx as a TCP Proxy or Halyard or NFS Server, I am talking about this Node. 

We are going to call this VM  **ENTRY VM** throughout the rest of the Labs.


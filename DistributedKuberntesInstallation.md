# Spinnaker The Hard Way

This tutorial walks you through setting up Spinnaker on Kubernetes the hard way. Needless to say, everything about this documentation is inspired by the amazing work done by Kelsey Hightower's [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way). Like the original document, this Spinnaker guide is not for people looking for a fully automated command to bring up a Kubernetes cluster with Spinnaker installed.

## Labs

This tutorial assumes you have access to programmable infrastructure, either self-hosted or using public cloud.

* [Prerequisites](docs/01-prerequisites.md)
* [Setup TCP Proxy on ENTRY VM](docs/02-setup-tcp-proxy.md)
* [Setup NFS Client(s) and Server](docs/03-setup-nfs-client-server.md)
* [Setup Tools](docs/04-setup-tools.md)
* [Setup Persistent Storage for Spinnaker (Minio)](docs/05-setup-minio.md)
* [Setup Minimal Hal Configuration](docs/06-setup-minimal-halconfig.md)
* [Configure External HTTPS access for Spinnaker Deck and Gate](docs/07-configure-https-access.md)
* [Wrap-up Spinnaker Setup](docs/08-run-spinnaker.md)
* [Setup Advanced Hal Configurations](docs/09-setup-advanced-halconfig.md)

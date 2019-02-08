# Spinnaker The Hard Way

![Spinnaker Distributed Install](https://storage.googleapis.com/us-east-4-anand-files/misc-files/spinnaker-distributed-install.png)

This tutorial walks you through setting up Spinnaker (on Kubernetes) The Hard way. Needless to say, everything about this documentation is inspired by Kelsey Hightower's masterpiece **[Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)**. Like the original document, this Spinnaker guide is not for people looking for a fully automated command to bring up a Kubernetes cluster with Spinnaker installed.

## Labs

* [Prerequisites](docs/01-prerequisites.md)
* [Setup TCP Proxy on ENTRY VM](docs/02-setup-tcp-proxy.md)
* [Setup NFS Client(s) and Server](docs/03-setup-nfs-client-server.md)
* [Setup Halyard](docs/04-setup-halyard.md)
* [Setup Persistent Storage (Minio)](docs/05-setup-minio.md)
* [Setup Minimal Halyard Configuration](docs/06-setup-minimal-halconfig.md)
* [Configure External HTTPS access](docs/07-configure-https-access.md)
* [Wrap-up Spinnaker Setup](docs/08-wrapup-setup.md)
* [Setup Advanced Halyard Configurations](docs/09-setup-advanced-halconfig.md)

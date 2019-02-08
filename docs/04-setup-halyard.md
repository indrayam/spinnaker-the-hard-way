## Setup Halyard on ENTRY VM

Before we install `Halyard`, we will install a slew of tools that will make us productive on the ENTRY VM.

## kubectl

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

## gcloud

```bash
{
    # Create environment variable for correct distribution
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

    # Add the Cloud SDK distribution URI as a package source
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # Import the Google Cloud Platform public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

    # Update the package list and install the Cloud SDK
    sudo apt-get update && sudo apt-get install google-cloud-sdk
}

```

## Fix Kubernetes CLI Prompt

```bash
cd $HOME
git clone git@github.com:jonmosco/kube-ps1.git .kube-ps1
exit
{
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
rm -f /usr/local/bin/kubectx /usr/local/bin/kubens /usr/local/bin/stern
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
curl -L -O https://github.com/wercker/stern/releases/download/1.8.0/stern_linux_amd64
chmod +x stern_linux_amd64
sudo mv stern_linux_amd64 /usr/local/bin/stern
curl -L -O https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz
tar -xvzf openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz
sudo mv openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit /opt/openshift/
sudo ln -s /opt/openshift/oc /usr/local/bin/oc
}
```

## Create Kubernetes Context Entry for Spinnaker

Create `sa.yaml` in `~/src`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spinnaker-service-account
  namespace: spinnaker
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: spinnaker-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: spinnaker-service-account
  namespace: spinnaker
```

Make sure `.kube/config` contains information about the Kubernetes cluster you would be installing Spinnaker into. 

```bash
cd ~/src
k create namespace spinnaker
k create -f sa.yml
CONTEXT=admin@code-alln-work
TOKEN=$(kubectl get secret --context $CONTEXT \
   $(kubectl get serviceaccount spinnaker-service-account \
       --context $CONTEXT \
       -n spinnaker \
       -o jsonpath='{.secrets[0].name}') \
   -n spinnaker \
   -o jsonpath='{.data.token}' | base64 --decode)

kubectl config set-credentials ${CONTEXT}-token-user --token $TOKEN
```

## Halyard

```bash
{
cd ~/src
# Install Java
apt-get -y install default-jre
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/local/java
# Install Halyard
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
sudo bash InstallHalyard.sh --version 1.15.0
}
```

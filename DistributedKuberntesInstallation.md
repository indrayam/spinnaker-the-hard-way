# Spinnaker The Hard Way

## Spinnaker Distributed Installation Pre-requisites

- Spinnaker will be installed on Kubernetes
- Kubernetes Cluster is already avaialble. My setup highlights:
  - One VM acting as Control Plane Master (4vCPUx8GB)
  - 9 Cluster Nodes (4vCPUx8GB) each running Ubuntu 16.04
  - Kubernetes version: 1.13.3 version
- Use an additional VM (2vCPUx4GB) running Ubuntu 16.04 for the following purposes: 
  - Running Halyard
  - Running TCP Proxy (Nginx) for my Kubernetes Cluster
  - Run NFS Server for Minion installation

Let's talk about the additional VM. You can choose to install Halyard, TCP Proxy (Nginx) and NFS Server each on a separate VM. However, I decided to keep it simple and use a single VM for that. So when I refer to VM running Nginx as a TCP Proxy or Halyard or NFS Server, I am talking about this Node. Let's call it `ENTRY` VM.

I decided to run it on my internal OpenStack cluster. You can follow this along on any Public Cloud provider offering IaaS. [Digital Ocean](https://www.digitalocean.com/) would be a good choice.

## Get Nginx updated on ENTRY VM

Update Nginx to the latest version offered by `nginx.org`

```bash
sudo vim /etc/nginx/tcppassthrough.conf (Update the Upstream Port numbers for 80 and 443)

sudo wget https://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo vim /etc/apt/sources.list.d/nginx.list 
#Add the following lines to nginx.list:
#    deb https://nginx.org/packages/mainline/ubuntu/ <CODENAME> nginx
#    deb-src https://nginx.org/packages/mainline/ubuntu/ <CODENAME> nginx
```

```bash
sudo apt-get remove nginx #Remove existing Nginx install (if any)
sudo apt-get install nginx
```

## Update /etc/nginx/nginx.conf on ENTRY VM

```bash
{
    ...
    #include /etc/nginx/conf.d/*.conf;
    #include /etc/nginx/sites-enabled/*;
}

include /etc/nginx/tcppassthrough.conf;
```

## TCP LB and SSL passthrough on ENTRY VM

Update the `/etc/nginx/tcppassthrough.conf` file with the IP addresses of the 9 Kubernetes Worker Nodes. Do not worry about the two port number stes (31092 and 31391) shown below. This will need to get updated after Heptio Contour Ingress Controller is installed (see below)

```bash
## tcp LB  and SSL passthrough for backend ##
stream {

    log_format combined '$remote_addr - - [$time_local] $protocol $status $bytes_sent $bytes_received $session_time "$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 192.168.1.19:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:11111 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 192.168.1.19:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:22222 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 80;
        proxy_pass httpenvoy;
        proxy_next_upstream on;
    }

    server {
        listen 443;
        proxy_pass httpsenvoy;
        proxy_next_upstream on;
    }
}
```

```bash
sudo nginx -t
sudo systemctl stop nginx
sudo systemctl start nginx
```

## Setup NFS Server on ENTRY VM


```bash
sudo apt-get install -y nfs-kernel-server
sudo mkdir /var/nfs/minio -p
sudo chown nobody:nogroup /var/nfs/minio

sudo vim /etc/exports

# The two address ranges are to make sure that clients ONLY from these ranges can connect to the NFS server
/var/nfs/minio  192.168.1.0/24(rw,sync,no_subtree_check)
#/var/nfs/minio  64.102.178.0/23(rw,sync,no_subtree_check) 64.102.186.0/23(rw,sync,no_subtree_check)
sudo systemctl restart nfs-kernel-server
```

## Setup NFS Client on all 9 Kubernetes Cluster Nodes

The IP address portion in this line:
`sudo mount 192.168.1.14:/var/nfs/minio /nfs/minio`

should be the IP address of the NFS server

```bash
sudo apt-get install nfs-common
{
    sudo mkdir -p /nfs/minio
    sudo mount 192.168.1.14:/var/nfs/minio /nfs/minio
    df -h
}
```

```bash
sudo vim /etc/fstab
192.168.1.14:/var/nfs/minio /nfs/minio nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
sudo umount /nfs/minio (if you need to)
```

## Install K8s/Cloud Tools on ENTRY VM

**Install kubectl:**

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

**Install gcloud:**

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

**Install fix k8s prompts:**

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

**Create a Namespace for Spinnaker Microservices:**

Make sure `.kube/config` contains information about the Kubernetes cluster you would be installing Spinnaker into

```bash
cd ~/src
k create namespace spinnaker
k create -f sa.yml
CONTEXT=k8s-on-p3-rtp
TOKEN=$(kubectl get secret --context $CONTEXT \
   $(kubectl get serviceaccount spinnaker-service-account \
       --context $CONTEXT \
       -n spinnaker \
       -o jsonpath='{.secrets[0].name}') \
   -n spinnaker \
   -o jsonpath='{.data.token}' | base64 --decode)

kubectl config set-credentials ${CONTEXT}-token-user --token $TOKEN
```

## Install Halyard on ENTRY VM

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

That said, using the Docker version is actually a LOT more flexible

```bash
cd ~/
echo "Clone halyard configurations private repo..."
git clone git@github.com:indrayam/dothal.git ~/.dothal
echo "Clone kube config private repo..."
git clone git@github.com:indrayam/dotkube.git ~/.dotkube
ln -s ~/.dotkube .kube
ln -s ~/.dothal .hal
docker run -p 8065:8064 --name halyard -d -v ~/.dothal:/home/ubuntu/.hal \
    -v ~/.dotkube:/home/ubuntu/.kube \
    gcr.io/spinnaker-marketplace/halyard:nightly
```

Make sure the docker container `halyard` is running by running the following command:

```bash
docker ps 
```

Exec into the docker container using `docker exec -it halyard bash`. Don't forget to setup a symlink:

```bash
cd
ln -s /home/ubuntu/.hal .hal
ln -s /home/ubuntu/.kube .kube 
```

## Configure the Timezone

```bash
hal config edit --timezone 'America/New_York'
```

Not sure if this worked though. Not at the UI level

## Configure Spinnaker Kubernetes Account for Installation

```bash
hal config provider kubernetes account add code-work-alln --provider-version v2 --context admin@code-work-alln

hal config features edit --artifacts true

hal config deploy edit --type distributed --account-name code-work-alln

```

## Configure Spinnaker Account for Docker Registry

```bash
hal config provider docker-registry account add dockerhub \
    --address index.docker.io \
    --repositories "library/nginx indrayam/debug-container indrayam/kubia" \
    --username indrayam \
    --password
```

## Configure HTTP Artifact Support

```bash
{
USERNAME='automation'
PASSWORD='<password>'
USERNAME_PASSWORD_FILE='/home/ubuntu/.bitbucket-user'
echo ${USERNAME}:${PASSWORD} > $USERNAME_PASSWORD_FILE
GITSCM_HTTP_ARTIFACT_ACCOUNT_NAME=automation-gitscm
hal config artifact http enable
hal config artifact http account add ${GITSCM_HTTP_ARTIFACT_ACCOUNT_NAME} \
    --username-password-file $USERNAME_PASSWORD_FILE
}
```

## Configure GitHub Artifact Support

```bash
{
TOKEN='<password>'
TOKEN_FILE='/home/ubuntu/.dothal/tokens/github-token'
echo $TOKEN > $TOKEN_FILE
GITHUB_ARTIFACT_ACCOUNT_NAME=indrayam-github
hal config artifact github enable
hal config artifact github account add $GITHUB_ARTIFACT_ACCOUNT_NAME \
    --token-file $TOKEN_FILE
}
```

## Configure GCS Artifact Support

```bash
{
    SERVICE_ACCOUNT_NAME='spinnaker-gce-account'
    SERVICE_ACCOUNT_DEST='~/.config/gcloud/evident-wind-163400-spinnaker.json'
    
    #gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name $SERVICE_ACCOUNT_NAME
    
    SA_EMAIL=$(gcloud iam service-accounts list \
        --filter="displayName:$SERVICE_ACCOUNT_NAME" \
        --format='value(email)')
    
    PROJECT=$(gcloud info --format='value(config.project)')

    gcloud projects get-iam-policy $PROJECT
    # If the roles/storage.admin is not there, set it by running the following command:
    #gcloud projects add-iam-policy-binding $PROJECT --role roles/storage.admin --member serviceAccount:$SA_EMAIL

    #mkdir -p $(dirname $SERVICE_ACCOUNT_DEST)

    #gcloud iam service-accounts keys create $SERVICE_ACCOUNT_DEST --iam-account $SA_EMAIL
    ARTIFACT_ACCOUNT_NAME=evident-wind-gcs
    hal config features edit --artifacts true
    hal config artifact gcs account add $ARTIFACT_ACCOUNT_NAME \
        --json-path $SERVICE_ACCOUNT_DEST
}
```

## Configure Persistent Storage (Minio)

Create Minio Kubernetes files:

- **minio-standalone-pv.yml:** Set the IP address of the NFS server

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minio-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    path: /var/nfs/minio
    server: 192.168.1.14
  persistentVolumeReclaimPolicy: Retain
```

- **minio-standalone-pvc.yml:**

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  # This name uniquely identifies the PVC. This is used in deployment.
  name: minio-pv-claim
spec:
  # Read more about access modes here: http://kubernetes.io/docs/user-guide/persistent-volumes/#access-modes
  accessModes:
    # The volume is mounted as read-write by a single node
    - ReadWriteOnce
  resources:
    # This is the request for storage. Should be available in the cluster.
    requests:
      storage: 10Gi
  storageClassName: ""
```

- `minio-standalone-deployment.yml:` Update values for *MINIO_ACCESS_KEY* and *MINIO_SECRET_KEY*

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  # This name uniquely identifies the Deployment
  name: minio-deployment
spec:
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        # Label is used as selector in the service.
        app: minio
    spec:
      # Refer to the PVC created earlier
      volumes:
      - name: storage
        persistentVolumeClaim:
          # Name of the PVC created earlier
          claimName: minio-pv-claim
      containers:
      - name: minio
        # Pulls the default Minio image from Docker Hub
        image: minio/minio
        args:
        - server
        - /storage
        env:
        # Minio access key and secret key
        - name: MINIO_ACCESS_KEY
          value: "..."
        - name: MINIO_SECRET_KEY
          value: "..."
        ports:
        - containerPort: 9000
        # Mount the volume into the pod
        volumeMounts:
        - name: storage # must match the volume name, above
          mountPath: "/storage"
```

- `minio-standalone-service.yml:` Set the Service Type to ClusterIP

```yaml
apiVersion: v1
kind: Service
metadata:
  # This name uniquely identifies the service
  name: minio-service
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
      protocol: TCP
  selector:
    # Looks for labels `app:minio` in the namespace and applies the spec
    app: minio
```

Once these files are created and saved in `~/src` folder, run the following commands:

```bash
cd ~/src
k apply -f ./minio-standalone-pv.yml
k apply -f ./minio-standalone-pvc.yml
k apply -f ./minio-standalone-deployment.yml
k apply -f ./minio-standalone-service.yml
```

Run the following `hal` command to configure persistent storage (minio):

```bash
{
MINIO_ACCESS_KEY="..."
MINIO_SECRET_KEY="..."
ENDPOINT="http://minio-service:9000"
echo $MINIO_SECRET_KEY | hal config storage s3 edit --endpoint $ENDPOINT \
    --access-key-id $MINIO_ACCESS_KEY \
    --secret-access-key
}
hal config storage edit --type s3
```

## Configure Jenkins Support

```bash
{
hal config ci jenkins enable

PASSWORD='Maltose$.123'
echo $PASSWORD | hal config ci jenkins master add my-jenkins-master \
    --address https://ci6.cisco.com \
    --username jenkins-ci.gen \
    --password
}
```

## Install Spinnaker

```bash
VERSION="1.12.1"
hal config version edit --version $VERSION
hal deploy apply
cd ~/.hal/default/profiles
vim front50-local.yml (add: spinnaker.s3.versioning: false)
hal deploy apply
```

## Configure ENTRY VM to route Spinnaker URLs to spin-deck and spin-gate Services

**Install Heptio Contour Ingress Controller:**

Source(s):
- [heptio/contour](https://github.com/heptio/contour)
- [Tutorial: Deploy web applications on Kubernetes with Contour and Let's Encrypt](https://github.com/heptio/contour/blob/master/docs/cert-manager.md)

```bash
cd ~/src
curl -L -O https://j.hept.io/contour-deployment-rbac
mv contour-deployment-rbac contour-deployment-rbac.yaml
vim contour-deployment-rbac.yaml
# Change the last line (Service type) from LoadBalancer to NodePort
k apply -f contour-deployment-rbac.yml
k -n heptio-contour get svc
kn default
```

Use the output of the `k -n heptio-contour get svc` to figure out what NodePort is mapped to Port(s) **80** and **443**. For example, let's say the output looks like this:

```
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
contour   NodePort   10.101.167.20   <none>        80:31092/TCP,443:31391/TCP   3h58m
```

Since port 80 is mapped to 31092 and 443 is mapped to 31391, update `/etc/nginx/tcppassthrough.conf` file's port numbers so that the section `httpenvoy` uses 31092 and the section `httpsenvoy` uses 31391:

```bash

stream {

    log_format combined '$remote_addr - - [$time_local] $protocol $status $bytes_sent $bytes_received $session_time "$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 192.168.1.19:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:31092 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 192.168.1.19:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:31391 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 80;
        proxy_pass httpenvoy;
        proxy_next_upstream on;
    }

    server {
        listen 443;
        proxy_pass httpsenvoy;
        proxy_next_upstream on;
    }
}
```

**Install KUARD demo app**

```bash
cd ~/src
curl -L -O https://j.hept.io/contour-kuard-example
mv contour-kuard-example contour-kuard-example.yaml
kn default
k apply -f contour-kuard-example.yaml
```

If you have `wercker/stern` installed, run the following command. It should show messages reflecting the fact that Heptio Contour was able to react to the new Ingress Object created in Kubernetes:

`stern contour`

You can also tail the Nginx stream log on the ENTRY VM machine to see if the TCP Proxy received and forwarded the request appropriately:

```
tail -f /var/log/nginx/stream-access.log
```

You should see an output like:

```
173.37.95.214 - - [08/Feb/2019:14:47:21 +0000] TCP 200 0 0 0.004 "192.168.1.16:31092"
```

Assuming `kuard1-code.cisco.com` is the DNS entry that points to the ENTRY VM's TCP Proxy, open `kuard1-code.cisco.com` in the browser. You should see the KUARD app.  

**Jetstack Cert Manager (self-signed):**

Source(s):
- [Installing cert-manager](https://docs.cert-manager.io/en/latest/getting-started/install.html)
- [Setting up CA Issuers](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-ca.html)
- [Automatically creating Certificates for Ingress resources](https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/ingress-shim.html)

Install Jetstack cert manager

```bash
k create namespace cert-manager
kn cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/cert-manager.yaml
```

```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -subj "/CN=Cisco CoDE Team" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
k create secret tls ca-key-pair --cert=ca.crt --key=ca.key --namespace=cert-manager
```

Create `ca-clusterissuer.yaml` file in `~/src`:

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: ca-key-pair
```

Run the following command to setup the ClusterIssuer in Kubernetes:

```
k apply -f ./ca-clusterissuer.yml
```

**Install Ingress Objects with Jetstack Annotations:**

Update the `contour-kuard-example.yaml` file's Ingress section (at the bottom of the file) with this content:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  labels:
    app: kuard
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: kuard1-code
    hosts:
    - kuard1-code.cisco.com
  rules:
  - host: kuard1-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: kuard
          servicePort: 80
---
```

Apply the changes to Kubernetes:

```bash
kn default
k apply -f contour-kuard-example.yaml
k get secret
# A new secret is created called kuard1-code
```

**Getting your MacOS to trust the self-signed cert**

```bash
echo quit | openssl s_client -showcerts -servername kuard1-code.cisco.com -connect kuard1-code.cisco.com:443 > kuard1-code.pem
vim kuard1-code.pem
# Delete everything above and below the BEGIN CERTIFICATE and END CERTIFICATE section
```

- Open KeyChain Access on your MacOS
- Drag and drop `kuard1-code.pem` into `All Items` Category of KeyChain Access tool
- Click on `Certificates` category
- Double-click the certificate
- Expand "Trust" dropdown
- Select "Always Trust"
- Open https://kuard1-code.cisco.com in Incognito Window

**Create Ingress Objects for Spinnaker**

Create `spinnaker1-code-ingress-https.yml` in `~/src`. If you want to create an Ingress resource without cert-manager features, remove the `annotations` and `spec>tls` blocks:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spinnaker-deck
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: spinnaker-deck-tls
    hosts:
    - spinnaker1-code.cisco.com
  rules:
  - host: spinnaker1-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: spin-deck
          servicePort: 9000
```

Create `spinnaker1api-code-ingress-https.yml` in `~/src`. If you want to create an Ingress resource without cert-manager features, remove the `annotations` and `spec>tls` blocks:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spinnaker-gate
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: spinnaker-gate-tls
    hosts:
    - spinnaker1api-code.cisco.com
  rules:
  - host: spinnaker1api-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: spin-gate
          servicePort: 8084
```

```bash
kn spinnaker
k apply -f ./spinnaker1-code-ingress-https.yml -n spinnaker
k apply -f ./spinnaker1api-code-ingress-https.yml -n spinnaker
```

## Update Base URLs for Spinnaker UI (spin-deck) and API Gateway (spin-gate)

```bash
hal config security ui edit \
    --override-base-url https://spinnaker1-code.cisco.com

hal config security api edit \
    --override-base-url https://spinnaker1api-code.cisco.com

hal deploy apply
```


## Advanced Nerd Knobs: Configure Email Notification Support

1. Create echo-local.yml file as below:

```bash
mail:
  enabled: true
  from: noreply@cisco.com
spring:
  mail:
    host: outbound.cisco.com
    port: 25
    properties:
      mail:
        smtp:
          auth: false
          starttls:
            enable: true
        transport:
          protocol: smtp
        debug: true
```

2. Copy the file into ~/.hal/default/profiles/ folder
3. Run: `hal deploy apply --service-names echo`


## Advanced Nerd Knobs: Configure LDAP Authentication

```bash
hal config security authn ldap edit --user-dn-pattern="cn={0},OU=Employees,OU=Cisco Users" --url=ldap://ds.cisco.com:3268/DC=cisco,DC=com
# Note, I had to remove the space betweeen Cisco and Users when running this command and later edit the ~/.hal/config file 
# by adding the space
hal deploy apply
```

Here's the problem with using just the `--user-dn-pattern`. As the documentation says, it is somewhat simplistic. In order to search a broader base of users who may exist in separate `OU` under the root, using `--user-search-filter` and `--user-search-base` is the way to go. Two quick caveats:

1. When you use `--user-search-filter` and `--user-search-base`, you will get an error while trying to login saying "This LDAP operation needs to be run with proper binding". If you try to add `managerDn:` and `managerPassword:` like you do in Fiat, `hal` throws an error.
2. When you add `userSearchFilter:` values, do not add an extra single quotes around `'{0}'`. So, this is WRONG: `userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN='{0}', OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN='{0}', OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))`. It is subtle, but it can cause a lot of headache. The right way to is to remove the single quotes around the `{0}` entry

So, to get around the `hal` constraints, you create `gate-local.yml` file with content like this:

```bash
ldap:
  enabled: true
  url: ldap://ds.cisco.com:3268
  managerDn: dft-ds.gen@cisco.com
  managerPassword: <password>
  userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
  userSearchBase: OU=Cisco Users,DC=cisco, DC=com
```

## Advanced Nerd Knobs: Configure LDAP Groups for Authorizations

Helpful command: `hal config security authz ldap edit --help`

```bash
hal config security authz ldap edit \
    --url ldap://ds.cisco.com:3268/dc=cisco,dc=com \
    --manager-dn 'dft-ds.gen@cisco.com' \
    --manager-password \
    --user-dn-pattern cn={0},ou=CiscoUsers \
    --group-search-base OU=Standard,OU=CiscoGroups,dc=cisco,dc=com \
    --group-search-filter "(member{0})" \
    --group-role-attributes cn
```

Once the command is run, open up ~/.hal/config file, edit `CiscoUsers` to `Cisco Users` and `CiscoGroups` to `Cisco Groups`. Why not add it in the command? Because hal command did not like the spaces. This might change later. Also, add the following additional LDAP criterias:

```bash
userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
userSearchBase: dc=cisco,dc=com
```

**Update:**

I finally was able to make things work without resorting to `userSearchFilter`. Here's what the end state looked like:

```bash
url: ldap://ds.cisco.com:3268/DC=cisco,DC=com
managerDn: dft-ds.gen@cisco.com
managerPassword: <password>
groupSearchBase: OU=Standard,OU=Cisco Groups
groupSearchFilter: (member={0})
groupRoleAttributes: cn
userDnPattern: cn={0},OU=Employees,OU=Cisco Users
```

However, in order to support users from multiple `OUs`, a better approach is to use `userSearchFilter:` and `userSearchBase:`. For that, I created `fiat-local.yml` and added the following:

```bash
auth:
  groupMembership:
    service: LDAP
    ldap:
      roleProviderType: LDAP
      url: ldap://ds.cisco.com:3268
      managerDn: dft-ds.gen@cisco.com
      managerPassword: <password>
      groupSearchBase: OU=Standard,OU=Cisco Groups,dc=cisco,dc=com
      groupSearchFilter: (member={0})
      groupRoleAttributes: cn
      userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
      userSearchBase: OU=Cisco Users,DC=cisco, DC=com
  enabled: true
```

**Note:**
I cannot make ldaps work in a Kubernetes environment. Keeps giving me LDAPS (LDAP over TLS) connection failed. [Reference 1](https://community.spinnaker.io/t/ldap-authentication-ldaps-protocol/386), [Reference 2](https://langui.sh/2009/03/14/checking-a-remote-certificate-chain-with-openssl/)

## Advanced Nerd Knobs: Configure External Redis

Using a single Redis instance will not scale in the end. Eventually, you are better off having the Microservices use their own Redis instance. The following Microservices have dependency on Redis:

- Gate
- Fiat
- Orca
- Clouddriver
  + Clouddriver RW
  + Clouddriver Caching
  + Clouddriver RO
- Igor
- Rosca
- Kayenta

In order to make each of these use its own dedicated Redis instance, make the following changes.

1. Add `~/.hal/default/service-settings/redis.yml`:

```bash
skipLifeCycleManagement: true
```

2. Create, if one does not exist, the following files in `~/.hal/default/profiles/`:
- fiat-local.yml
- gate-local.yml
- igor-local.yml
- kayenta-local.yml
- orca-local.yml
- rosco-local.yml

In each of the file, add a line like the following:

```bash
services.redis.baseUrl: redis://:<redis-password>@64.102.181.16:6383
```

Yes, the `userid` portion is blank, because as of Redis 4.x, there is no concept of users in Redis.


Observations:

Redis entries that we saw soon after starting up the Spinnaker instance:

- Clouddriver: 1527 entries (for 2 Accounts, 2 Registries)
- Gate: 6 keys (but only after I logged in at least once)
- Fiat: 104 Keys
- Orca: None (I have not created a single pipeline or triggered it)
- Igor: 758 Keys (All related to Docker Registries and My Jenkins configuration)
- Rosco: None (I have not created a pipeline which needed baking an image)
- Kayenta: None

It is easier to run `hal deploy clean` and start afresh

Finally, I noticed the following during startup:

- Fiat does not startup until Clouddriver is done doing validations...
- Igor does not startup until Clouddriver is up....

## Advanced Nerd Knobs: Clouddriver HA

Run the following commands to enable Clouddriver HA:

```bash
hal config deploy ha clouddriver enable
hal config deploy ha clouddriver edit --redis-master-endpoint 'redis://:<redis-password>@64.102.181.16:6382' --redis-slave-endpoint 'redis://:<redis-password>@64.102.180.241:16382'
```

Followed by, `hal deploy apply`

## Advanced Nerd Knobs: Echo HA

Run the following commands to enable Echo HA:

```bash
hal config deploy ha echo enable
```

Followed by, `hal deploy apply`

## Advanced Nerd Knobs: Custom Sizing

Manually edit `~/.hal/config` file and make the necessary edits

```bash
customSizing:
   spin-rosca:
     replicas: 1
   spin-echo-scheduler:
     replicas: 1
   spin-clouddriver-caching:
     replicas: 1
   spin-echo-worker:
     replicas: 1
   spin-clouddriver-ro:
     replicas: 1
   spin-deck:
     replicas: 1
   spin-gate:
     replicas: 1
   spin-igor:
     replicas: 1
   spin-fiat:
     replicas: 1
   spin-orca:
     replicas: 1
   spin-clouddriver-rw:
     replicas: 1
   spin-kayenta:
     replicas: 1
```

Followed by, `hal deploy apply`


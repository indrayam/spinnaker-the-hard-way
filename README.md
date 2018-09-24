# Spinnaker Install Notes on Kubernetes

As the documentation states:

  Spinnaker is an open-source, multi-cloud continuous delivery platform that helps you release software changes with high velocity and confidence. Spinnaker provides two core sets of features:

- Application Management
- Application deployment

Ok, so what does it all mean?

Well, when you think of the infrastructure that goes into running a Cloud Native Application consisting of a few or many Microservices in a Public (or Private) Cloud, you are looking at some (or all) of the following:

- DNS Service
- Load Balancers (with Certificates)
- Compute (VM Instances or Pods)
- Firewall Rules
- Cloud Account(s) and Permissions
- Databases
- ...

If you had a handful of Applications (with Microservices) to manage in a single cloud, managing it wouldn't be terribly hard. However, in reality, Organizations tend to have myriad of Applications instantiated across various lifecycles and more than a few Clouds! When you log into the Cloud provider's Console, you have no easy way to zero-in on your App resources! Spinnaker is as much about Application "Management" as it is about Application "Deployment"

### Spinnaker Microservices

![Spinnaker Microservices](https://s3.amazonaws.com/us-east-1-anand-files/spinnaker-architecture.jpg)

**[Deck](https://github.com/spinnaker/deck)**

  Browser-based UI

**[Gate](https://github.com/spinnaker/gate)**

  API Gateway: All API callers, including the UI, communicate with Spinnaker through Gate

**[Echo](https://github.com/spinnaker/echo)**

  Eventing Bus used for sending Notifications (like Emails, Slack, HipChat)

**[Orca](https://github.com/spinnaker/orca)**

  Orchestration Engine that handles all ad-hoc operations and Pipelines

**[Fiat](https://github.com/spinnaker/fiat)**

  Spinnaker's Authorization Service. It is used to query a user’s access permissions for accounts, applications and service accounts.

**[Clouddriver](https://github.com/spinnaker/clouddriver)**

  The arms of the Octopus (read, Spinnaker) that reaches out to the Clouds and mutates the infrastructure. It also indexes and caches all deployed resources

**[Igor](https://github.com/spinnaker/igor)**

  Integrates with build systems like Jenkins or TravisCI. Used to trigger pipelines via CI jobs. Also allows Jenkins/TravisCI stages to be used in Pipelines

**[Front50](https://github.com/spinnaker/front50)**

  Data Persistence Layer. Basically, persists Spinnaker data to the backend store

**[Kayenta](https://github.com/spinnaker/kayenta)**

  Canary Analysis Engine

**[Halyard](https://github.com/spinnaker/halyard)**

  Spinnaker's Configuration Service. It manages the lifecycle of each of the above services and only interacts with these services during Spinnaker startup, updates, and rollbacks.


### Spinnaker Nomenclature

**Project:**

  A Spinnaker Project is a collection of Spinnaker Applications. It's a view that pulls information about multiple Spinnaker Apps into a single pane

**Application:**

  Think of a Cloud Native Application as described above: A collection of Load Balancers, Compute Instance(s), Firewall Rules etc. No surprise to see that a Spinnaker Application is a collection of Clusters, which in turn is a collection of Server Groups (or Deployments). And yes, a Spinnaker Application also includes firewalls and load balancers! So, a Spinnaker Application truly represents the "Cloud Native App (or Service)" that a team is going to deploy using Spinnaker, all configuration for that App, and all the infrastructure on which it will run.

  Chances are, you will typically create a Spinnaker App per Cloud Native App you build

**Clusters (think, Deployment in Kubernetes):**

  Cluster is a collection of Server Groups (see below). Do not confuse Cluster here with Kubernetes Cluster! When deployed, a Server Group is a collection of instances of the running software (VM instances, Kubernetes Pods)

**Server Groups (think, ReplicaSet in Kubernetes):**

  The base resource, Server Group, identifies the deployable artifact and basic configuration settings such as number of instances, autoscaling policies, metadata etc. This resource is optionally associated with a Load Balancer and Firewall rules. 

**Instances (think, Pods in Kubernetes):**

  Server Group is a collection of the "atomic" entity within which a software is instantiated. Think individual virtual machine or a Kubernetes Pod. Hence, it should come as no surprise that we track Instance Count and Instance Types.

**Load Balancers:**

  Think of it as the entry doorway into your Cloud Native App. It is associated with ingress protocol, port ranges and often certificates. It balances traffic among instances in Server Groups. 

**Firewalls:**

  It defines network traffic access. Essentially a set of rules defined by IP Range (CIDR), protocol and port range

**Pipeline:**

  Pipeline is the App Deployment Management construct! It consists of a sequence of actions, known as Stages. You can pass parameters from Stage to Stage along the Pipeline. The Pipeline can be started manually or it can be triggered automatically by an external event, such as completion of a Jenkins Job or completion of a Container Image push to an Image Registry. It can also be triggered by another Stage in a different Pipeline!

**Stage:**

  A Stage in Spinnaker is an atomic building block for a pipeline, describing an action that the pipeline will perform. These stages can be sequenced in any order, though some stage sequences may be more common than others. Canned Stages are provided by Spinnaker to make it super simply to put together a Pipeline. For example:
  - Bake: Container or VM
  - Find Image
  - Deploy: Several Different Strategies
  - Wait
  - Disable/Enable
  - Resize
  - Manual Judgement
  - Check Preconditions

**Account:**

  In Spinnaker, an Account is a named credential Spinnaker uses to authenticate against a Cloud "Provider" (think, AWS, GCP, Azure, Kubernetes etc). Each provider has slightly different requirements for what format credentials can be in, and what permissions they need to be afforded to them. You can have as many accounts added as desired - this will allow you to keep your lifecycle environments (staging vs. production) separate, as well restrict access to sets of resources using Spinnaker's Authorization mechanisms. When working in the context of Kubernetes, an Account directly relates to a Cluster as defined by the `$HOME/.kube/config` file. Clouddriver component of Spinnaker reads `$HOME/.kube/config` file and adds each "Cluster" entry as an Account in Spinnaker

**Region:**

  Public Cloud Providers (like Amazon or Google) are hosted in multiple locations. These locations are composed of Regions and Availability Zones. Each Region is a separate geographic area and is completely independent. This achieves the greatest possible fault tolerance and stability. For Kubernetes, Region maps to Namespaces. Regions are more applicable when working with federated Kubernetes Clusters as you likely have nodes running in more than just one Region.

**Availability Zones:**

  Each Region has multiple, isolated locations known as Availability Zones. Each Availability Zone is isolated, but the Availability Zones in a Region are connected through low-latency links. It is not a bad idea to think of an Availability Zone as a separate Data Center, although it is not always the case.

**Stack:**

  It should come as no surprise that various aspects of Spinnaker reflects the culture at Netflix and how they do Continuous Delivery. One aspect of that is how they name Cloud Resources. The naming pattern is `application_name-stack_name-detail-version` where Stack refers to the Application lifecycle or environment of the App resources. Like, "staging" or "production"

**Detail:**

  Detail refers to things like "canary-staging" or "blue-version" or anything really that you want to add to further clarify and identify the cloud resource

**Status:**

  Is an Instance healthy, unhealthy, disabled etc.


### Pre-requisites
- Installed a 1 Master, 5 Node (Ubuntu 16.04) Kubernetes Cluster running the latest 1.11.2 version
- Create a standalone VM (Ubuntu 16.04) to use for two purposes: Running Halyard and Running TCP Proxy for my Kubernetes Cluster. So when I refer to VM running Nginx or TCP Proxy or Halyard, I am talking about this 6th Node

## [Run on VM running Nginx L4 TCP Proxy] 

### Get Nginx updated
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

### Update /etc/nginx/nginx.conf with these changes to the http block...

```bash
    #include /etc/nginx/conf.d/*.conf;
    #include /etc/nginx/sites-enabled/*;
}

include /etc/nginx/tcppassthrough.conf;
```

### TCP LB  and SSL passthrough for backend ##

```bash

# This is what /etc/nginx/tcppassthrough.conf looks like
stream {
    log_format combined '$remote_addr - - [$time_local] $protocol $status $bytes_sent $bytes_received $session_time "$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 64.102.179.84:31913 max_fails=3 fail_timeout=10s;
        server 64.102.178.218:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.202:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.80:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.228:31913 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 64.102.179.84:31913 max_fails=3 fail_timeout=10s;
        server 64.102.178.218:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.202:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.80:31913 max_fails=3 fail_timeout=10s;
        server 64.102.179.228:31913 max_fails=3 fail_timeout=10s;
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

## [Run on VM that will be the NFS Server]

### Setup NFS Server


```bash
sudo apt-get install -y nfs-kernel-server
sudo mkdir /var/nfs/minio -p
sudo chown nobody:nogroup /var/nfs/minio

sudo vim /etc/exports

/var/nfs/minio  64.102.178.0/23(rw,sync,no_subtree_check) 64.102.186.0/23(rw,sync,no_subtree_check)
sudo systemctl restart nfs-kernel-server
```

## [Run on all Kubernetes Nodes]

### Setup NFS Client

```bash
sudo apt-get install nfs-common
{
    sudo mkdir -p /nfs/minio
    sudo mount 64.102.179.211:/var/nfs/minio /nfs/minio
    df -h
}
```

```bash
sudo vim /etc/fstab
64.102.179.211:/var/nfs/minio /nfs/minio nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
sudo umount /nfs/minio (if you need to)
```

## [Run on Halyard VM]

### Install kubectl

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

### Install gcloud

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

### Fix K8s prompts

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

Make sure .kube/config contains information about the Kubernetes cluster you would be installing stuff into

## [Run on Halyard VM]

```bash
{
cd ~/src
tar -xvzf hal.tar.gz (get it from Dropbox)
sudo bash InstallHalyard.sh
dpkg -l | grep -i openjdk
sudo ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/local/java (assuming you are using openjdk)
}
```

### Create Spinnaker Kubernetes v2 Cloud Provider: Setup Kubernetes Cluster

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

### Add Kubernetes Account

```bash
{
hal config provider kubernetes account add cae-np-alln-hcn \
    --provider-version v2 \
    --context cae-np-alln-hcn

hal config provider kubernetes account add cae-prd-rcdn-hcn \
    --provider-version v2 \
    --context cae-np-alln-hcn

hal config provider kubernetes account add cae-np-rtp-udeploy \
    --provider-version v2 \
    --context cae-np-rtp-udeploy   
}
hal config features edit --artifacts true
```

### Choose Environment

```bash
hal config deploy edit --type distributed --account-name spinnaker-code
```

### Persistent Storage

```bash
cd ~/src
vim ./minio-standalone-pv.yml (Set the IP address of the NFS server)
k apply -f ./minio-standalone-pv.yml
k apply -f ./minio-standalone-pvc.yml
k apply -f ./minio-standalone-deployment.yml
vim ./minio-standalone-service.yml (Set the Service Type to Cluster IP)
k apply -f ./minio-standalone-service.yml
{
MINIO_ACCESS_KEY="NQGLI04VLERHGQI8X7SW"
MINIO_SECRET_KEY="4hIXeYg5I0WS15tOdCG7PAHVq4YiaHGJp2w3QwCC"
ENDPOINT="http://minio-service:9000"
echo $MINIO_SECRET_KEY | hal config storage s3 edit --endpoint $ENDPOINT \
    --access-key-id $MINIO_ACCESS_KEY \
    --secret-access-key
}
hal config storage edit --type s3
```

### Deploy Spinnaker

```bash
VERSION="1.9.0"
hal config version edit --version $VERSION
hal deploy apply
cd ~/.hal/default/profiles
vim front50-local.yml (add: spinnaker.s3.versioning: false)
hal deploy apply
```

### Install Ingress Controller, cert-manager

```bash
k apply -f contour-deployment-rbac.yml
k -n heptio-contour get svc
```

### Cert Manager (Self-signed)

```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -subj "/CN=Cisco CoDE Team" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
k create secret tls ca-key-pair --cert=ca.crt --key=ca.key --namespace=cert-manager
k apply -f ./ca-clusterissuer.yml
```

### Switch Namespace to Spinnaker

```bash
k apply -f ./spinnaker-code-ingress-https.yml -n spinnaker
k apply -f ./spinnakerapi-code-ingress-https.yml -n spinnaker
```

### Cert Manager (LetsEncrypt)

```bash
k apply -f ./letsencrypt-staging.yml
k apply -f ./letsencrypt-prod.yml
```

### Update Ingress

```bash
k apply -f ./spinnaker-code-ingress-https.yml
k apply -f ./spinnakerapi-code-ingress-https.yml

hal config security ui edit \
    --override-base-url http://spinnaker-code.cisco.com

hal config security ui edit \
    --override-base-url https://spinnaker-code.cisco.com

hal config security api edit \
    --override-base-url http://spinnakerapi-code.cisco.com

hal config security api edit \
    --override-base-url https://spinnakerapi-code.cisco.com
```

### Enable Security

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

### Add Kubernetes Accounts

```bash
hal config provider kubernetes account add cae-np-rtp-hcn --provider-version v2 --context cae-np-rtp_hcn
hal config provider kubernetes account add cae-np-alln-hcn --provider-version v2 --context cae-np-alln_hcn
hal config provider kubernetes account add cae-prd-rcdn-hcn --provider-version v2 --context cae-prd-rcdn_hcn

hal config provider docker-registry account add ech-hcn --address containers.cisco.com \
    --repositories "codeplayground/hello-udeploy-cloud-native-web-app" \
    --username "anasharm"  \
    --password "<password>"
```

### Authentication UI

```html
<html><head><title>Login Page</title></head><body onload='document.f.username.focus();'>
<h3>Login with Username and Password</h3><form name='f' action='/login' method='POST'>
<table>
    <tr><td>User:</td><td><input type='text' name='username' value=''></td></tr>
    <tr><td>Password:</td><td><input type='password' name='password'/></td></tr>
    <tr><td colspan='2'><input name="submit" type="submit" value="Login"/></td></tr>
</table>
</form></body></html>
```

### Add Jenkins Support

```bash
{
hal config ci jenkins enable

PASSWORD='<password>'
echo $PASSWORD | hal config ci jenkins master add my-jenkins-master \
    --address https://ci6.cisco.com \
    --username jenkins-ci.gen \
    --password
}
```

### Change the timezone

```bash
hal config edit --timezone 'America/New_York'
```

Not sure if this worked though. Not at the UI level

### HTTP Artifact Support

```bash
{
USERNAME='automation'
PASSWORD='<password>'
USERNAME_PASSWORD_FILE='/home/ubuntu/.bitbucket-user'
echo ${USERNAME}:${PASSWORD} > $USERNAME_PASSWORD_FILE
GITSCM_HTTP_ARTIFACT_ACCOUNT_NAME=automation-gitscm
hal config features edit --artifacts true
hal config artifact http enable
hal config artifact http account add ${GITSCM_HTTP_ARTIFACT_ACCOUNT_NAME} \
    --username-password-file $USERNAME_PASSWORD_FILE
}
```

### GitHub Artifact Support

```bash
{
TOKEN='<password>'
TOKEN_FILE='/home/ubuntu/.github-token'
echo $TOKEN > $TOKEN_FILE
GITHUB_ARTIFACT_ACCOUNT_NAME=indrayam-github
hal config features edit --artifacts true
hal config artifact github enable
hal config artifact github account add $GITHUB_ARTIFACT_ACCOUNT_NAME \
    --token-file $TOKEN_FILE
}
```

### GCS Artifact Support

```bash
{
    SERVICE_ACCOUNT_NAME='spinnaker-gce-account'
    SERVICE_ACCOUNT_DEST='/home/ubuntu/.config/gcloud/evident-wind-163400-spinnaker.json'
    
    #gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name $SERVICE_ACCOUNT_NAME
    
    SA_EMAIL=$(gcloud iam service-accounts list \
        --filter="displayName:$SERVICE_ACCOUNT_NAME" \
        --format='value(email)')
    
    PROJECT=$(gcloud info --format='value(config.project)')

    gcloud projects add-iam-policy-binding $PROJECT \
        --role roles/storage.admin --member serviceAccount:$SA_EMAIL

    #mkdir -p $(dirname $SERVICE_ACCOUNT_DEST)

    #gcloud iam service-accounts keys create $SERVICE_ACCOUNT_DEST --iam-account $SA_EMAIL
    ARTIFACT_ACCOUNT_NAME=evident-wind-gcs
    hal config features edit --artifacts true
    hal config artifact gcs account add $ARTIFACT_ACCOUNT_NAME \
        --json-path $SERVICE_ACCOUNT_DEST
}
```

### Email Notification Support

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

### Spinnaker Authorization

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

### Spinnaker RBAC Model

![Spinnaker Fiat Service](https://s3.amazonaws.com/us-east-1-anand-files/fiat-visual-version-2.png)

Spinnaker's Fiat offers Authorization functionality.

There are three resources in Spinnaker that can be given permissions:

- Spinnaker Accounts
- Spinnaker Applications
- Spinnaker Pipelines

A single Spinnaker Account can contain multiple applications. Similarly, a single Spinnaker Application can involve multiple Spinnaker Accounts. Put simple, they have a M:N relationship with each other. Also, one Spinnaker Application can contain one or many Pipelines. However, one Pipeline can only belong to a single Spinnaker Application.

**Spinnaker Accounts:**

There are two types of access restrictions to a Spinnaker Account, `READ` and `WRITE`. Users that log into Spinnaker must belong to groups (LDAP or otherwise) that is assigned one `READ` permission to the account to view the cloud resources tied to the account. If they would like to make changes to these cloud resources, then the user must belong to a group that has been assigned `WRITE` permission to the Spinnaker account

Bottom line...

Giving an LDAP group WRITE privileges to a Spinnaker account essentially means that users belonging to that group can deploy code to that account. You want to be very careful about giving this privilege

**Spinnaker Applications**

Application permissions are pretty straightforward. If a logged in user belongs to group(s) that have been given READ permissions, they will be able to see the Spinnaker Application under "Applications" in Deck UI, but will not be able to modify the Application attributes. Not surprisingly, if the logged in user belongs to group(s) that have WRITE permissions, they will be able to modify the Application attributes.

Note, having Application-level `WRITE` permission does not mean they can "deploy" code to the Spinnaker account(s). It also does not mean they can modify the pipelines associated with the Application. 

Bottom line...

Giving an LDAP group WRITE privileges to a Spinnaker Application essentially means that users belonging to that group can modify "all" Application attributes, including permissions. However, 
- These users cannot magically escalate their permissions and gain the ability to deploy or edit Application resources assuming they do not have WRITE privileges to the Spinnaker Account(s) configured as part of the Spinnaker Application
- These users cannot modify existing Pipelines tied to the Spinnaker Application either, if the logged in user does not have access to the Service Account tied to the existing Pipelines. Of course, they can always create new Pipelines in the Application

It’s important to understand what may happen if you leave either an account or application without any configured permissions.

- If an account is unrestricted, any user with access to Spinnaker can deploy a new application to that account.
- If an application is unrestricted, any user with access to Spinnaker can deploy that application into a different account (_Note: Need to understand and verify_). They may also be able to see basic information like instance names and counts within server groups.


**Spinnaker Pipelines**

When pipelines run against accounts and applications that are protected, it is necessary to configure them with enough permissions to access those protected resources. Fiat Service Accounts enable the ability for automatically triggered pipelines to modify resources in protected accounts or applications. 

Service accounts are persistent and configuration merely consists of giving it a name and a set of roles. **Caution:** While it seems like you can create arbitrarily named FIAT Service Accounts that have nothing to do with LDAP, you will eventually get errors when you run the sync command (500) and authorize commands (404), and it does impact the overall functionality around the `Run As User` behavior despite the fact that the dropdown does show the entries.

The Roles (translation: the LDAP groups that this Service Account is a member of) given to a Service Account determines who has access to use it. In order to prevent a privilege escalation vulnerability, only users with _every_ role the service account has may use it. Translation: Only users who have all of the specified roles assigned to the Service Account can edit or execute (_Note: Need to understand and verify_) the pipeline!!

For example, if a logged in user `sujmuthu` has roles `code-sujmuthu`, `dftcd-apps-developer` and `dftcd-apps-admin` and service account `dft-ds.gen` has role `code-sujmuthu`, then the logged in user `sujmuthu` has access to assign `dft-ds.gen` as the `Run As User` service account to any Pipeline that she has write privileges to. However, she can only modify the pipeline if `sujmuthu` has access to the service account `dft-ds.gen` (she does) as well as the service account `dft-ds.gen` has write access to the Spinnaker Application to which this Pipeline belongs. Since `dft-ds.gen` only has role `code-sujmuthu`, it means the Spinnaker Application must give write permissions to the group `code-sujmuthu` in order for Sujatha to modify the Pipeline.

Now, imagine if the service account logged in user `sujmuthu` has roles `code-sujmuthu`, `dftcd-apps-developer` and `dftcd-apps-admin` and service account `cd-spinnaker.gen` has roles `code-sujmuthu` and `code-anasharm` (a role that `sujmuthu` does not belong to), then the user does not have access to the service account `cd-spinnaker.gen`. So, if `sujmuthu` has write access to a Spinnaker Application which has a Pipeline that will be "Run as" `cd-spinnaker.gen`, `sujmuthu` will not be able to make any changes to this Pipeline despite the fact that she has write access to the Spinnaker Application.

_BOTTOMLINE:_

Bottom line, let's say there is an application called _ABC_. You decide to create an App Management and App Deployment interface for this application using Spinnaker. When you create a Spinnaker Application for _ABC_, you should create two LDAP groups: a small and mighty group that consists of application admins (_AppAdmins_) and another group consisting of all the application developers (_AppDevs_). 

The Spinnaker Account tied to the Application's Production Infrastructure should be setup to give write privileges to group _AppAdmins_ ONLY. It should give read access to the group _AppDevs_. However, the Spinnaker Account tied to the Application's Non-Prod Infrastructure should be setup so that both _AppAdmins_ and _AppDevs_ can read/write to that infrastructure.

The Spinnaker Application tied to the Application _ABC_ should give read/write privileges to group _AppAdmins_ and only read privileges to group _AppDevs_. You really do not want _AppDevs_ to have the ability to muck around with the Application Attributes, like permissions. Or wily nily create new Pipelines. 

Two Service Accounts (`ABC Prod SA` and `ABC Non-Prod SA`) should be created to run the Pipelines in the Application _ABC_. All Pipelines that interact with the Production Infrastructure should be setup with the `ABC Prod SA` Service Account that is a member of the group _AppAdmins_ ONLY. All other Pipelines that interact with Non-Production Infrastructure should be setup with the `ABC Non-Prod SA` Service Account which should be member of the group _AppDevs_ ONLY. You do not want to add _AppAdmins_ membership as well for this Service Account, since that would mean that only the logged in users who belong to BOTH _AppAdmins_ and _AppDevs_ will be able to modify the Pipelines that are being run with the `ABC Non-Prod SA` Service Account. These would be the Pipelines that deploy to Non-Prod Infrastructure and _AppDevs_ should absolutely be able to do that. 

In Summary, Users belonging to _AppAdmins_ group:

- Can deploy the binaries of _ABC_ application, since they have write access to the Spinnaker Account and they have access to the Service Account (`ABC Prod SA` is a member of _AppAdmins_ group) tied to the Pipelines
- Can access and modify Application Attributes of the Spinnaker Application created for _ABC_ since they have read/write privileges to the Spinnaker Application
- Can create and modify all Pipelines created under this Application

Users belonging to _AppDev_ group:

- Can deploy the binaries of _ABC_ application to the Non-Production Infrastucture since they have write access to the Spinnaker account tied to the Non-Prod Infra
- Cannot deploy the binaries of _ABC_ application to the Production Infrastucture since they do not have write access to the Spinnaker Account tied to the Production Infrastructure
- Can access and read, but not modify, the Application Attributes of the Spinnaker Application created for _ABC_
- Can modify and run the Pipelines that are setup to run as `ABC Non-Prod SA` and deploys to Non-Production Infrastructure
- Cannot modify and successfully run the Pipelines that are setup to run as `ABC Prod SA` service account

Here's how to create it, since we cannot use `hal` to perform CRUD operations

```bash

# Make sure your current kubernetes context points to the cluster and namespace where Spinnaker runs
# You only need to run this if and only if Halyard is running outside of the Kubernetes cluster
kubectl run -i --rm --restart=Never debugpod --image=indrayam/debug-container:latest --command -- sleep 9999999
kubectl exec -it debugpod -- bash

# Make sure the service discovery works
nslookup spin-front50

# Create a sa.sh with the following content:
FRONT50=http://spin-front50.spinnaker:8080
FIAT=http://spin-fiat.spinnaker:7003
ORCA=http://spin-orca.spinnaker:8083
ROSCO=http://spin-rosco.spinnaker:8087
IGOR=http://spin-igor.spinnaker:8088
REDIS=redis://spin-redis.spinnaker:6379
ECHO=http://spin-echo.spinnaker:8089
CLOUDDRIVER=http://spin-clouddriver.spinnaker:7002
DECK=http://spin-deck.spinnaker:9000
GATE=http://spin-gate.spinnaker:8084

chmod +x sa.sh
source sa.sh

# Create or update Service Accounts using the following API call
curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "jenkins-admin.gen", "memberOf": ["dftcd-apps-admin", "dftcd-apps-developer"] }' \
  $FRONT50/serviceAccounts | jq .

curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "spinnaker-demo1.gen", "memberOf": ["code-anasharm"] }' \
  $FRONT50/serviceAccounts | jq .

curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "spinnaker-demo2.gen", "memberOf": ["code-anasharm", "code-sujmuthu"] }' \
  $FRONT50/serviceAccounts | jq .

# See the Service Account(s)
curl -s $FRONT50/serviceAccounts | jq .

# A Fiat sync may be necessary for all affected users to pick up the changes:
curl -X POST $FIAT/roles/sync

# Confirm the new service account has permissions to the resources you think it should by querying Fiat
curl -s $FIAT/authorize/spinnaker-demo1.gen | jq .

# If you made a mistake, and you want to delete it, run the following command
curl -X DELETE -H "Content-type: application/json"  http://spin-front50:8080/serviceAccounts/<sa-name>

```








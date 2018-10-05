# Spinnaker Local Installation

I created this document after following the document titled ["Getting Set Up for Spinnaker Development"](https://www.spinnaker.io/guides/developer/getting-set-up/). Without this document, and help from Spinnaker Core member(s), let's just say none of this would be possible

## My laptop Details

- Installed on my Mac running macOS Sierra (10.12.6)
- MacBook Pro (15" 2016); 16 GB RAM; 2.6 GHz Intel Core i7

## Assumptions

- You have a GitHub account
- You have configured your laptop to access repos in GitHub over SSH. References: [1](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/) and [2](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)
- You have `gcloud` installed and available on your `$PATH`. Also, make sure it is configured to interact with your GCP account. Here's a quick 3 step installation process on a Mac:

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

I used Google Cloud SDK version `219.0.1` and `gsutil` version `4.34`

## Core Tools

- **git**
> `brew install git` (Version running on my laptop: 2.19.0)
- **curl**
> `brew install curl; 7.61.1` (Version running on my laptop: 7.61.1)
- **netcat**
> `brew install netcat; 0.7.1` (Version running on my laptop: 0.7.1)
- **redis-server**
> `brew install redis; brew services start redis` (Version running on my laptop: 4.0.11)
- **java**
> Downloaded directly from Oracle (Version running on my laptop: 1.8.0_31)
- **node**
> curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
  # Follow instructions at end of script to add nvm to ~/.bash_rc
  
  nvm install v8.9.0
- **yarn**
> `npm install -g yarn` (Version running on my laptop: 1.9.4)

Make sure all the pieces are installed by running the following:

```bash
{
git --version
curl --version
netcat -V
/usr/local/Cellar/redis/4.0.11/bin/redis-server -v
java -version
node -v
yarn -v
}
```

## Install Halyard

```bash
cd ~/
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/macos/InstallHalyard.sh
sudo bash InstallHalyard.sh
rm InstallHalyard.sh
```

## Set up Storage Service

If you have used GCS already as the Storage provider, you may want to clean up before setting up your new local setup:

```bash
gsutil ls gs:// | grep -i spin
gsutil rm -r gs://<spin-bucket-name>
```

Time to make sure you are ready to interact with Google Cloud Storage. Here are the commands I ran to get things setup.

```bash
SERVICE_ACCOUNT_NAME='spinnaker-gce-account'
SERVICE_ACCOUNT_DEST='~/.config/gcloud/spinnaker-gce-account.json'
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name $SERVICE_ACCOUNT_NAME
SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:$SERVICE_ACCOUNT_NAME" --format='value(email)')
PROJECT=$(gcloud info --format='value(config.project)')
#gcloud projects get-iam-policy $PROJECT
gcloud projects add-iam-policy-binding $PROJECT --role roles/storage.admin --member serviceAccount:$SA_EMAIL
gcloud iam service-accounts keys create $SERVICE_ACCOUNT_DEST --iam-account $SA_EMAIL
BUCKET_LOCATION=us
hal config storage gcs edit --project $PROJECT --bucket-location $BUCKET_LOCATION --json-path $SERVICE_ACCOUNT_DEST
hal config storage edit --type gcs
```

## Set up Cloud Provider (Kubernetes)

```bash
export KUBECONFIG="/Users/anasharm/.kube/rtp-learn.yaml"
hal config provider kubernetes account add rtp-learn-admin --provider-version v2 --context $(kubectl config current-context) --kubeconfig-file "~/.kube/rtp-learn.yaml"
hal config provider kubernetes enable
hal config features edit --artifacts true
```

## Fork Spinnaker Microservices

Here are all the Spinnaker Microservices that are documented in [Spinnaker Reference Docs](https://www.spinnaker.io/reference/architecture/#spinnaker-microservices)

**OPTION 1:**

Open each of the links in a separate tab and fork the repo into your personal repo. **Make sure you have your SSH keys setup to access each of these Git repos**:

- [Deck](https://github.com/spinnaker/deck)
- [Gate](https://github.com/spinnaker/gate)
- [Orca](https://github.com/spinnaker/orca)
- [Clouddriver](https://github.com/spinnaker/clouddriver)
- [Front50](https://github.com/spinnaker/front50)
- [Rosco](https://github.com/spinnaker/rosco)
- [Igor](https://github.com/spinnaker/igor)
- [Echo](https://github.com/spinnaker/echo)
- [Fiat](https://github.com/spinnaker/fiat)
- [Kayenta](https://github.com/spinnaker/kayenta)
- [Halyard](https://github.com/spinnaker/halyard)


**OPTION 2:**

Run the [Setup Forks](spin-scripts/setup-forks.sh) script. However, the script assumes that you have the following on your latop:

- [Hub CLI](https://hub.github.com/)
- Configure `hub` CLI so that it knows your GitHub username and GitHub Personal Token

## Halyard Commands to Wrap Up

```bash
hal config deploy edit --type localgit --git-origin-user=indrayam
hal config version edit --version branch:upstream/master
# Run the following commands to enable Fiat Authn and Enable LDAP as the Authn medium
hal config security authn ldap enable
hal config security authn ldap edit --user-dn-pattern="cn={0},OU=Employees,OU=CiscoUsers" --url=ldap://ds.cisco.com:3268/DC=cisco,DC=com
# If the LDAP settings need to be updated, update the ~/.spinnaker/fiat-local.yml file

# Run the following commands to enable Fiat Authz and use LDAP as Role Provider
hal config security authz enable
hal config security authz ldap edit \
    --url ldap://ds.cisco.com:3268/dc=cisco,dc=com \
    --manager-dn 'dft-ds.gen@cisco.com' \
    --manager-password \
    --user-dn-pattern cn={0},ou=CiscoUsers \
    --group-search-base OU=Standard,OU=CiscoGroups,dc=cisco,dc=com \
    --group-search-filter "(member{0})" \
    --group-role-attributes cn
# If this command fails, update the ~/.spinnaker/gate-local.yml file
hal deploy apply
```

## Handle Microservices

First things first:

- Run [Stop All Microservices](spin-scripts/stop-all.sh)
- Once you have your laptop back (:wink:), run [Start Core Services](spin-scripts/start-core.sh). Your "core" set of services might be different from mine
- OPTIONAL: [Stop Core Services](spin-scripts/stop-core.sh)


## Setup IntelliJ

Repeat these steps for each Microservice!

```bash
cd ~/dev/spinnaker/<microservice>/
./gradlew idea
```

If something goes wrong, run the following to clean all IntelliJ related files/folders:

```bash
git clean -dnxf -e '*.iml' -e '*.ipr' -e '*.iws'
git clean -dxf -e '*.iml' -e '*.ipr' -e '*.iws'
```

## Useful Commands/Hacks

- `hal deploy apply --service-names deck, fiat, gate, clouddriver, orca, front50`

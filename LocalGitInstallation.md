# Spinnaker Local Installation

## My laptop Details

- Installed on my Mac running macOS Sierra (10.12.6)
- MacBook Pro (15" 2016); 16 GB RAM; 2.6 GHz Intel Core i7

## Assumptions

- You have a GitHub account
- You have configured your laptop to access repos in GitHub over SSH. References: [1](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/) and [2](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

## Install Halyard

```bash
cd ~/
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/macos/InstallHalyard.sh
sudo bash InstallHalyard.sh
rm InstallHalyard.sh
```

## Set up Storage Service

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

## Additional Tools

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
> Downloaded and installed it from [nodejs.org](https://nodejs.org/en/) (Version running on my laptop: 8.11.3)
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

## Fork Spinnaker Microservices

Here are all the Spinnaker Microservices that are documented in [Spinnaker Reference Docs](https://www.spinnaker.io/reference/architecture/#spinnaker-microservices)

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

- Run [Stop All Microservices](stop-all.sh)
- Once you have your laptop back (:wink:), run [Start Core Services](start-core.sh). Your "core" set of services might be different from mine
- OPTIONAL: [Stop Core Services](stop-core.sh)


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

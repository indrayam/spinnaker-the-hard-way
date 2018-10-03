# Spinnaker Local Installation

## My laptop Details

- Installed on my Mac running macOS Sierra (10.12.6)
- MacBook Pro (15" 2016); 16 GB RAM; 2.6 GHz Intel Core i7

## Assumptions

- You have a GitHub account
- You have configured your laptop to access repos in GitHub over SSH. References: [1](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/) and [2](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

## Install Halyard

```bash
mkdir ~/spinnaker-dev
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




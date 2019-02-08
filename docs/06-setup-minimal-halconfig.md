# Setup Minimal Hal Configuration

With `hal` installed, it's time to start building up `~/.hal/config` file. Why? Because `~/.hal/config` file is how `hal` deploys and configures Spinnaker (on Kubernetes). 

How do we build up `~/.hal/config` file?

We run `hal` commands to build `~/.hal/config` file. If you are interested in reviewing all `hal` commands, checkout the [Halyard Commands](https://www.spinnaker.io/reference/halyard/commands/) documentation

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

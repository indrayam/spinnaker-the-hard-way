#!/bin/bash

# Setup the base folder
SPINNAKER_FORK="/tmp/spinnaker"
echo "Cleanup any existing $SPINNAKER_FORK folder..."
rm -rf $SPINNAKER_FORK
mkdir -p $SPINNAKER_FORK
GITHUB_USER_ID="indrayam"
GITHUB_PERSONAL_TOKEN="${1}"
if [ -z "$GITHUB_PERSONAL_TOKEN" ]
then
      echo "You forgot to pass a personal GitHub access token :-("
      echo "Why does the script need it? For deleting your existing \"forked\" Spinnaker repos from your GitHub account"
      echo
      echo "Usage: setup-forks.sh <github-token>"
      exit 1
fi


for ms in deck gate fiat clouddriver orca kayenta front50 rosco igor echo halyard; do
    echo "Deleting $ms"
    curl -XDELETE -H "Authorization: token $GITHUB_PERSONAL_TOKEN" "https://api.github.com/repos/${GITHUB_USER_ID}/$ms"
    echo "Cloning spinnaker/$ms..."
    cd $SPINNAKER_FORK
    rm -rf $ms
    hub clone spinnaker/$ms
    cd $ms
    hub fork --remote-name=origin
    hub remote -v
done

echo
echo "Cleanup the cloned folders since hal will clone and set them up"
rm -rf $SPINNAKER_FORK

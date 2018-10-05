#!/bin/bash

# Setup the base folder
SPINNAKER_DEV="$HOME/dev/spinnaker"
mkdir -p $SPINNAKER_DEV
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
    echo "Deleting $r"
    curl -XDELETE -H "Authorization: token $GITHUB_PERSONAL_TOKEN" "https://api.github.com/repos/${GITHUB_USER_ID}/$r"
    echo "Cloning spinnaker/$ms..."
    cd $SPINNAKER_DEV
    rm -rf $ms
    hub clone spinnaker/$ms
    cd $ms
    hub fork --remote-name=origin
    hub remote -v
done

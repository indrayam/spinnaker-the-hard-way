#!/bin/bash

# Setup the base folder
SPINNAKER_DEV="$HOME/dev/spinnaker"
mkdir -p $SPINNAKER_DEV
# If you want your existing GitHub repos to be deleted
GITHUB_PERSONAL_TOKEN="<token>"
GITHUB_USER_ID="indrayam"

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

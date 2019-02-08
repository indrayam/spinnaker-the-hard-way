# Halyard

### Update Spinnaker Version

```bash
hal config version edit --version 1.9.5
```

### Hal shutdown

```bash
hal shutdown
```

### Hal Version

```bash
hal version latest
```

### Hal Deploy

```bash
hal deploy apply --service-names clouddriver front50 deck gate fiat orca
```

### Update Halyard

```bash
sudo update-halyard
```

### Hal using Docker
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

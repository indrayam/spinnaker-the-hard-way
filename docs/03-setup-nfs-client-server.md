# Setup NFS Client(s) and Server on ENTRY VM


## Install NFS Server

Run these commands on the ENTRY VM

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

## Install NFS Client 

Run these commands on all 9 Kubernetes Cluster Nodes

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

# Configure Persistent Storage (Minio)

## Create Minio Kubernetes files

- **minio-standalone-pv.yml:** Set the IP address of the NFS server

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minio-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    path: /var/nfs/minio
    server: 192.168.1.14
  persistentVolumeReclaimPolicy: Retain
```

- **minio-standalone-pvc.yml:**

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  # This name uniquely identifies the PVC. This is used in deployment.
  name: minio-pv-claim
spec:
  # Read more about access modes here: http://kubernetes.io/docs/user-guide/persistent-volumes/#access-modes
  accessModes:
    # The volume is mounted as read-write by a single node
    - ReadWriteOnce
  resources:
    # This is the request for storage. Should be available in the cluster.
    requests:
      storage: 10Gi
  storageClassName: ""
```

- `minio-standalone-deployment.yml:` Update values for *MINIO_ACCESS_KEY* and *MINIO_SECRET_KEY*

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  # This name uniquely identifies the Deployment
  name: minio-deployment
spec:
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        # Label is used as selector in the service.
        app: minio
    spec:
      # Refer to the PVC created earlier
      volumes:
      - name: storage
        persistentVolumeClaim:
          # Name of the PVC created earlier
          claimName: minio-pv-claim
      containers:
      - name: minio
        # Pulls the default Minio image from Docker Hub
        image: minio/minio
        args:
        - server
        - /storage
        env:
        # Minio access key and secret key
        - name: MINIO_ACCESS_KEY
          value: "..."
        - name: MINIO_SECRET_KEY
          value: "..."
        ports:
        - containerPort: 9000
        # Mount the volume into the pod
        volumeMounts:
        - name: storage # must match the volume name, above
          mountPath: "/storage"
```

- `minio-standalone-service.yml:` Set the Service Type to ClusterIP

```yaml
apiVersion: v1
kind: Service
metadata:
  # This name uniquely identifies the service
  name: minio-service
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
      protocol: TCP
  selector:
    # Looks for labels `app:minio` in the namespace and applies the spec
    app: minio
```

## Setup Minio

Once these files are created and saved in `~/src` folder, run the following commands:

```bash
cd ~/src
k apply -f ./minio-standalone-pv.yml
k apply -f ./minio-standalone-pvc.yml
k apply -f ./minio-standalone-deployment.yml
k apply -f ./minio-standalone-service.yml
```

Run the following `hal` command to configure persistent storage (minio):

```bash
{
MINIO_ACCESS_KEY="..."
MINIO_SECRET_KEY="..."
ENDPOINT="http://minio-service:9000"
echo $MINIO_SECRET_KEY | hal config storage s3 edit --endpoint $ENDPOINT \
    --access-key-id $MINIO_ACCESS_KEY \
    --secret-access-key
}
hal config storage edit --type s3
```

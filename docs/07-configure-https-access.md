# Configure External HTTPS access

**Why do we need this?**

To externally route Spinnaker URLs to `spin-deck` and `spin-gate` Services running within Kubernetes

**Could you elaborate some more, please?**

Accessing Spinnaker (or any web application) in Kubernetes needs an external "load balancer" to route requests into the cluster. Since we are setting this up ourselves, we need to do the following things to make web access possible:

- Setup Heptio Contour Ingress Controller and TCP Proxy on ENTRY VM
- Setup Jetstack Cert Manager (to allow Kubernetes to automatically provision self-signed Certs)
- Create Spinnaker Ingress Objects with appropriate annotations

## Install Heptio Contour Ingress Controller and TCP Proxy on ENTRY VM

Source(s):
- [heptio/contour](https://github.com/heptio/contour)
- [Tutorial: Deploy web applications on Kubernetes with Contour and Let's Encrypt](https://github.com/heptio/contour/blob/master/docs/cert-manager.md)

```bash
cd ~/src
curl -L -O https://j.hept.io/contour-deployment-rbac
mv contour-deployment-rbac contour-deployment-rbac.yaml
vim contour-deployment-rbac.yaml
# Change the last line (Service type) from LoadBalancer to NodePort
k apply -f contour-deployment-rbac.yml
k -n heptio-contour get svc
kn default
```

Use the output of the `k -n heptio-contour get svc` to figure out what NodePort is mapped to Port(s) **80** and **443**. For example, let's say the output looks like this:

```
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
contour   NodePort   10.101.167.20   <none>        80:31092/TCP,443:31391/TCP   3h58m
```

Since port 80 is mapped to 31092 and 443 is mapped to 31391, update `/etc/nginx/tcppassthrough.conf` file's port numbers so that the section `httpenvoy` uses 31092 and the section `httpsenvoy` uses 31391:

```bash

stream {

    log_format combined '$remote_addr - - [$time_local] $protocol $status $bytes_sent $bytes_received $session_time "$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 192.168.1.19:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:31092 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:31092 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 192.168.1.19:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:31391 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:31391 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 80;
        proxy_pass httpenvoy;
        proxy_next_upstream on;
    }

    server {
        listen 443;
        proxy_pass httpsenvoy;
        proxy_next_upstream on;
    }
}
```

**Install KUARD demo app**

```bash
cd ~/src
curl -L -O https://j.hept.io/contour-kuard-example
mv contour-kuard-example contour-kuard-example.yaml
kn default
k apply -f contour-kuard-example.yaml
```

If you have `wercker/stern` installed, run the following command. It should show messages reflecting the fact that Heptio Contour was able to react to the new Ingress Object created in Kubernetes:

`stern contour`

You can also tail the Nginx stream log on the ENTRY VM machine to see if the TCP Proxy received and forwarded the request appropriately:

```
tail -f /var/log/nginx/stream-access.log
```

You should see an output like:

```
173.37.95.214 - - [08/Feb/2019:14:47:21 +0000] TCP 200 0 0 0.004 "192.168.1.16:31092"
```

Assuming `kuard1-code.cisco.com` is the DNS entry that points to the ENTRY VM's TCP Proxy, open `kuard1-code.cisco.com` in the browser. You should see the KUARD app.  

## Install Jetstack Cert Manager (self-signed)

Source(s):
- [Installing cert-manager](https://docs.cert-manager.io/en/latest/getting-started/install.html)
- [Setting up CA Issuers](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-ca.html)
- [Automatically creating Certificates for Ingress resources](https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/ingress-shim.html)

Install Jetstack cert manager

```bash
k create namespace cert-manager
kn cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/cert-manager.yaml
```

```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -subj "/CN=Cisco CoDE Team" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
k create secret tls ca-key-pair --cert=ca.crt --key=ca.key --namespace=cert-manager
```

Create `ca-clusterissuer.yaml` file in `~/src`:

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: ca-key-pair
```

Run the following command to setup the ClusterIssuer in Kubernetes:

```
k apply -f ./ca-clusterissuer.yml
```

**Install Ingress Objects with Jetstack Annotations:**

Update the `contour-kuard-example.yaml` file's Ingress section (at the bottom of the file) with this content:

```yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  labels:
    app: kuard
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: kuard1-code
    hosts:
    - kuard1-code.cisco.com
  rules:
  - host: kuard1-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: kuard
          servicePort: 80
---
```

Apply the changes to Kubernetes:

```bash
kn default
k apply -f contour-kuard-example.yaml
k get secret
# A new secret is created called kuard1-code
```

**Getting your MacOS to trust the self-signed cert**

```bash
echo quit | openssl s_client -showcerts -servername kuard1-code.cisco.com -connect kuard1-code.cisco.com:443 > kuard1-code.pem
vim kuard1-code.pem
# Delete everything above and below the BEGIN CERTIFICATE and END CERTIFICATE section
```

- Open KeyChain Access on your MacOS
- Drag and drop `kuard1-code.pem` into `All Items` Category of KeyChain Access tool
- Click on `Certificates` category
- Double-click the certificate
- Expand "Trust" dropdown
- Select "Always Trust"
- Open https://kuard1-code.cisco.com in Incognito Window

## Create Spinnaker Ingress Objects with appropriate annotations

Create `spinnaker1-code-ingress-https.yml` in `~/src`. If you want to create an Ingress resource without cert-manager features, remove the `annotations` and `spec>tls` blocks:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spinnaker-deck
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: spinnaker-deck-tls
    hosts:
    - spinnaker1-code.cisco.com
  rules:
  - host: spinnaker1-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: spin-deck
          servicePort: 9000
```

Create `spinnaker1api-code-ingress-https.yml` in `~/src`. If you want to create an Ingress resource without cert-manager features, remove the `annotations` and `spec>tls` blocks:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spinnaker-gate
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "ca-issuer"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - secretName: spinnaker-gate-tls
    hosts:
    - spinnaker1api-code.cisco.com
  rules:
  - host: spinnaker1api-code.cisco.com
    http:
      paths:
      - backend:
          serviceName: spin-gate
          servicePort: 8084
```

```bash
kn spinnaker
k apply -f ./spinnaker1-code-ingress-https.yml -n spinnaker
k apply -f ./spinnaker1api-code-ingress-https.yml -n spinnaker
```

**Getting your MacOS to trust the self-signed cert**

```bash
echo quit | openssl s_client -showcerts -servername spinnaker1-code.cisco.com -connect spinnaker1-code.cisco.com:443 > spinnaker1-code.pem
vim spinnaker1-code.pem
# Delete everything above and below the BEGIN CERTIFICATE and END CERTIFICATE section
```

```bash
echo quit | openssl s_client -showcerts -servername spinnaker1api-code.cisco.com -connect spinnaker1api-code.cisco.com:443 > spinnaker1api-code.pem
vim spinnaker1api-code.pem
# Delete everything above and below the BEGIN CERTIFICATE and END CERTIFICATE section
```

- Open KeyChain Access on your MacOS
- Drag and drop `spinnaker1-code.pem` and `spinnaker1api-code.pem` into `All Items` Category of KeyChain Access tool
- Click on `Certificates` category
- Double-click the certificate
- Expand "Trust" dropdown
- Select "Always Trust"

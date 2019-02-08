# Setup TCP Proxy on ENTRY VM

This lab will help you configure Nginx powered TCP proxy that will front-end the Kubernetes Cluster. 

## Update Nginx

Update Nginx to the latest version offered by `nginx.org`

```bash
sudo vim /etc/nginx/tcppassthrough.conf (Update the Upstream Port numbers for 80 and 443)

sudo wget https://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
sudo vim /etc/apt/sources.list.d/nginx.list 
#Add the following lines to nginx.list:
#    deb https://nginx.org/packages/mainline/ubuntu/ <CODENAME> nginx
#    deb-src https://nginx.org/packages/mainline/ubuntu/ <CODENAME> nginx
```

```bash
sudo apt-get remove nginx #Remove existing Nginx install (if any)
sudo apt-get install nginx
```

## Update /etc/nginx/nginx.conf

```bash
{
    ...
    #include /etc/nginx/conf.d/*.conf;
    #include /etc/nginx/sites-enabled/*;
}

include /etc/nginx/tcppassthrough.conf;
```

## TCP LB and SSL passthrough

Update the `/etc/nginx/tcppassthrough.conf` file with the IP addresses of the 9 Kubernetes Worker Nodes. Do not worry about the two port number stes (31092 and 31391) shown below. This will need to get updated after Heptio Contour Ingress Controller is installed (see below)

```bash
## tcp LB  and SSL passthrough for backend ##
stream {

    log_format combined '$remote_addr - - [$time_local] $protocol $status $bytes_sent $bytes_received $session_time "$upstream_addr"';

    access_log /var/log/nginx/stream-access.log combined;

    upstream httpenvoy {
        server 192.168.1.19:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:11111 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:11111 max_fails=3 fail_timeout=10s;
    }

    upstream httpsenvoy {
        server 192.168.1.19:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.20:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.9:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.16:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.27:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.15:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.24:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.28:22222 max_fails=3 fail_timeout=10s;
        server 192.168.1.18:22222 max_fails=3 fail_timeout=10s;
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

```bash
sudo nginx -t
sudo systemctl stop nginx
sudo systemctl start nginx
```

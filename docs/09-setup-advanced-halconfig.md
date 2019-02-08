# Advanced Halyard Configuration

This section will document all the advanced Spinnaker nerd knobs that I have been able to understand and configure in my own Spinnaker setup.

## Configure Email Notification Support

1. Create echo-local.yml file as below:

```bash
mail:
  enabled: true
  from: noreply@cisco.com
spring:
  mail:
    host: outbound.cisco.com
    port: 25
    properties:
      mail:
        smtp:
          auth: false
          starttls:
            enable: true
        transport:
          protocol: smtp
        debug: true
```

2. Copy the file into ~/.hal/default/profiles/ folder
3. Run: `hal deploy apply --service-names echo`


## Configure LDAP Authentication

```bash
hal config security authn ldap enable
hal config security authn ldap edit --user-dn-pattern="cn={0},OU=Employees,OU=Cisco Users" --url=ldap://ds.cisco.com:3268/DC=cisco,DC=com
# Note, I had to remove the space betweeen Cisco and Users when running this command and later edit the ~/.hal/config file 
# by adding the space
hal deploy apply
```

Here's the problem with using just the `--user-dn-pattern`. As the documentation says, it is somewhat simplistic. In order to search a broader base of users who may exist in separate `OU` under the root, using `--user-search-filter` and `--user-search-base` is the way to go. Two quick caveats:

1. When you use `--user-search-filter` and `--user-search-base`, you will get an error while trying to login saying "This LDAP operation needs to be run with proper binding". If you try to add `managerDn:` and `managerPassword:` like you do in Fiat, `hal` throws an error.
2. When you add `userSearchFilter:` values, do not add an extra single quotes around `'{0}'`. So, this is WRONG: `userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN='{0}', OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN='{0}', OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))`. It is subtle, but it can cause a lot of headache. The right way to is to remove the single quotes around the `{0}` entry

So, to get around the `hal` constraints, you create `gate-local.yml` file with content like this:

```bash
ldap:
  enabled: true
  url: ldap://ds.cisco.com:3268
  managerDn: dft-ds.gen@cisco.com
  managerPassword: <password>
  userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
  userSearchBase: OU=Cisco Users,DC=cisco, DC=com
```

## Configure LDAP Groups for Authorizations

Helpful command: `hal config security authz ldap edit --help`

```bash
hal config security authz ldap edit \
    --url ldap://ds.cisco.com:3268/dc=cisco,dc=com \
    --manager-dn 'dft-ds.gen@cisco.com' \
    --manager-password \
    --user-dn-pattern cn={0},ou=CiscoUsers \
    --group-search-base OU=Standard,OU=CiscoGroups,dc=cisco,dc=com \
    --group-search-filter "(member{0})" \
    --group-role-attributes cn
hal config security authz edit --type ldap
hal config security authz enable
```

Once the command is run, open up ~/.hal/config file, edit `CiscoUsers` to `Cisco Users` and `CiscoGroups` to `Cisco Groups`. Why not add it in the command? Because hal command did not like the spaces. This might change later. Also, add the following additional LDAP criterias:

```bash
userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
userSearchBase: dc=cisco,dc=com
```

**Update:**

I finally was able to make things work without resorting to `userSearchFilter`. Here's what the end state looked like:

```bash
url: ldap://ds.cisco.com:3268/DC=cisco,DC=com
managerDn: dft-ds.gen@cisco.com
managerPassword: <password>
groupSearchBase: OU=Standard,OU=Cisco Groups
groupSearchFilter: (member={0})
groupRoleAttributes: cn
userDnPattern: cn={0},OU=Employees,OU=Cisco Users
```

However, in order to support users from multiple `OUs`, a better approach is to use `userSearchFilter:` and `userSearchBase:`. For that, I created `fiat-local.yml` and added the following:

```bash
auth:
  groupMembership:
    service: LDAP
    ldap:
      roleProviderType: LDAP
      url: ldap://ds.cisco.com:3268
      managerDn: dft-ds.gen@cisco.com
      managerPassword: <password>
      groupSearchBase: OU=Standard,OU=Cisco Groups,dc=cisco,dc=com
      groupSearchFilter: (member={0})
      groupRoleAttributes: cn
      userSearchFilter: (&(objectClass=user)(|(distinguishedName=CN={0}, OU=Generics, OU=Cisco Users, DC=cisco, DC=com)(distinguishedName=CN={0}, OU=Employees, OU=Cisco Users, DC=cisco, DC=com)))
      userSearchBase: OU=Cisco Users,DC=cisco, DC=com
  enabled: true
```

**Note:**
I cannot make ldaps work in a Kubernetes environment. Keeps giving me LDAPS (LDAP over TLS) connection failed. [Reference 1](https://community.spinnaker.io/t/ldap-authentication-ldaps-protocol/386), [Reference 2](https://langui.sh/2009/03/14/checking-a-remote-certificate-chain-with-openssl/)

## Configure External Redis

Using a single Redis instance will not scale in the end. Eventually, you are better off having the Microservices use their own Redis instance. The following Microservices have dependency on Redis:

- Gate
- Fiat
- Orca
- Clouddriver
  + Clouddriver RW
  + Clouddriver Caching
  + Clouddriver RO
- Igor
- Rosca
- Kayenta

In order to make each of these use its own dedicated Redis instance, make the following changes.

1. Add `~/.hal/default/service-settings/redis.yml`:

```bash
skipLifeCycleManagement: true
```

2. Create, if one does not exist, the following files in `~/.hal/default/profiles/`:
- fiat-local.yml
- gate-local.yml
- igor-local.yml
- kayenta-local.yml
- orca-local.yml
- rosco-local.yml

In each of the file, add a line like the following:

```bash
services.redis.baseUrl: redis://:<redis-password>@64.102.181.16:6383
```

Yes, the `userid` portion is blank, because as of Redis 4.x, there is no concept of users in Redis.


Observations:

Redis entries that we saw soon after starting up the Spinnaker instance:

- Clouddriver: 1527 entries (for 2 Accounts, 2 Registries)
- Gate: 6 keys (but only after I logged in at least once)
- Fiat: 104 Keys
- Orca: None (I have not created a single pipeline or triggered it)
- Igor: 758 Keys (All related to Docker Registries and My Jenkins configuration)
- Rosco: None (I have not created a pipeline which needed baking an image)
- Kayenta: None

It is easier to run `hal deploy clean` and start afresh

Finally, I noticed the following during startup:

- Fiat does not startup until Clouddriver is done doing validations...
- Igor does not startup until Clouddriver is up....

## Clouddriver HA

Run the following commands to enable Clouddriver HA:

```bash
hal config deploy ha clouddriver enable
hal config deploy ha clouddriver edit --redis-master-endpoint 'redis://:<redis-password>@64.102.181.16:6382' --redis-slave-endpoint 'redis://:<redis-password>@64.102.180.241:16382'
```

Followed by, `hal deploy apply`

## Echo HA

Run the following commands to enable Echo HA:

```bash
hal config deploy ha echo enable
```

Followed by, `hal deploy apply`

## Custom Sizing

Manually edit `~/.hal/config` file and make the necessary edits

```bash
customSizing:
   spin-rosca:
     replicas: 1
   spin-echo-scheduler:
     replicas: 1
   spin-clouddriver-caching:
     replicas: 1
   spin-echo-worker:
     replicas: 1
   spin-clouddriver-ro:
     replicas: 1
   spin-deck:
     replicas: 1
   spin-gate:
     replicas: 1
   spin-igor:
     replicas: 1
   spin-fiat:
     replicas: 1
   spin-orca:
     replicas: 1
   spin-clouddriver-rw:
     replicas: 1
   spin-kayenta:
     replicas: 1
```

Followed by, `hal deploy apply`


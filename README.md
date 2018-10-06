# Spinnaker The Hard Way

## Spinnaker Installation Steps

- [Spinnaker LocalGit Installation Steps](LocalGitInstallation.md)
- [Spinnaker Distributed Kubernetes Installation Steps](DistributedKuberntesInstallation.md)

## Spinnaker Concepts

As the documentation states:

  Spinnaker is an open-source, multi-cloud continuous delivery platform that helps you release software changes with high velocity and confidence. Spinnaker provides two core sets of features:

- Application Management
- Application deployment

Ok, so what does it all mean?

Well, when you think of the infrastructure that goes into running a Cloud Native Application consisting of a few or many Microservices in a Public (or Private) Cloud, you are looking at some (or all) of the following:

- DNS Service
- Load Balancers (with Certificates)
- Compute (VM Instances or Pods)
- Firewall Rules
- Cloud Account(s) and Permissions
- Databases
- ...

If you had a handful of Applications (with Microservices) to manage in a single cloud, managing it wouldn't be terribly hard. However, in reality, Organizations tend to have myriad of Applications instantiated across various lifecycles and more than a few Clouds! When you log into the Cloud provider's Console, you have no easy way to zero-in on your App resources! Spinnaker is as much about Application "Management" as it is about Application "Deployment"

## Spinnaker Microservices

![Spinnaker Microservices](https://s3.amazonaws.com/us-east-1-anand-files/spinnaker-architecture.jpg)

**[Deck](https://github.com/spinnaker/deck)**

  Browser-based UI

**[Gate](https://github.com/spinnaker/gate)**

  API Gateway: All API callers, including the UI, communicate with Spinnaker through Gate

**[Echo](https://github.com/spinnaker/echo)**

  Eventing Bus used for sending Notifications (like Emails, Slack, HipChat)

**[Orca](https://github.com/spinnaker/orca)**

  Orchestration Engine that handles all ad-hoc operations and Pipelines

**[Fiat](https://github.com/spinnaker/fiat)**

  Spinnaker's Authorization Service. It is used to query a user’s access permissions for accounts, applications and service accounts.

**[Clouddriver](https://github.com/spinnaker/clouddriver)**

  The arms of the Octopus (read, Spinnaker) that reaches out to the Clouds and mutates the infrastructure. It also indexes and caches all deployed resources

**[Igor](https://github.com/spinnaker/igor)**

  Integrates with build systems like Jenkins or TravisCI. Used to trigger pipelines via CI jobs. Also allows Jenkins/TravisCI stages to be used in Pipelines

**[Front50](https://github.com/spinnaker/front50)**

  Data Persistence Layer. Basically, persists Spinnaker data to the backend store

**[Kayenta](https://github.com/spinnaker/kayenta)**

  Canary Analysis Engine

**[Halyard](https://github.com/spinnaker/halyard)**

  Spinnaker's Configuration Service. It manages the lifecycle of each of the above services and only interacts with these services during Spinnaker startup, updates, and rollbacks.


## Spinnaker Nomenclature

**Project:**

  A Spinnaker Project is a collection of Spinnaker Applications. It's a view that pulls information about multiple Spinnaker Apps into a single pane

**Application:**

  Think of a Cloud Native Application as described above: A collection of Load Balancers, Compute Instance(s), Firewall Rules etc. No surprise to see that a Spinnaker Application is a collection of Clusters, which in turn is a collection of Server Groups (or Deployments). And yes, a Spinnaker Application also includes firewalls and load balancers! So, a Spinnaker Application truly represents the "Cloud Native App (or Service)" that a team is going to deploy using Spinnaker, all configuration for that App, and all the infrastructure on which it will run.

  Chances are, you will typically create a Spinnaker App per Cloud Native App you build

**Clusters (think, Deployment in Kubernetes):**

  Cluster is a collection of Server Groups (see below). Do not confuse Cluster here with Kubernetes Cluster! When deployed, a Server Group is a collection of instances of the running software (VM instances, Kubernetes Pods)

**Server Groups (think, ReplicaSet in Kubernetes):**

  The base resource, Server Group, identifies the deployable artifact and basic configuration settings such as number of instances, autoscaling policies, metadata etc. This resource is optionally associated with a Load Balancer and Firewall rules. 

**Instances (think, Pods in Kubernetes):**

  Server Group is a collection of the "atomic" entity within which a software is instantiated. Think individual virtual machine or a Kubernetes Pod. Hence, it should come as no surprise that we track Instance Count and Instance Types.

**Load Balancers:**

  Think of it as the entry doorway into your Cloud Native App. It is associated with ingress protocol, port ranges and often certificates. It balances traffic among instances in Server Groups. 

**Firewalls:**

  It defines network traffic access. Essentially a set of rules defined by IP Range (CIDR), protocol and port range

**Pipeline:**

  Pipeline is the App Deployment Management construct! It consists of a sequence of actions, known as Stages. You can pass parameters from Stage to Stage along the Pipeline. The Pipeline can be started manually or it can be triggered automatically by an external event, such as completion of a Jenkins Job or completion of a Container Image push to an Image Registry. It can also be triggered by another Stage in a different Pipeline!

**Stage:**

  A Stage in Spinnaker is an atomic building block for a pipeline, describing an action that the pipeline will perform. These stages can be sequenced in any order, though some stage sequences may be more common than others. Canned Stages are provided by Spinnaker to make it super simply to put together a Pipeline. For example:
  - Bake: Container or VM
  - Find Image
  - Deploy: Several Different Strategies
  - Wait
  - Disable/Enable
  - Resize
  - Manual Judgement
  - Check Preconditions

**Account:**

  In Spinnaker, an Account is a named credential Spinnaker uses to authenticate against a Cloud "Provider" (think, AWS, GCP, Azure, Kubernetes etc). Each provider has slightly different requirements for what format credentials can be in, and what permissions they need to be afforded to them. You can have as many accounts added as desired - this will allow you to keep your lifecycle environments (staging vs. production) separate, as well restrict access to sets of resources using Spinnaker's Authorization mechanisms. When working in the context of Kubernetes, an Account directly relates to a Cluster as defined by the `$HOME/.kube/config` file. Clouddriver component of Spinnaker reads `$HOME/.kube/config` file and adds each "Cluster" entry as an Account in Spinnaker

**Region:**

  Public Cloud Providers (like Amazon or Google) are hosted in multiple locations. These locations are composed of Regions and Availability Zones. Each Region is a separate geographic area and is completely independent. This achieves the greatest possible fault tolerance and stability. For Kubernetes, Region maps to Namespaces. Regions are more applicable when working with federated Kubernetes Clusters as you likely have nodes running in more than just one Region.

**Availability Zones:**

  Each Region has multiple, isolated locations known as Availability Zones. Each Availability Zone is isolated, but the Availability Zones in a Region are connected through low-latency links. It is not a bad idea to think of an Availability Zone as a separate Data Center, although it is not always the case.

**Stack:**

  It should come as no surprise that various aspects of Spinnaker reflects the culture at Netflix and how they do Continuous Delivery. One aspect of that is how they name Cloud Resources. The naming pattern is `application_name-stack_name-detail-version` where Stack refers to the Application lifecycle or environment of the App resources. Like, "staging" or "production"

**Detail:**

  Detail refers to things like "canary-staging" or "blue-version" or anything really that you want to add to further clarify and identify the cloud resource

**Status:**

  Is an Instance healthy, unhealthy, disabled etc.

## Understanding Spinnaker RBAC Model

![Spinnaker Fiat Service](https://s3.amazonaws.com/us-east-1-anand-files/spinnaker-rbac-overall.png)

Spinnaker's Fiat offers Authorization functionality.

There are three resources in Spinnaker that can be given permissions:

- Spinnaker Accounts
- Spinnaker Applications
- Spinnaker Pipelines

A single Spinnaker Account can contain multiple applications. Similarly, a single Spinnaker Application can involve multiple Spinnaker Accounts. Put simple, they have a M:N relationship with each other. Also, one Spinnaker Application can contain one or many Pipelines. However, one Pipeline can only belong to a single Spinnaker Application.

**Spinnaker Accounts:**

There are two types of access restrictions to a Spinnaker Account, `READ` and `WRITE`. Users that log into Spinnaker must belong to groups (LDAP or otherwise) that is assigned one `READ` permission to the account to view the cloud resources tied to the account. If they would like to make changes to these cloud resources, then the user must belong to a group that has been assigned `WRITE` permission to the Spinnaker account

Bottom line...

Giving an LDAP group WRITE privileges to a Spinnaker account essentially means that users belonging to that group can deploy code to that account. You want to be very careful about giving this privilege

**Spinnaker Applications**

Application permissions are pretty straightforward. If a logged in user belongs to group(s) that have been given READ permissions, they will be able to see the Spinnaker Application under "Applications" in Deck UI, but will not be able to modify the Application attributes. Not surprisingly, if the logged in user belongs to group(s) that have WRITE permissions, they will be able to modify the Application attributes.

Note, having Application-level `WRITE` permission does not mean they can "deploy" code to the Spinnaker account(s). It also does not mean they can modify the pipelines associated with the Application. 

Bottom line...

Giving an LDAP group WRITE privileges to a Spinnaker Application essentially means that users belonging to that group can modify "all" Application attributes, including permissions. However, 
- These users cannot magically escalate their permissions and gain the ability to deploy or edit Application resources assuming they do not have WRITE privileges to the Spinnaker Account(s) configured as part of the Spinnaker Application
- These users cannot modify existing Pipelines tied to the Spinnaker Application either, if the logged in user does not have access to the Service Account tied to the existing Pipelines. Of course, they can always create new Pipelines in the Application

It’s important to understand what may happen if you leave either an account or application without any configured permissions.

- If an account is unrestricted, any user with access to Spinnaker can deploy a new application to that account.
- If an application is unrestricted, any user with access to Spinnaker can deploy that application into a different account (_Note: Need to understand and verify_). They may also be able to see basic information like instance names and counts within server groups.


**Spinnaker Pipelines**

When pipelines run against accounts and applications that are protected, it is necessary to configure them with enough permissions to access those protected resources. Fiat Service Accounts enable the ability for automatically triggered pipelines to modify resources in protected accounts or applications. 

Service accounts are persistent and configuration merely consists of giving it a name and a set of roles. **Caution:** While it seems like you can create arbitrarily named FIAT Service Accounts that have nothing to do with LDAP, you will eventually get errors when you run the sync command (500) and authorize commands (404), and it does impact the overall functionality around the `Run As User` behavior despite the fact that the dropdown does show the entries.

The Roles (translation: the LDAP groups that this Service Account is a member of) given to a Service Account determines who has access to use it. In order to prevent a privilege escalation vulnerability, only users with _every_ role the service account has may use it. Translation: Only users who have all of the specified roles assigned to the Service Account can edit the pipeline!!

For example, if a logged in user `sujmuthu` has roles `code-sujmuthu`, `dftcd-apps-developer` and `dftcd-apps-admin` and service account `dft-ds.gen` has role `code-sujmuthu`, then the logged in user `sujmuthu` has access to assign `dft-ds.gen` as the `Run As User` service account to any Pipeline that she has write privileges to. However, she can only modify the pipeline if `sujmuthu` has access to the service account `dft-ds.gen` (she does) as well as the service account `dft-ds.gen` has write access to the Spinnaker Application to which this Pipeline belongs. Since `dft-ds.gen` only has role `code-sujmuthu`, it means the Spinnaker Application must give write permissions to the group `code-sujmuthu` in order for Sujatha to modify the Pipeline.

Now, imagine if the service account logged in user `sujmuthu` has roles `code-sujmuthu`, `dftcd-apps-developer` and `dftcd-apps-admin` and service account `cd-spinnaker.gen` has roles `code-sujmuthu` and `code-anasharm` (a role that `sujmuthu` does not belong to), then the user does not have access to the service account `cd-spinnaker.gen`. So, if `sujmuthu` has write access to a Spinnaker Application which has a Pipeline that will be "Run as" `cd-spinnaker.gen`, `sujmuthu` will not be able to make any changes to this Pipeline despite the fact that she has write access to the Spinnaker Application.

**How do I setup Spinnaker for my Application?**

![Setting up Spinnaker for App ABC](https://s3.amazonaws.com/us-east-1-anand-files/spinnaker-setup-for-app.png)

Let's say there is an application called _ABC_. You decide to create an App Management and App Deployment interface for this application using Spinnaker. When you create a Spinnaker Application for _ABC_, you should create two LDAP groups: 
  - _AppAdmin_: Group of users that will act as Application Admins or Release Managers
  - _AppDev_: Group consisting of all the application developers

The Spinnaker Account tied to the Application's Production Infrastructure should be setup to give write privileges to group _AppAdmin_ ONLY. It should give read access to the group _AppDev_. However, the Spinnaker Account tied to the Application's Non-Prod Infrastructure should be setup so that both _AppAdmin_ and _AppDev_ can read/write to that infrastructure.

The Spinnaker Application tied to the Application _ABC_ should give read/write privileges to group _AppAdmin_ and only read privileges to group _AppDev_. You really do not want _AppDev_ to have the ability to muck around with the Application Attributes, like permissions. Or wily nily create new Pipelines. 

Two Service Accounts (`ABC Prod SA` and `ABC Non-Prod SA`) should be created to run the Pipelines in the Application _ABC_. All Pipelines that interact with the Production Infrastructure should be setup with the `ABC Prod SA` service account that is a member of the group _AppAdmin_ ONLY. All other Pipelines that interact with Non-Production Infrastructure should be setup with the `ABC Non-Prod SA` Service Account which should be member of the group _AppAdmin_ and _AppDev_. What does that mean? A user belonging to _AppAdmin_ and _AppDev_ group will be the only ones who will be able to access both `ABC Prod SA` or `ABC Non-Prod SA` service accounts and set all the Pipelines up with the proper `Run As User` setting. A user belonging to _AppDev_ group will not have access to any of these Service Accounts!  

In Summary, Users belonging to _AppAdmin_ group:

- Can deploy the binaries of _ABC_ application, since they have write access to the Spinnaker Account 
- Can access and modify Spinnaker Application Attributes since they have read/write privileges to the Spinnaker Application
- Can create and modify all the Pipelines created to run as `ABC Prod SA` service account. If the User happens to belong to _AppDev_ group as well, they can modify all the Pipelines created to run as `ABC Prod SA` and `ABC Non-Prod SA` service accounts. Why? Since `ABC Prod SA` service account is a member of _AppAdmin_ while `ABC Non-Prod SA` is a member of _AppAdmin_ and _AppDev_. Remember, a logged in User has access to a Service Account if, and only if, the user has _every_ role the service account has! As a corollary, if the user belongs to ONLY _AppAdmin_ group, they will not be able to modify the Pipelines which are setup to run as `ABC Non-Prod SA` service account.

Users belonging to _AppDev_ group:

- Can deploy the binaries of _ABC_ application to the Non-Production Infrastucture since they have write access to the Spinnaker account tied to the Non-Production Infrastructure
- Cannot deploy the binaries of _ABC_ application to the Production Infrastucture since they do not have write access to the Spinnaker Account tied to the Production Infrastructure
- Can access and read, but not modify, the Application Attributes of the Spinnaker Application created for _ABC_
- Can run all the Pipelines. However, they can really only run the Pipelines that are setup to run as `ABC Non-Prod SA` service account and deploy to Non-Production Infrastructure since they only have read/write privilges to that Spinnaker Account. They cannot modify any of the Pipelines!

## Setting up Service Accounts

Here's how to create it, since we cannot use `hal` to perform CRUD operations to create Service Account.

Make sure your current kubernetes context points to the cluster and namespace where Spinnaker runs. You only need to run this if and only if Halyard is running outside of the Kubernetes cluster

```bash
kubectl run -i --rm --restart=Never debugpod --image=indrayam/debug-container:latest --command -- sleep 9999999
kubectl exec -it debugpod -- bash
```

Make sure the service discovery works

```bash
nslookup spin-front50
```

Create a sa.sh with the following content

```bash
FRONT50=http://spin-front50.spinnaker:8080
FIAT=http://spin-fiat.spinnaker:7003
ORCA=http://spin-orca.spinnaker:8083
ROSCO=http://spin-rosco.spinnaker:8087
IGOR=http://spin-igor.spinnaker:8088
REDIS=redis://spin-redis.spinnaker:6379
ECHO=http://spin-echo.spinnaker:8089
CLOUDDRIVER=http://spin-clouddriver.spinnaker:7002
DECK=http://spin-deck.spinnaker:9000
GATE=http://spin-gate.spinnaker:8084
```

```bash
chmod +x sa.sh
source sa.sh
```

Create or update Service Accounts using the following API call(s)

```bash
curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "jenkins-admin.gen", "memberOf": ["dftcd-apps-admin", "dftcd-apps-developer"] }' \
  $FRONT50/serviceAccounts | jq .

curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "spinnaker-demo1.gen", "memberOf": ["code-anasharm"] }' \
  $FRONT50/serviceAccounts | jq .

curl -X POST \
  -H "Content-type: application/json" \
  -d '{ "name": "spinnaker-demo2.gen", "memberOf": ["code-anasharm", "code-sujmuthu"] }' \
  $FRONT50/serviceAccounts | jq .

# See the Service Account(s)
curl -s $FRONT50/serviceAccounts | jq .

# A Fiat sync may be necessary for all affected users to pick up the changes:
curl -X POST $FIAT/roles/sync

# Confirm the new service account has permissions to the resources you think it should by querying Fiat
curl -s $FIAT/authorize/spinnaker-demo1.gen | jq .

# If you made a mistake, and you want to delete it, run the following command
curl -X DELETE -H "Content-type: application/json"  http://spin-front50:8080/serviceAccounts/<sa-name>
```


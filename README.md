# MongoDB deployment for Kubernetes on GKE

VeeScore uses MongoDB heavily as core database. At time of writing (March 2018) we migrate from self-hosted MongoDB setup at Blix (single bare-metal server) to GCP. This repository contains all code that is required to deploy a n-node setup onto a Kubernetes cluster running in GCP.

## Requirements

- GCP account 
- Google Cloud CLI
- Terraform
- Kontemplate

### Local workstation

You need to initialize your local workstation to use your GCP account, install Kubernetes CLI, configure authentication credentials and set the default GCP zone to be deployed to:

```
$ gcloud init
$ gcloud components install kubectl
$ gcloud auth application-default login
$ gcloud config set compute/us-central1-a
$ gcloud config set container/new_scopes_behavior true
```

Double-check if the workstation has been configured properly to access GCP infrastructure:

```
$ gcloud config list

```

### GCP web console

Create the project `veescore-production` within GCP web console.

## Deployment

The deployment of our MongoDB cluster is based on few scripts and configuration files in the project repository.

### Kubernetes cluster

First of all we need to perform the following steps:

- creating Kubernetes cluster in our GCP project `veescore-production`
- creating persistent disk storage
- creating persistent disk volumes
- creating key file for MongoDB (k8s shared secret)
- creating MongoDB service (including StatefulSet)
- waiting until all `mongod`'s have started properly
- feedback of Kubernetes cluster configurtion

There exists one shell script to achieve the tasks below:

```
$ ./create.sh
```

### MongoDB replica set and admin user

Next we need to configure the MongoDB replica set `rs0` and create an admin user `main_admin`. To achieve both launch the following shell script:

```
$ ./configure.sh MyVerySecretPW
```

The script basically connects to the first MongoDB instance that runs in a container in our Kubernetes StatefulSet. It uses the official MongoDB shell to initialize our replica set `rs0` and creates the admin user `main_admin`. The argument we provide launching the shell script is used as password for the admin user.

You should now have a MongoDB replica set initialised, secured and running in a Kubernetes stateful set. You can view the list of pods that contain these MongoDB resources, by launching the following command:

```
$ kubectl get pods
```

You should get a feedback message similar to:

```
NAME                      READY     STATUS    RESTARTS   AGE
hostvm-configurer-glhnm   1/1       Running   0          22m
hostvm-configurer-llblz   1/1       Running   0          22m
hostvm-configurer-wcbpm   1/1       Running   0          22m
mongod-0                  1/1       Running   0          22m
mongod-1                  1/1       Running   0          21m
mongod-2                  1/1       Running   0          21m
```

You can also check the state of our deplyed environment via []GCP web console](https://console.cloud.google.com). There you can check:

- `Compute Engine` -> `VM instances` lists 3 VMs which are the actual Kubernetes nodes hosting the actual pods.
- `Compute Engine` -> `Disks` lists 6 persistent disks (3 standard persistent disks for MongoDB cluster default pool and 3 SSD persistent disks for payload)
- `Kubernetes Engine` -> `Clusters` lists our Kubernetes cluster with its total vCPUs and RAM
- `Kubernetes Engine` -> `Storage` lists 3 persistent storage claims

You can also view the the state of the deployed environment via the [Google Cloud Platform Console]() (look at both the “Kubernetes Engine” and the “Compute Engine” sections of the Console).

The running replica set members will be accessible to any "app tier" containers, that are running in the same Kubernetes cluster, via the following hostnames and ports (remember to also specify the username and password, when connecting to the database):

    mongod-0.mongodb-service.default.svc.cluster.local:27017
    mongod-1.mongodb-service.default.svc.cluster.local:27017
    mongod-2.mongodb-service.default.svc.cluster.local:27017

You can reach e.g. secondary `mongod-1` from the primary `mongod-0` by launching the following command:

```
$ kubectl exec -it mongod-0 -c mongod-container bash
> mongo --shell --host mongod-1.mongodb-service.default.svc.cluster.local --port 27017
```

## Test

In this section I will shortly describe how to test if replication is working properly between members in our containerized replica set. On the other side our premise is that data is retained even when the MongoDB service or MongoDB stateful set is removed and then recreated. The recreation can happen by virtue or of by reusing same persistent volume claims. At this point we will test both behaviours.

### Replica set

First of all test if our MongoDB replica test has been setup properly and if data is replicated over all members. To achieve this connect to the container running the first MongoDB replica:
```
$ kubectl exec -it mongod-0 -c mongod-container bash
```

Next launch the MongoDB shell:
 
```
$ mongo
```

Being with the MongoDB shell we need to authenticate as `main_admin` user:

```
> db.getSiblingDB('admin').auth("main_admin", "MyVerySecretPW");
``` 

Finally create a new database `test`. It will be created automatically just by using it for first time:

```
> use test;

```

... and add some test data:

```
> db.users.insert({first_name: "John", last_name: "Doe"});
> db.users.insert({first_name: "Jane", last_name: "Roe"});
> db.users.find();
```

To check if the data has been mirrored to the other replica member, quit the current MongoDB shell session and connect to the second replica node:

```
> quit
```


### Redeployment without data loss

## Destroying Kubernetes cluster

Particularly in the testing and evaluation phase it makes sense to have one single shell script to tear down the entire Kubernetes cluster and to remove all project resources from GKE/GCE. This includes deleting the MongoDB stateful set, MongoDB service, shared secrets, releasing persistent disks (GCE) and deleting all associated data in persistent volumes (GKE). Finally we need to delete the whole Kubernetes cluster including its VM instances. To achieve this, there exists one script `destroy.sh` that takes care of all commands to be performed:

```
$ ./destroy.sh
```

Finally check in the [Google Cloud Platform Console](https://console.cloud.google.com) that all resources have been removed properly. You should be able recreate the cluster sitting on top of existing data volumes.


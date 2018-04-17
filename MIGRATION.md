# Migration of MongoDB data from casper to GKE

Our setup of VeeScore uses MongoDB as underlying database store for few years. VeeScore processes a high volume of data and generates a constant stream of data that is stored in our MongoDB database. The current setup runs on a single MongoDB node which is risky because of hardware failures, network outages, data loss etc.

Thus the aim is to migrate the entire MongoDB dataset to a 3 node replica cluster that is already up in running in our GKE cluster `mongodb-prod-cluster`.

In this doucment I will point out all steps that are required to migrate the actual data without any downtime.

## SSH tunnel

### casper

Due to security any remote login into the MongoDB setup on `casper.massive-insights.com` is disabled. To fetch data from a remote machine, create a SSH tunnel:

```
$~ ssh -L 37017:casper.massive-insights.com:27017 massive@casper.massive-insights.com
```

From now on you should be able to login into MongoDB that is mapped to localhost:

```
$ mongo --host localhost --port 37017
```

### GKE

Also the MongoDB pods in GKE are not straight available from the Internet. At this point we establish port forwarding for our first MongoDB pod `mongod-0` using Kubernetes:

```
$ kubectl port-forward mongod-0 47017:27017
```

We can login into the target MongoDB cluster by launching the following command:

```
$ mongo --username main_admin --password MyVerySecretPW --authenticationDatabase admin localhost:47017/test
```

## Migration

```
$ ./mongo-migration --from mongodb://localhost:37017/veescore_crawler --to mongodb://localhost:47017/test --in test --out output
```

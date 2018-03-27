#!/bin/bash

# This script connects to the first MongoDB instance running in a container of the
# Kubernetes StatefulSet. It uses the MongoDB shell to initalize a MongoDB replica
# set and create a MongoDB admin user.

if [[ $# -eq 0 ]] ; then
  echo "Missing argument as password for the 'main_admin' user."
  echo '  Usage:  configure_replica_set.sh MyVerySecretPW'
  echo
  exit 1
fi

# Create MongoDB replica set
echo ">>> Configuring MongoDB replica set rs0 ..."
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [ {_id: 0, host: "mongod-0.mongodb-service.default.svc.cluster.local:27017"}, {_id: 1, host: "mongod-1.mongodb-service.default.svc.cluster.local:27017"}, {_id: 2, host: "mongod-2.mongodb-service.default.svc.cluster.local:27017"} ]});'
echo

# Wait for MongoDB replica set to have its primary ready
echo ">>> Waiting for MongoDB replica set ..."
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'while (rs.status().hasOwnProperty("myState") && rs.status().myState != 1) { print("."); sleep(1000); };'
sleep 20
echo

# Create admin user
echo ">>> Creating user 'main_admin' ..."
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'db.getSiblingDB("admin").createUser({user:"main_admin",pwd:"'"${1}"'",roles:[{role:"root",db:"admin"}]});'
echo


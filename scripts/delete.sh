#!/bin/sh

# This script deletes MongoDB stateful set and MongoDB service

# Delete MongoDB stateful set
echo ">>> Deleting MongoDB stateful set ..."
kubectl delete statefulsets mongod
echo

# Delete MongoDB service
echo ">>> Deleting MongoDB service ..."
kubectl delete services mongodb-service
echo

kubectl get persistentvolumes
echo

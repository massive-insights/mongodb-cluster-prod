#!/bin/sh

# This script deploys a n-node MongoDB replica set onto an existing Kubernetes cluster.

kubectl get persistentvolumes
echo

# Create MongoDB service
echo ">>> Creating MongoDB service ..."
kubectl apply -f ../resources/service.yaml
sleep 5
echo

kubectl get persistentvolumes
echo
kubectl get all
echo
echo "Keep running until all 'mongod-n' pods are listed as running:"
echo "  $ kubectl get all"
echo

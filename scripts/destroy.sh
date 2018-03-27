#!/bin/sh

# This script removes all project resources from GKE/GCE.

cluster_name="mongodb-prod-cluster"

# Delete MongoDB stateful set
echo ">>> Deleting MongoDB stateful set"
kubectl delete statefulsets mongod
echo

# Delete MongoDB service
echo ">>> Deleting MongoDB service ..."
kubectl delete services mongodb-service
echo

# Delete Kubernetes shared secrets
echo ">>> Deleting Kubernetes shared secrets..."
kubectl delete secret shared-bootstrap-data
echo

# Delete DaemonSet
echo ">>> Deleting DaemonSet..."
kubectl delete daemonset hostvm-configurer
sleep 3
echo

# Delete persistent volume claims in GKE
echo ">>> Deleting persistent volume claims in GKE ..."
kubectl delete persistentvolumeclaims -l role=mongo
sleep 3
echo

# Delete persistent volumes in GKE
echo ">>> Deleting persistent volumes in GKE ..."
for i in 1 2 3
do
  kubectl delete persistentvolumes data-volume-$i
done
sleep 20
echo

# Delete persistent disks in GCE
echo ">>> Deleting persistent disks in GCE ..."
for i in 1 2 3
do
  gcloud -q compute disks delete pd-ssd-disk-$i
done
echo

# Delete Kubernetes cluster including its VM instances
echo ">>> Deleting Kubernetes cluster $cluster_name ..."
gcloud -q container clusters delete $cluster_name
echo

echo "Please double-check within the GCP web console at https://console.cloud.google.com if the Kubernetes cluster"
echo "and all related resources have been deleted properly."
echo

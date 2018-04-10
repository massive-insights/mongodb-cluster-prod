#!/bin/sh

# This script deploys a Kubernetes cluster to GKE and creates a n-node MongoDB replica set.
# The setup is based on Ubuntu.

cluster_name="mongodb-prod-cluster"
image_type="UBUNTU"
machine_type="n1-standard-2"

# Create Kubernetes cluster
echo ">>> Creating Kubernetes cluster $cluster_name ..."
gcloud container clusters create $cluster_name --image-type=$image_type --machine-type=$machine_type
echo

# Disable hugepages on host VM (via DaemonSet)
echo ">>> Disabling hugepages on host VM"
kubectl apply -f ../resources/daemon_set.yaml
echo

# Define storage class
# echo ">>> Defining storage class ..."
# kubectl apply -f ../resources/storage_class.yaml
# echo

# Create persistent disks in GCE
echo ">>> Creating persistent disks in GCE ..."
for i in 1 2 3
do
  gcloud compute disks create --size 10GB --type pd-ssd pd-ssd-disk-$i
done
sleep 3
echo

# Create persistent volumes in GKE
echo ">>> Creating persistent volumes in GKE ..."
for i in 1 2 3
do
  sed -e "s/INST/${i}/g" ../resources/persistent_volume.yaml > /tmp/persistent_volume.yaml
  kubectl apply -f /tmp/persistent_volume.yaml
done
rm /tmp/persistent_volume.yaml
sleep 3
echo

# Create key file for MongoDB cluster (Kubernetes shared secret)
echo ">>> Creating key file for MongoDB cluster ..."
keyfile_tmp=$(mktemp)
/usr/bin/openssl rand -base64 741 > $keyfile_tmp
kubectl create secret generic shared-bootstrap-data --from-file=internal-auth-mongodb-keyfile=$keyfile_tmp
rm $keyfile_tmp
echo

# Create MongoDB service
echo ">>> Creating MongoDB service ..."
kubectl apply -f ../resources/service.yaml
echo

# Wait until the final mongod has started properly
echo ">>> Waiting until the final mongod has started properly (ignore any reported not found & connection errors) ..."
sleep 30
echo -n "  "
until kubectl --v=0 exec mongod-2 -c mongod-container -- mongo --quiet --eval 'db.getMongo()'; do
  sleep 5
  echo -n "  "
done
echo

# --- Create Nginx deployment
echo ">>> Creating Nginx deployment ..."
kubectl apply -f ../resources/deployment.yaml
echo

kubectl get persistentvolumes
echo
kubectl get all 
echo

#!/bin/sh

# Exposing the service on a Nodeport enables access to the Calico Enterprise UI from outside the cluster
# Existing service must be deleted
kubectl delete svc -n tigera-manager tigera-manager

# Recreate service with NodePort on port 3200
kubectl apply -f ./ui-access/service-tigera-manager.yaml

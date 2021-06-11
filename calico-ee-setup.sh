#!/bin/sh
# Prerequisite: Must have config.json file containing Quay token and license.yaml file
#
# Configure Storage before proceeding

# Install the Tigera operator and custom resource definitions
kubectl create -f https://docs.tigera.io/manifests/tigera-operator.yaml

# Install the Prometheus operator and related custom resource definitions. The Prometheus operator will be used to deploy Prometheus server 
# and Alertmanager to monitor Calico Enterprise metrics
kubectl create -f https://docs.tigera.io/manifests/tigera-prometheus-operator.yaml

# Install pull secret - make sure config.json file exist in root of "KubeADM-and-Calico-EE-Cluster" directory
kubectl create secret generic tigera-pull-secret \
    --from-file=.dockerconfigjson=./config.json \
    --type=kubernetes.io/dockerconfigjson -n tigera-operator

# Install calicoctl - this is for a linux install as a binary
curl -o calicoctl -O -L https://docs.tigera.io/download/binaries/v3.7.0/calicoctl
chmod +x calicoctl

# Install for custom Tigera reesources
kubectl create -f https://docs.tigera.io/manifests/custom-resources.yaml
watch kubectl get tigerastatus

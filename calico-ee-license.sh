#!/bin/sh

# Installing the license. The yaml file must be located at the root of "KubeADM-and-Calico-EE-Cluster" directory
kubectl create -f ./license.yaml
watch kubectl get tigerastatus

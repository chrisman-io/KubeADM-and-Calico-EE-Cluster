#!/bin/sh
  
# Install the following network policies to secure Calico Enterprise component communications
kubectl create -f https://docs.tigera.io/manifests/tigera-policies.yaml

echo "Enter new user to be created:"
read username

# create a service account in the default namespace
kubectl create sa $username -n default

# Give the service account permissions to access the Calico Enterprise Manager UI, and a Calico Enterprise cluster role
kubectl create clusterrolebinding $username-access --clusterrole tigera-network-admin --serviceaccount default:$username

# Obtain token for service account which is used to log into the UI
kubectl get secret $(kubectl get serviceaccount $username -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep token) -o go-template='{{.data.token | base64decode}}' > ui-token.txt && echo "UI token generated and found in ui-token.txt"

# Obtain the password for user elastic to log into Kibana
kubectl -n tigera-elasticsearch get secret tigera-secure-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' > kibana-password.txt && \
        echo "Kibana password found in kibana-password.txt"


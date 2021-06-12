# KubeADM-and-Calico-EE-Cluster
This walks through the installation of a KubeADM Kubernetes cluster running on Ubuntu 20.04.2 LTS and the Calico CNI with Calico Enterprise Edition (EE). This installation requires a config.json file to pull the images from Tigera's repo and also a license.yaml for for Calico EE licensing. This installation also exposes the Calico EE UI as a NodePort in order to gain access from outside of the cluster. This setup has used the following nomenclature:

master node: k8s-master-01   
worker node: k8s-worker-01

This is important when using selectors when provisioning the Persistent Volume

Review the official Calico EE documentation for more info and explanation of deployment options: 
https://docs.tigera.io/about/about-calico-enterprise

  
## Initial Setup ##

Ensure you are at the root of the KubeADM-and-Calico-EE-Cluster directory. Run the intial setup script and enter the required variables. Commands are run as root and will require the password



```
$ bash setup.sh
Which version of Docker (eg 19.03.14,20.10.0)
19.03.14
Which Kubernetes version (eg. 1.19.0-00, 1.20.0-00)
1.19.0-00
Is this node the Master? (print yes or no)
no
```

If the node is the master there are additional variables required at the end of the script installation


```
CIDR range for Cluster: (e.g. 10.244.0.0/16)
10.10.0.0/16
Initialized Master Node with CIDR range 10.10.0.0/16 - Cluster token found in cluster_token.txt
```

On the master node the token for worker nodes to join the cluster is contained in the newly created file cluster_token.txt. Repeat the initial setup on each node using the `setup.sh` script.



## Master Node Preparation ##
Storage is required in order to provision the Calico EE components for logging and reporting. This guides walks through configuring a local volume one of the Kubernetes Nodes. This requires creating a Persistant Volume and enables mounting to the local Node directory. For this installation a directory of /var/log/calico-ee is created on Node k8s-worker-01 prior to the following steps. 


```
kubectl apply -f ./storage/storageclass.yaml
kubectl apply -f ./storage/es-pv.yaml
```

Run the `calico-ee-setup.sh` script to begin installation of the Calico CNI and Calico EE components. The config.json file is expected at the root of this cloned directory.

```
bash calico-ee-setup.sh
```
\
Wait until the `apiserver` status is `Available`

Install the Calico EE licensing. The license.yaml file is expected at the root of this cloned directory. 
\
Wait until all component status is `Available`  

## User Accounts and Tokens ##

Run the script `calico-ee-accounts.sh` to create user accounts to login into the UI. The token required to log into the UI is written to ui-token.txt and the password for kibana is written to kibana-password.txt

```
bash calico-ee-accounts.sh
```

## Exposing the UI interface ##

There are several options how to access the UI. This guide exposes the tigera-manager service as a NodePort on port 32000 which allows a user to target any of the of the Worker Node IP address on port 32000 to access the UI. As the default installation deploys the service with a cluster IP the Service needs to be deleted and recreated

```
bash ui-nodeport.sh
```

Now the UI is exposed on a node port a user can log into the UI on https://`<Worker Node IP>`:9443. The token for logging in is contained in file ui-token.txt. \

Log into Kibana useing `elastic` as the username and the password contained in the file kibana-password.txt




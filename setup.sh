#!/bin/sh

echo "Which version of Docker (eg 19.03.14,20.10.0)"
read versiondocker
echo "Which Kubernetes version (eg. 1.19.0-00, 1.20.0-00)"
read versionk8s
echo "Is this node the Master? (print yes or no)"
read mastercheck
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "added Docker GPG key"
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install -y docker-ce=5:$versiondocker~3-0~ubuntu-focal
echo "Docker CE v$versiondocker installed"
sudo apt-get install -y docker-ce-cli=5:$versiondocker~3-0~ubuntu-focal
echo  "Docker-ce-cli v$versiondocker installed"
sudo apt-get install -y containerd.io
echo " Containerd installed"

echo "Letting iptables see bridged traffic"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

echo "Adding Kubernetes apt repo"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y  kubelet=$versionk8s kubeadm=$versionk8s kubectl=$versionk8s
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Assuming bash is the shell. This re-initializes the shell session. Change your relevant shell script if needed
sudo apt-get update
echo "installed kubeadm, kubeket and kubectl"
echo "Disabling swap"
sudo swapoff -a
sudo rm /swap.img
# Need to Remove following line from /etc/fstab to persist
# /swap.img       none    swap    sw      0       0
sudo sed -i '/^\/swap/d' /etc/fstab

#sudo mkdir -p /etc/containerd
#sudo apt install -y containerd
#containerd config default | sudo tee /etc/containerd/config.toml
# Need to add one line to  /etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#  ...
#  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#    SystemdCgroup = true
#sudo sed -i '/containerd.runtimes.runc.options/a \            \SystemdCgroup = true' /etc/containerd/config.toml 
#sudo systemctl restart containerd

# Changing Docker cgroup driver to use systemd
sudo tee -a /etc/docker/daemon.json << END
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
END
sudo systemctl restart docker
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
# run on master node
if [ "$mastercheck" == 'yes' ]; then
  echo "CIDR range for Cluster: (e.g. 10.244.0.0/16)"
  read CIDR
  sudo kubeadm init --pod-network-cidr=$CIDR > cluster_token2.txt
  awk '/kubeadm join/,0' cluster_token2.txt > cluster_token.txt && rm cluster_token2.txt
  sed -i '1s/^/sudo /' cluster_token.txt
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  echo "Initialized Master Node with CIDR range $CIDR - Cluster token found in cluster_token.txt "
fi
source ~/.bashrc  
echo "Installation complete"

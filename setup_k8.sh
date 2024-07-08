# script to setup k8

#!/bin/bash

# Install Kubernetes and necessary packages
sudo dnf install -y kubernetes kubernetes-kubeadm kubernetes-client
sudo dnf install -y kubernetes kubernetes-client kubernetes-systemd
sudo dnf update

# Disable swap
sudo systemctl stop swap-create@zram0
sudo dnf remove zram-generator-defaults -y
sudo systemctl disable --now firewalld
sudo dnf install -y iptables iproute-tc

# Configure IPv4 forwarding and bridge filters
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Load overlay
sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl parameters required by setup, params persist across reboots
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
lsmod | grep br_netfilter
lsmod | grep overlay
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Install CRI-O and networking plugins
sudo dnf install -y cri-o containernetworking-plugins

# For Fedora 39 and earlier
sudo dnf install -y kubernetes-client kubernetes-node kubernetes-kubeadm

# For Fedora 40 and later
sudo dnf install -y kubernetes kubernetes-kubeadm kubernetes-client

# Enable and start CRI-O
sudo systemctl enable --now crio

# Pull Kubernetes images
sudo kubeadm config images pull

# Enable and start Kubelet
sudo systemctl enable --now kubelet

# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubeconfig for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Remove taint from control-plane node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Apply Flannel CNI
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

# Check pods in all namespaces
kubectl get pods --all-namespaces

# Install versionlock plugin and lock package versions
sudo dnf install -y 'dnf-command(versionlock)'
sudo dnf versionlock add kubernetes*-1.28.* cri-o-1.28.*

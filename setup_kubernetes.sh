#!/bin/bash

set -ex

# cleanup prev install
rm -rf gvisor-containerd-shim

sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common apparmor
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

sudo apt-get update && sudo apt-get remove -y containerd.io && sudo apt-get install -y containerd.io=1.6.12-1

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
#sudo apt-get remove -y kubelet kubeadm kubectl
sudo apt-get install -qy kubelet=1.21.0-00 kubectl=1.21.0-00 kubeadm=1.21.0-00
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a

## Install go
wget https://golang.org/dl/go1.14.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.14.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

## Install gvisor containerd shim
git clone https://github.com/google/gvisor-containerd-shim
cd gvisor-containerd-shim
make
sudo make install

#cat <<EOF | sudo tee /etc/containerd/config.toml
#disabled_plugins = ["restart"]
#[plugins.linux]
#  shim_debug = true
#[plugins.cri.containerd.runtimes.runsc]
#  runtime_type = "io.containerd.runsc.v1"
#EOF
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
  shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF


sudo systemctl restart containerd
sudo mkdir -p /mydata/seclambda_log
sudo mkdir -p /mydata/microbench_logs
sudo mkdir -p /mydata/mount
sudo chmod 777 -R /mydata

if [ "$1" == "--control" ]; then
	sudo apt install -y python3-pip libssl-dev libz-dev luarocks
	sudo luarocks install luasocket
	sudo kubeadm init --control-plane-endpoint $(hostname) --pod-network-cidr=10.217.0.0/16
  	mkdir -p $HOME/.kube
  	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  	sudo chown $(id -u):$(id -g) $HOME/.kube/config
  	#kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml
	curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
	sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
	rm cilium-linux-amd64.tar.gz{,.sha256sum}
	sudo cilium install
	cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1beta1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF
        sudo apt-get update
	sudo apt-get install -y ca-certificates curl gnupg lsb-release
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install -y docker-ce docker-ce-cli

	#echo "#################################"
	#echo "Installing OpenFaas"
	#kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
	#curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
	#helm repo add openfaas https://openfaas.github.io/faas-netes/
	#helm upgrade openfaas --install openfaas/openfaas     --namespace openfaas      --set functionNamespace=openfaas-fn     --set generateBasicAuth=true     --set openfaasPRO=false     --set faasnetes.httpProbe=false     --set faasnetes.livenessProbe.timeoutSeconds=5 --set faasnetes.livenessProbe.periodSeconds=70      --set faasnetes.readinessProbe.periodSeconds=70
	#curl -sSL https://cli.openfaas.com | sudo -E sh
	#wget -O crd.yaml https://raw.githubusercontent.com/openfaas/faas-netes/master/artifacts/crds/openfaas.com_profiles.yaml
	#echo "Experimental try profile with openfaas-fn as well"
	#cat <<EOF | kubectl apply -f - 
        #  kind: Profile
        #  apiVersion: openfaas.com/v1
        #  metadata:
        #    name: test
        #    namespace: openfaas
        #  spec:
            # Configuration values can be set as key-value properties
        #      runtimeClassName: gvisor
#EOF
	#curl -sSL https://cli.openfaas.com | sudo -E sh
	#faas-cli login --password $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode) --gateway $HOSTNAME:31112

	#helm uninstall -n openfaas openfaas
	#git clone https://github.com/deepaksirone/faas-netes.git
	#pushd ./faas-netes 
	#git checkout gvisor
	#kubectl apply -f ./yaml_runc
	#popd

	#sleep 20

	#faas-cli login --password $(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode) --gateway $HOSTNAME:31112
	#echo "#### Now copy gVisor and seclambda to /usr/local/bin on all nodes and move the default docker image store ####"
	
fi

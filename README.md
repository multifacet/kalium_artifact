# Artifact for Kalium - USENIX Security '23

This repository contains the artifact for the paper `Guarding Serverless Applications with Kalium`. The project contains 3 submodules that need to be built separately. The following has been tested on a Kubernetes cluster of 5 machines running Ubuntu 18.04 LTS.

Clone this repo to a build machine using
```
git clone https://github.com/multifacet/kalium_artifact && cd kalium_artifact && git submodule update --init --recursive
```

### Table of Contents
1. [Pre-Build](#pre-build)
2. [Building](#building)
3. [Setting up Kubernetes](#setup_kubernetes)
4. [Setting up Controller](#setup_controller)
5. [Running Benchmarks](#benchmarks)

### Pre-Build <a name="pre-build"></a>
[Time taken: <= 30 mins]
Provision 6 machines running Ubuntu 18.04 LTS. 5 of these will be used for the Kubernetes cluster while 1 of them will be used for the Kalium controller. All the nodes should have a publicly addressable hostname.

### Building <a name="building"></a>
[Time taken: 10-20 mins]

Install `docker` based on your distro's [install instructions](https://docs.docker.com/engine/install/)

Run `./build-docker.sh <controller-hostname>`. This will generate a build directory `build` with all the required binaries - `runsc_stock` (gVisor), `runsc_kalium` (kalium), `runsc_microbench` (kalium with logging), `seclambda` (kalium-proxy) and `ctr` (controller)

### Setting up Kubernetes Nodes <a name="setup_kubernetes"></a>

The Kubernetes cluster is assumed to have 5 nodes with one of them being the controller node. You may choose any one of the nodes to be the controller.

##### Setting Up The Kubernetes Controller Node

Copy `setup_kubernetes.sh` to a clean directory on the Kubernetes controller node (not the Kalium controller node). Run `./setup_kubernetes.sh --control &> setup_log` on the controller node. This will install Kubernetes and Cilium on the controller node. The script will prompt for `sudo` access whenever required.

Search for the following text in `setup_log`:
```
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <hostname> --token <TOKEN> \
	--discovery-token-ca-cert-hash sha256:<hash>
```

The command above can be used to join worker nodes to the cluster.

Create the log directory as follows:
```
sudo mkdir -p /mydata
sudo chmod 777 -R /mydata 
```

`/mydata` will contain some fine grained measurements that are output from the container runtime (gVisor) as well as some database files.

##### Setting Up Kubernetes Worker Nodes
Repeat the following steps for each of the Kubernetes worker nodes.

Copy `setup_kubernetes.sh` to a clean directory on the worker node. Run `./setup_kubernetes.sh &> setup_log` on the worker node. This will install Kubernetes on the worker node. 

After the script finishes running, run the command for adding the worker node to the cluster:
```
sudo kubeadm join <hostname> --token <TOKEN> \
	--discovery-token-ca-cert-hash sha256:<hash>
```

Create the log directory as follows:
```
sudo mkdir -p /mydata
sudo chmod 777 -R /mydata
```

`/mydata` will contain some fine grained measurements that are output from the container runtime (gVisor) as well as some database files.


##### Setting up OpenFaas
After all the worker nodes have joined the cluster, install OpenFaas on the Kubernetes controller as follows.

Copy `setup_openfaas.sh` to a clean directory on the controller node. Run `./setup_openfaas.sh &> setup_log`. This will install OpenFaas and faas-cli on the cluster.

##### Copying Kalium Proxy
Copy `build/bin/seclambda` to `/usr/local/bin` in each of the Kubernetes nodes

### Setting up Controller Node <a name="setup_controller"></a>

Copy `build/bin/ctr`, `build/bin/policy_test.json` and `build/bin/instid` to the Kalium controller node.

### Running Benchmarks <a name="benchmarks"></a>

Follow the steps in kalium-benchmarks/README.md

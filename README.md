# Artifact for Kalium - USENIX Security '23

This repository contains the artifact for the paper `Guarding Serverless Applications with Kalium`. The project contains 3 submodules that need to be built separately. The following has been tested on a cluster of 5 machines running Ubuntu 18.04 LTS.

Clone this repo to a build machine (preferrably running Ubuntu 18.04 LTS) using
```
git clone https://github.com/multifacet/kalium_artifact && git submodule update --init --recursive
```

### Table of Contents
1. [Building](#building)
2. [Setting up Kubernetes](#setup_kubernetes)
3. [Setting up Controller](#setup_controller)
4. [Running Benchmarks](#benchmarks)


### Building <a name="building"></a>
Building has been tested on Ubuntu 18.04

##### Prerequisites
Run `setup-prerequisites.sh` to setup the prerequisites

##### Prebuild Steps

Modify line 336 in kalium/runsc/container/container.go ([here](https://github.com/multifacet/kalium/blob/12ef38ce771ac6b29665cbad11017838d55363bb/runsc/container/container.go#L336)) to point to the URI of the controller node

##### Build Step
Run `./build.sh`. This will generate a folder `build` containing the binaries `runsc` (gVisor), `seclambda` (kalium-proxy) and `ctr` (controller)

### Setting up Kubernetes Nodes <a name="setup_kubernetes"></a>

The Kubernetes cluster is assumed to have 5 nodes with one of them being the controller node. You may choose any one of the nodes to be the controller.

##### Setting Up The Kubernetes Controller Node

Copy `setup_kubernetes.sh` to a clean directory on the controller node. Run `./setup_kubernetes.sh --control &> setup_log` on the controller node. This will install Kubernetes and Cilium on the controller node. The script will prompt for `sudo` access whenever required.

Search for the follwing text in `setup_log`:
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

##### Copying runsc and seclambda
Copy `build/runsc` and `build/seclambda` to `/usr/local/bin` in each of the Kubernetes nodes

### Setting up Controller Node <a name="setup_controller"></a>

Copy `build/ctr`, `build/policy_test.json` and `build/instid` to the controller node.

Run `./ctr policy_test.json`. The controller defaults to port 5000

### Running Benchmarks <a name="benchmarks"></a>

Follow the steps in kalium-benchmarks/README.md

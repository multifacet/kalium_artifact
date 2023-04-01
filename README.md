# Artifact for Kalium - Usenix Security '23

This repository contains the artifact for the paper `Guarding Serverless Applications with Kalium`. The project contains 3 submodules that need to be built separately. The following has been tested on a cluster of 5 machines running Ubuntu 18.04 LTS.

### Table of Contents
1. [Building](#building)
2. [Setting up Kubernetes](#example2)
3. [Setting up Controller](#third-example)
4. [Running Benchmarks](#fourth-examplehttpwwwfourthexamplecom)


### Building <a name="building"></a>
Building has been tested on Ubuntu 18.04

##### Prerequisites
Run `setup-prerequisites.sh` to setup the prerequisites

##### Prebuild Steps

Modify line 336 in kalium/runsc/container/container.go ([here](https://github.com/multifacet/kalium/blob/12ef38ce771ac6b29665cbad11017838d55363bb/runsc/container/container.go#L336)) to point to the URI of the controller node

##### Build Step
Run `./build.sh`. This will generate a folder `build` containing the binaries `runsc` (gVisor), `seclambda` (kalium-proxy) and `ctr` (controller) 

### Setting up Kubernetes Nodes

The Kubernetes cluster is assumed to have 5 nodes with one of them being the controller node.

##### Setting Up The Kubernetes Controller Node

Copy `setup_kubernetes_openfaas` to a clean directory. Run `sudo setup_kubernetes_openfaas.sh --control &> setup_log` on the controller node. This will install Kubernetes, Cilium and OpenFaaS on the controller node.

Search for the follwing text in `setup_log`:
```
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <hostname> --token <TOKEN> \
	--discovery-token-ca-cert-hash sha256:<hash>
```

The command above can be used to join worker nodes to the cluster.

##### Setting Up Kubernetes Worker Nodes

Copy `setup_kubernetes_openfaas` to a clean directory. Run `sudo setup_kubernetes_openfaas.sh &> setup_log` on the controller node. This will install Kubernetes, Cilium and OpenFaaS on the worker node.

After the script finishes running, run the command for adding the worker node to the cluster:
```
sudo kubeadm join <hostname> --token <TOKEN> \
	--discovery-token-ca-cert-hash sha256:<hash>
```

##### Copying runsc and seclambda
Copy `build/runsc` and `build/seclambda` to `/usr/local/bin` in each of the kubernetes nodes (including the controller)

### Setting up Controller Node

Copy `build/ctr`, `build/policy_test.json` and `build/instid` to the controller node.

Run `./ctr policy_test.json`. The controller defaults to port 5000
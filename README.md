# Artifact for Kalium - USENIX Security '23

This repository contains the artifact for the paper `Guarding Serverless Applications with Kalium`. The project contains 3 submodules that need to be built separately. The following has been tested on a Kubernetes cluster of 5 machines running Ubuntu 18.04 LTS.

Clone this repo to a build machine (**should not be one of the Kubernetes nodes or the Kalium Controller**) using
```
git clone https://github.com/multifacet/kalium_artifact && cd kalium_artifact && git submodule update --init --recursive
```

### Table of Contents
1. [Pre-Build](#pre-build)
2. [Building](#building)
3. [Setting up Kubernetes](#setup_kubernetes)
4. [Setting up Controller](#setup_controller)
5. [Setting up Image Server](#imgsrvr)
6. [Basic Test](#test)
7. [Running Benchmarks](#benchmarks)

### 1. Pre-Build <a name="pre-build"></a>
**[Time taken: <= 30 mins]**

Provision 6 machines running Ubuntu 18.04 LTS. 5 of these will be used for the Kubernetes cluster while 1 of them will be used for the Kalium controller. All the nodes should have a publicly addressable hostname.

A sample configuration is as follows:
- node0: Kubernetes Worker
- node1: Kubernetes Worker
- node2: Kubernetes Worker
- node3: Kubernetes Worker
- node4: Kubernetes Controller
- node5: Kalium Controller

### 2. Building (On the build machine) <a name="building"></a>
**[Time taken: 10-20 mins]**

Install `docker` based on the build machine's distro's [install instructions](https://docs.docker.com/engine/install/)

**Warning** Installing docker on any of the Kubernetes nodes or Kalium Controller may cause errors with the Kubernetes setup

Run `./build-docker.sh <kalium-controller-hostname>`. This will generate a build directory `build` with all the required binaries - `runsc_stock` (gVisor), `runsc_kalium` (kalium), `runsc_microbench` (kalium with logging), `seclambda` (kalium-proxy) and `ctr` (controller)

### 3. Setting up Kubernetes Nodes <a name="setup_kubernetes"></a>
**[Time taken: <= 40 mins]**

The Kubernetes cluster is assumed to have 5 nodes with one of them being the controller node. You may choose any one of the nodes to be the Kubernetes controller.

#### 3.1 Setting Up The Kubernetes Controller Node

Copy `setup_kubernetes.sh` from the build machine to a clean directory on the Kubernetes controller node (not the Kalium controller node). Run `./setup_kubernetes.sh --control &> setup_log` on the controller node. This will install Kubernetes and Cilium on the controller node. The script will prompt for `sudo` access whenever required.

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

#### 3.2 Setting Up Kubernetes Worker Nodes
Repeat the following steps for each of the Kubernetes worker nodes.

Copy `setup_kubernetes.sh` from the build machine to a clean directory on the worker node. Run `./setup_kubernetes.sh &> setup_log` on the worker node. This will install Kubernetes on the worker node. 

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


#### 3.3 Setting up OpenFaas
After all the worker nodes have joined the cluster, install OpenFaas on the Kubernetes controller as follows.

Copy `setup_openfaas.sh` from the build machine to a clean directory on the controller node. Run `./setup_openfaas.sh &> setup_log`. This will install OpenFaas and faas-cli on the cluster.

#### 3.4 Copying Kalium Proxy
Copy `build/bin/seclambda` from the build machine to `/usr/local/bin` in each of the Kubernetes nodes

### 4. Setting up Controller Node <a name="setup_controller"></a>
**[Time taken: <= 5 mins]**

Copy `build/bin/ctr`, `build/bin/policy_test.json` and `build/bin/instid` from the build machine to the Kalium controller node.

### 5. Setting up Image Server <a name="imgsrvr"></a>
**[Time taken: approx 10 mins]**

The image server is needed for the microbenchmark as well as the receive function in the product-photos benchmark. It is a python server script that serves an image at the url https://<hostname>:4443/image.jpg

In order for kalium to intercept the request, the server needs a valid certificate chain.

Copy the `python_server` folder into the Kalium controller node. Follow the guide at [the certbot website](https://certbot.eff.org/instructions?ws=other&os=ubuntubionic) to get a certificate for the controller domain. When prompted for the domain, provide the publicly facing hostname of the controller node.

Create a directory called `certs` in `srv_dir`. Copy `fullchain.pem` and `privkey.pem` to `certs`.

Open a new terminal to the controller and start the server by running `python server.py`. Test it out by visiting the URL [https://\<hostname\>:4443/image.jpg]() on your browser

### 6. Basic Test <a name="test"></a>
This test ensures that all the necessary elements of Kalium are working including the Kalium controller and the Image Server. Please do this step after completing steps 1-5.

- Copy `build/bin/runsc_kalium` from the build machine to `/usr/local/bin/runsc` on all the Kubernetes nodes
- Open two terminals to the Kalium controller and run `./ctr policy_test.json` to start the Kalium controller and run `python server.py` in the other terminal to start the image Server
- Open a terminal to the Kubernetes controller node and checkout the Kalium artifact by running `git clone https://github.com/multifacet/kalium_artifact && cd kalium_artifact && git submodule update --init --recursive` and checking out the stable commit
- Change directory to `kalium-benchmarks` and checkout the `artifact_kalium` branch
- Navigate to `vanilla-hello-retail/product-photos/1.microbench` and edit `MediaUrl0` in `sample-input_localurl.json` to point to the URL of the image served by the image server ([https://\<hostname\>:4443/image.jpg]())
- Run `faas-cli deploy -f product-photos-1-microbench.yml --gateway $HOSTNAME:31112 && sleep 70`, this should deploy the microbenchmark function
- If the pod starts successfully, the Kalium controller should print out information about the pod that connected to it
- Next run ,`curl -d @sample-input_localurl.json -w "@curl-format_total.txt" -H "Content-Type: application/json" -X POST "http://$HOSTNAME:31112/function/product-photos-1-microbench"` to invoke the function with `sample-input_localurl.json`
- If that run was successful, the function should echo back its input json and a POST request entry should up in the image server log on the terminal
- After the run, remove the function by running `faas-cli remove -f product-photos-1-microbench.yml --gateway $HOSTNAME:31112`
- Return to a clean benchmark repo by running `git checkout .`


### 7. Running Benchmarks <a name="benchmarks"></a>

Follow the steps in kalium-benchmarks/README.md

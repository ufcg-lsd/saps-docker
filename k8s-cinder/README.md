# Deploying SAPS on Kubernetes Cluster

## Prerequisites

Your cluster must have at least one node with 16GB RAM.

## Install Kubeadm

You need to install kubeadm and cluster dependencies in all nodes of your cluster. You can do that by executing the `install-k8s.sh` script in each one of them.

```
sudo bash install-k8s.sh
```

## Change cgroup driver

You need to change the docker cgroup driver on all nodes. Create or edit the `/etc/docker/daemon.json` configuration file and include the following:

```
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

After saving it, restart your docker service.

```
sudo systemctl restart docker
```

## Setup K8s using OpenStack Cinder

For our cluster, we use (and recommend) Weave as a Network Provider.

First you need to have a configuration file that points the **cloud-provider** as external. The [kubeadm-conf.yaml](./kubeadm-conf.yaml) is already configured to create the cluster in version 1.22.1. Choose your master node, create the `kubeadm-conf.yaml` and run the following commands:

```
sudo kubeadm init --config kubeadm-conf.yaml
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Run the command that was output by `kubeadm init` on master inside the worker nodes. For example:
```
kubeadm join --token <token> <master-ip>:<master-port>
```

Verification of the presence of the new node in the cluster:
```
kubectl get nodes
```

### Install Weave

In order to install Weave, run the following command:

**Note**: The `IPALLOC_RANGE` must be equal to the podSubnet chosen in the `kubeadm-conf.yaml`
```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=192.168.0.0/16"
```

Wait until each pod has the status of **Running** with the following command:
```
watch kubectl get pods -n kube-system
```

## Install CSI Cinder Driver

Now you need to install the necessary resources for the CSI Cinder Driver to manage the OpenStack Cinder volumes. You can find this more specific tutorial in the [csi-cinder-driver](./csi-cinder-driver) directory.


## Configuration

It is necessary to edit the [cinder-storage.yaml](./cinder-storage.yaml) and change the **availability** zone and the **storage** space to values ​​consistent with your openstack resources.

The kubeconfig is the config file with credentials to access the k8s cluster. It will be used by Arrebol. Run the command below to get the contents of the k8s configuration file:

```
kubectl config view --flatten --minify --raw
```

Copy the output from the above command and paste it into the kubeconfig ConfigMap replacing `kube_config` with the output. This configuration is done in the [arrebol_deployment_k8s.yaml](./arrebol_deployment_k8s.yaml) file.

```
# Run the command below to get the contents of the k8s configuration file
# kubectl config view --flatten --minify --raw
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubeconfig
data:
  config: |
    kube_config
```

The rest of the files are already set up, but you can edit things like the namespace,catalog credentials or component details at your own risk.

## Install

With all the files configured, we can already deploy to the cluster, for that, first create the StorageClass and PersistentVolumeClaim for the Cinder Volume:

```
kubectl create -f cinder-storage.yaml
```

Check if the pvc is bound to a volume with:
```
kubectl get pvc
```

Now, you can already deploy arrebol and catalog:

```
kubectl create -f arrebol_deployment_k8s.yaml -f catalog_deployment.yaml
```

With the catalog and arrebol running, it's time to deploy the remaining components:

```
kubectl create -f archiver_deployment.yaml -f dispatcher_deployment.yaml -f scheduler_deployment.yaml
```

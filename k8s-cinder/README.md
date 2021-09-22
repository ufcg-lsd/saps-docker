# Deploying SAPS on Kubernetes Cluster

## Prerequisites

Your cluster must have at least one node with 16GB RAM to run the workers and another one with less than that (e.g 4GB RAM) to run the saps services.

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

## Deploy Cinder Storage Class

It is necessary to edit the [cinder-storage.yaml](./cinder-storage.yaml) and change the **availability** zone and the **storage** space to values ​​consistent with your openstack resources. Your openstack must allow volumes to have the multi-attachment property, and put this type of volume in **type** parameter in the same file. You can find more info about multi-attach volumes at this [link](https://itnext.io/kubernetes-on-devstack-part-3-running-applications-on-the-cluster-f15cf4762822).


Now we can already deploy to the cluster, for that, create the StorageClass and PersistentVolumeClaim for the Cinder Volume with:

```
kubectl apply -f cinder-storage.yaml
```

Check if the pvc is bound to a volume with:
```
kubectl get pvc
```

## Deploy Catalog, Archiver and Dispatcher

The Dispatcher and the Archiver components depend on the Catalog, so deploy the Catalog first with:

```
kubectl apply -f catalog_deployment.yaml
```

Wait until the catalog has the status of **Running** with the following command:

```
watch kubectl get pods
```

Now, you can deploy the Archiver and Dispatcher:

```
kubectl apply -f archiver_deployment.yaml -f dispatcher_deployment.yaml 
```

## Deploy Arrebol and Scheduler

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

Deploy the Arrebol by running the following command:

```
kubectl apply -f arrebol_deployment_k8s.yaml
```

## Deploy Scheduler

The Scheduler component depend on the Arrebol, wait until the Arrebol has the status of **Running** with the following command:

```
watch kubectl get pods
```

Now, you can deploy the Scheduler:

```
kubectl apply -f scheduler_deployment.yaml
```

# Deploying SAPS on Kubernetes Cluster

## Prerequisites

Your cluster must have at least one node with 16GB RAM and a NFS Server.

## Deploy NFS Server

Install NFS Server dependency:

```
sudo apt-get install -y nfs-kernel-server
```

Before starting the NFS daemon, please choose an directory, `$nfs_server_dir_path`, in your machine local file system. The NFS daemon will hold the exported files within this directory. Below commands setup the NFS server:

```
mkdir -p $nfs_server_dir_path
echo "$nfs_server_dir_path *(rw,insecure,no_subtree_check,async,no_root_squash)" >> /etc/exports
sudo service nfs-kernel-server restart
```

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

## Setup K8s

Choose your master node and run the following commands:
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

Run the command that was output by `kubeadm init` on master inside the worker nodes. For example:
```
kubeadm join --token <token> <master-ip>:<master-port>
```

Verification of the presence of the new node in the cluster:
```
kubectl get nodes
```

## Configuration

It is necessary to edit the [nfs-pv-pvc.yaml](./nfs-pv-pvc.yaml) and change the `server` and `path` attributes with the NFS Server IP and `$nfs_server_dir_path` respectively.
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

With all the files configured, we can already deploy to the cluster, for that, first create the PersistentVolume and PersistentVolumeClaim for the NFS Server:

```
kubectl create -f nfs-pv-pvc.yaml
```

Now, you can already deploy arrebol and catalog:

```
kubectl create -f arrebol_deployment_k8s.yaml -f catalog_deployment.yaml
```

With the catalog and arrebol running, it's time to deploy the remaining components:

```
kubectl create -f archiver_deployment.yaml -f dispatcher_deployment.yaml -f scheduler_deployment.yaml
```

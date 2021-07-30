# Deploying SAPS on Google Cloud Platform(GCP)

SAPS can be deployed in GCP using the Kubernetes cluster offered by them. To do this, you need to log into your google account and [access the console](https://cloud.google.com/kubernetes-engine/). 
It is highly recommended that you create a new cluster instead of using the one that comes already, as the jobs requested by Arrebol need you to have one node with at least 16GB RAM.

## Prerequisites

Your cluster must have at least one node with 16GB RAM and a blank disk that can be created via the platform.

## Configuration

It is necessary to edit the [nfs-server.yaml](./nfs-server.yaml) and change the pdName of your gcePersistentDisk to the name of the blank disk created earlier (By default the name is disk-1).
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

With all the files configured, we can already deploy to the cluster, for that, first deploy the nfs-server:

```
kubectl create -f nfs-server.yaml
```

With the NFS Server running, we can already deploy arrebol and catalog:

```
kubectl create -f arrebol_deployment_k8s.yaml -f catalog_deployment.yaml
```

With the NFS Server, catalog and arrebol running, it's time to deploy the remaining components:

```
kubectl create -f archiver_deployment.yaml -f dispatcher_deployment.yaml -f scheduler_deployment.yaml
```

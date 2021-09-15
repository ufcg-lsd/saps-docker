# Deploying SAPS on Google Cloud Platform(GCP)

SAPS can be deployed in GCP using the Kubernetes cluster offered by them. To do this, you need to log into your google account and [access the console](https://cloud.google.com/kubernetes-engine/). 
It is highly recommended that you create a new cluster instead of using the one that comes already, as the jobs requested by Arrebol need you to have one node with at least 16GB RAM.

## Prerequisites

Your cluster must have at least one node with 16GB RAM to run the workers And another one with less than that (e.g 4GB RAM) to run the saps services. You also need a blank disk that can be created via the platform to run the NFS Server.

### Creating Disk in the Google Cloud

- In the Google Cloud Console, access the `Disks` page and click in `Create disk`.
- Specify the name of your disk, this will be the `$pdName` that will be used to configurate the NFS Server later.
- Select the Region and Zone of disk, that must be the same region of your VM.
- In disk type, choose a blank disk.

## Deploy NFS Server

It is necessary to edit the [nfs-server.yaml](./nfs-server.yaml) and change the `pdName` of your gcePersistentDisk to the `$pdName` of the blank disk created earlier.

With the file configured, we can already deploy to the cluster, run the following command:

```
kubectl apply -f nfs-server.yaml
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

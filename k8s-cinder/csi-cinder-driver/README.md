# Install CSI Cinder Driver

You need to create a `cloud.conf` as in the [example](./cloud.conf) we have with the necessary credentials for your cluster to access the OpenStack.

- **auth-url**: OpenStack identity URL
- **tenant-id**: Project ID
- **user-id**: User ID with acess to the project
- **password**: User password.

You can find more information about the configurable options at this [link](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/openstack-cloud-controller-manager/using-openstack-cloud-controller-manager.md#global).

## Configuring Openstack Cloud Controller Manager

Create a secret based on the configuration file created before:
```
kubectl create secret -n kube-system generic cloud-config --from-file=cloud.conf
```

Now you need to create the RBAC resources, roles and daemon set that are already present in this directory:

```
kubectl apply -f cloud-controller-manager-roles.yaml
kubectl apply -f cloud-controller-manager-role-bindings.yaml
kubectl apply -f openstack-cloud-controller-manager-ds.yaml
```

Wait until the openstack daemon set has the status of **Running** with the following command:
```
watch kubectl get pods -n kube-system
```

## Configuring CSI Cinder Driver

Now you need to deploy Controller and Node Plugins, for that you need to encode the `cloud.conf` using base64:
```
base64 -w 0 cloud.conf
```

Update `cloud.conf` configuration in `cinder-csi-plugin/csi-secret-cinderplugin.yaml` file by using the result of the above command.

Create the secret with this command:
```
kubectl create -f cinder-csi-plugin/csi-secret-cinderplugin.yaml
```

Once the secret is created, Controller Plugin and Node Plugins can be deployed:
```
kubectl apply -f cinder-csi-plugin/
```

Wait until all pods has the status of **Running** with the following command:
```
watch kubectl get pods -n kube-system
```
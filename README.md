# kind-k8spin

## Project Overview

The project demonstrates how to setup multi-tenant capabilities in your Kubernetes Cluster using K8Spin on KinD Kubernetes cluster.

> [K8Spin](https://github.com/k8spin/k8spin-operator) is the Kubernetes multi-tenant operator.
>
> Visit the [K8Spin documentation](https://github.com/k8spin/k8spin-operator/tree/master/docs) to discover all the power of this operator.

## Install Prerequisite
- Docker
- KinD
- kubectl
- helm

NOTE: Tested with Docker=18.09, Kind=0.8.1, kubernetes=v1.19.0, kubectl=v1.19.0

## Create the setup

Create the kubernetes cluster using KinD

`$ make up`

Access the kubernetes cluster

```
$ kubectl cluster-info --context kind-k8spin-demo
$ kubectl get po --all-namespaces
```

Install the k8spin along with its dependencies into kubernetes cluster

`$ make install`

Verify the installation

```
$ kubectl get po -l control-plane=controller-manager -n kbcnat-system
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
kbcnat-system        kbcnat-controller-manager-594967764c-d59vr   2/2     Running   0          13s

$ kubectl logs -l control-plane=controller-manager -n kbcnat-system -c manager -f
```

## Test the k8spin operator multi-tenant capabilities
Now you are ready to use the operator

```bash
$ kubectl apply -f examples/org-1.yaml
organization.k8spin.cloud/example created
$ kubectl apply -f examples/tenant-1.yaml
tenant.k8spin.cloud/crm created
$ kubectl apply -f examples/space-1.yaml
space.k8spin.cloud/dev created
```

As cluster-admin check organizations:

```bash
$ kubectl get org
NAME      AGE
example   86s
```

If you have installed the [K8Spin kubectl plugin](docs/kubectl-plugin.md):

```bash
$ kubectl k8spin get org
Name                CPU                 Memory
example             10                  10Gi
```

As `example` organization admin get available tenants:

```bash
kubectl get tenants -n org-example --as Angel --as-group "K8Spin.cloud"
NAME   AGE
crm    7m31s
```

As `crm` tenant admin get spaces:

```bash
$ kubectl get spaces -n org-example-tenant-crm --as Angel --as-group "K8Spin.cloud"
NAME   AGE
dev    9m24s
```

Run a workload in the dev space:

```bash
$ kubectl run nginx --image nginxinc/nginx-unprivileged --replicas=2 -n org-example-tenant-crm-space-dev --as Angel --as-group "K8Spin.cloud"
pod/nginx created
```

Discover workloads in the dev space as space viewer:

```bash
$ kubectl get pods -n org-example-tenant-crm-space-dev --as Pau
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          66s

## Teardown the setup
Remove the k8spin along with its dependencies the kubernetes cluster

`$ make uninstall`

Delete the Cluster with Kind

`$ make down`
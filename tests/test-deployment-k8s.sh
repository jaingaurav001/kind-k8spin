#!/bin/bash
#
# Make sure the Kind local registry works as expected.

set -ex

# build image
docker build -t helloworld:latest .

# tag and push the image
docker tag helloworld:latest localhost:5000/helloworld:0.1.0
docker push localhost:5000/helloworld:0.1.0

# test k8s manifest
kubectl create -f ./deploy/pod.yaml
kubectl create -f ./deploy/service.yaml
kubectl wait --for=condition=ready pod/helloworld --timeout=60s
export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services helloworld)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
curl http://$NODE_IP:$NODE_PORT

# cleanup
kubectl delete -f ./deploy/pod.yaml
kubectl delete -f ./deploy/service.yaml

#!/bin/bash
#
# Make sure the Kind local registry works as expected.

set -ex

# build image
docker build -t helloworld:latest .

# tag and push the image
docker tag helloworld:latest localhost:5000/helloworld:0.1.0
docker push localhost:5000/helloworld:0.1.0

# package chart
helm package ./helloworld-chart

# test chart
helm install helloworld helloworld-chart-0.1.0.tgz
helm ls

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services helloworld-helloworld-chart)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
kubectl wait --for=condition=available deployment helloworld-helloworld-chart --timeout=120s
curl http://$NODE_IP:$NODE_PORT

# cleanup
helm delete helloworld
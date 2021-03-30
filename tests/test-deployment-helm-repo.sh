#!/bin/bash
#
# Make sure the Kind local container and chart repo works as expected.

set -ex

# add the repo to helm with:
helm repo add chartmuseum-demo http://localhost/

# list the repositories
helm repo list

# build image
docker build -t helloworld:latest .

# tag and push the image
docker tag helloworld:latest localhost:5000/helloworld:0.1.0
docker push localhost:5000/helloworld:0.1.0

# package chart
helm package ./helloworld-chart

# add chart to the repositories
curl --data-binary "@helloworld-chart-0.1.0.tgz" http://localhost/api/charts

# update the repo with:
helm repo update

# list the available packages on the repository:
helm search repo chartmuseum-demo

# install our package from the chartmuseum repo:
helm install helloworld chartmuseum-demo/helloworld-chart

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services helloworld-helloworld-chart)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
kubectl wait --for=condition=available deployment helloworld-helloworld-chart --timeout=120s
curl http://$NODE_IP:$NODE_PORT

# cleanup
helm delete helloworld
helm repo remove chartmuseum-demo
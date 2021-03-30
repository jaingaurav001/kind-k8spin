#!/bin/bash
#
# Make sure the local registry works as expected.

set -ex

# build image
docker build -t helloworld:latest .

# test image
docker run --rm -d -p 8080:8080 --name helloworld helloworld:latest
curl localhost:8080

# cleanup
docker stop helloworld

# tag and push the image
docker tag helloworld:latest localhost:5000/helloworld:0.1.0
docker push localhost:5000/helloworld:0.1.0

# test image
docker run --rm -d -p 8080:8080 --name helloworld localhost:5000/helloworld:0.1.0
curl localhost:8080

# cleanup
docker stop helloworld

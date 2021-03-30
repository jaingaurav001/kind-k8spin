#!/bin/bash
#

set -ex

# build image
docker build -t helloworld:latest .

# test image
docker run --rm -d -p 8080:8080 --name helloworld helloworld:latest
curl localhost:8080

# cleanup
docker stop helloworld

#!/bin/sh -x

docker stop csvm
docker rm csvm
docker run -itd \
  --name csvm \
  --hostname csvm \
  --privileged \
  --security-opt seccomp=unconfined \
  --security-opt apparmor=unconfined \
  --tmpfs /tmp \
  --tmpfs /run \
  -v /lib/modules:/lib/modules:ro \
  -v csvm-storage:/var \
  csvm 

# docker run -itd registry.cncfstack.com/docker.io/library/nginx:1.17.2
#!/bin/bash

cd ~
docker stop csvm
docker rm csvm
docker volume rm csvm-storage
docker run -itd \
  --name csvm \
  --hostname csvm \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v csvm-storage:/var \
  --pull always \
  registry.cncfstack.com/cncfstack/csvm:v0.1.2-bookworm
sleep 3
docker logs  csvm
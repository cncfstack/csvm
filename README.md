# CSVM（CncfStack Virtual Machine）

csvm 是一个基于容器模拟的虚拟机，基于 docker 容器实现。


docker build -t csvm .
docker stop csvm ; docker rm csvm ; docker run -itd --name csvm --privileged csvm

#!/bin/bash
mypath=`realpath $0`
cd `dirname $mypath`

docker pull $(cat AMPDockerFile | grep FROM | cut -f 2 -d ' ')
./buildDockerBase
yes | docker container prune
yes | docker image prune -a
yes | docker volume prune
exit


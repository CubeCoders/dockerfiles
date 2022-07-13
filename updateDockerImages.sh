#!/bin/bash
mypath=`realpath $0`
cd `dirname $mypath`

docker pull $(cat AMPDockerFile | grep FROM | cut -f 2 -d ' ')
./buildDockerBase.sh
exit


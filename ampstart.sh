#!/bin/bash

echo "[Info] AMPStart for Docker - v22.12.1"

if [ -z "${AMPUSERID}" ]; then
  echo "[Info] This docker image cannot be used directly by itself - it must be started by ampinstmgr"
  exit 100
fi

#Check if the AMP user already exists
getent passwd amp &> /dev/null

if [ "$?" == "0" ]; then
    echo "[Info] AMP user already exists, continuing..."
else
    echo "[Info] Performing first-time container setup..."
    groupadd -r -g $AMPGROUPID amp > /dev/null
    useradd -m -d /home/amp -s /bin/bash -c "AMP Process User" -u $AMPUSERID -g $AMPGROUPID amp > /dev/null
    touch /home/amp/.gitconfig
    chown -R amp:amp /home/amp 2> /dev/null
    usermod -aG tty amp
    chmod +x /AMP/AMP_Linux_x86_64
    echo "[Info] Container setup complete."
fi

ARGS=$@
exec su -l -c "ampinstmgr --sync-certs; cd /AMP; HOME=/home/amp /AMP/AMP_Linux_x86_64 ${ARGS}; exit $?" -- amp
exit $?

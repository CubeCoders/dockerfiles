#!/bin/bash

echo "[Info] AMPStart for Docker - v23.07.2"

if [ -z "${AMPUSERID}" ]; then
  echo "[Info] This docker image cannot be used directly by itself - it must be started by ampinstmgr"
  exit 100
fi

# Check if the AMP user already exists
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

REQUIRED_DEPS="$AMP_CONTAINER_DEPS"

if [ -n "$REQUIRED_DEPS" ]; then
  echo "[Info] Installing dependencies..."
  apt-get update
  apt-get install -y ${REQUIRED_DEPS}

  apt-get clean
  rm -rf /var/lib/apt/lists/*
  echo "[Info] Installation complete."
else
  echo "[Info] No dependencies to install."
fi

export AMPHOSTPLATFORM
export AMP_CONTAINER
export AMPMEMORYLIMIT

ARGS=$@
exec su -l -w AMPHOSTPLATFORM,AMP_CONTAINER,AMPMEMORYLIMIT -c "ampinstmgr --sync-certs; cd /AMP; HOME=/home/amp /AMP/AMP_Linux_x86_64 ${ARGS}; exit $?" -- amp
exit $?

#!/bin/bash

echo "[Info] AMPStart for Docker"

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

if [ -f "$INSTALLED_DEPS_FILE" ]; then
  INSTALLED_DEPS=$(jq -r '.[]' $INSTALLED_DEPS_FILE)
else
  INSTALLED_DEPS=""
  echo "[]" > $INSTALLED_DEPS_FILE
fi

REQUIRED_DEPS=$(echo $AMP_CONTAINER_DEPS | jq -r '.[]')

DEPS_TO_INSTALL=()
for DEP in $REQUIRED_DEPS; do
  if ! [[ $INSTALLED_DEPS =~ $DEP ]]; then
    DEPS_TO_INSTALL+=($DEP)
  fi
done

if [ ${#DEPS_TO_INSTALL[@]} -ne 0 ]; then
  echo "[Info] Installing dependencies..."
  apt-get update
  apt-get install --allow-downgrades -y ${DEPS_TO_INSTALL[@]}

#  for DEP in ${DEPS_TO_INSTALL[@]}; do
#    jq --arg dep "$DEP" '. += [$dep]' $INSTALLED_DEPS_FILE > temp && mv temp $INSTALLED_DEPS_FILE
#  done

  apt-get clean
  rm -rf /var/lib/apt/lists/*
  echo "[Info] Installation complete."
else
  echo "[Info] No missing dependencies to install."
fi

if [ -n "$AMP_MOUNTPOINTS" ]; then
  echo "[Info] Updating mountpoint permissions..."
  IFS=':' read -r -a dirs <<< "$AMP_MOUNTPOINTS"

  for dir in "${dirs[@]}"; do
    echo "[Info] - Updating $dir..."
    chown -R amp:amp "$dir"
  done
fi

export AMPHOSTPLATFORM
export AMP_CONTAINER
export AMPMEMORYLIMIT
export AMPSWAPLIMIT
export AMPCONTAINERCPUS
export AMP_CONTAINER_HOST_NETWORK
#export AMP_SHARED_INSTALL
#export DOTNET_GCHeapHardLimit=0x10000000

ARGS=$@
exec su -l -w AMPHOSTPLATFORM,AMP_CONTAINER,AMPMEMORYLIMIT,AMP_CONTAINER_HOST_NETWORK,AMPSWAPLIMIT,AMPCONTAINERCPUS,LANG,LANGUAGE,LC_ALL -c "cd /AMP; HOME=/home/amp /AMP/AMP_Linux_x86_64 ${ARGS}; exit $?" -- amp
exit $?


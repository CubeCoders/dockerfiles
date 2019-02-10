# AMP Standalone Dockerfile

FROM debian:9.6-slim

EXPOSE 8080-8180
EXPOSE 5678-5688
EXPOSE 7777-7877
EXPOSE 21025-21125
EXPOSE 25565-25665
EXPOSE 27015-27115
EXPOSE 28015-28115
EXPOSE 34197-34297

ENV AMPUSER=admin
ENV AMPPASSWORD=changeme123
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /usr/share/man/man1 && \
    useradd -d /home/AMP -m AMP -s /bin/bash && \
    apt-get update && \
    apt-get install -y \
        locales \
        cron \
        lib32gcc1 \
        coreutils \
        inetutils-ping \
        tmux \
        socat \
        unzip \
        wget \
        git \
        screen \
        procps \
        lib32gcc1 \
        lib32stdc++6 \
        software-properties-common \
        dirmngr \
        apt-transport-https \
        openjdk-8-jre-headless \
        software-properties-common \
        dirmngr \
        apt-transport-https && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    apt-key adv --fetch-keys http://repo.cubecoders.com/archive.key && \
    apt-add-repository "deb http://repo.cubecoders.com/ debian/" && \
    apt-get update && \
    apt-get install ampinstmgr --install-suggests && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    su -l AMP -c '(crontab -l ; echo "@reboot ampinstmgr -b")| crontab -' && \
    mkdir -p /data && \
    touch /data/empty && \
    chown AMP:AMP /data && \
    ln -s /data /home/AMP/.ampdata

VOLUME ["/data"]

ENTRYPOINT (su -l AMP -c "ampinstmgr quick ${AMPUSER} ${AMPPASSWORD} 0.0.0.0 8080"; su -l AMP -c "ampinstmgr view ADS true") || bash || tail -f /dev/null

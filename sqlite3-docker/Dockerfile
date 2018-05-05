FROM resin/rpi-raspbian
MAINTAINER Marc Szymanski "marc.szymanski@mac.com"

LABEL version="latest"

RUN apt-get update 
RUN apt-get install -y --no-install-recommends apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install sqlite3
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/db

WORKDIR /root/db

ENTRYPOINT [ "sqlite3" ]


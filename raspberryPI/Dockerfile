ARG NODE_VERSION=6
FROM hypriot/rpi-node:${NODE_VERSION}

# add support for gpio library
RUN apt-get update
RUN apt-get install python-rpi.gpio

# Home directory for application source code.
RUN mkdir -p /usr/src/iGrowFlora

WORKDIR /usr/src/iGrowFlora

# Add node-red user so we aren't running as root.
#RUN useradd --home-dir /usr/src/node-red --no-create-home iGrowFlora \
#    && chown -R iGrowFlora:iGrowFlora /usr/src/iGrowFlora

#USER iGrowFlora

COPY src/mqttValveControllerClient.js /usr/src/iGrowFlora
COPY src/package.json /usr/src/iGrowFlora
COPY src/mqttValveControllerClient.js /usr/src/iGrowFlora
RUN mkdir /usr/src/iGrowFlora/config
COPY src/config/ /usr/src/iGrowFlora/config/

# package.json contains NPM module and node dependencies
RUN npm install

CMD ["npm", "start"]

#!/bin/sh

SERVER="iGrowFlora-MQTTServer.sh"
CLIENT="iGrowFlora-ValveController.sh"

echo installing iGrowFlora...
echo adding daemons to runlevel...

cp $PWD/runlevel/$SERVER /etc/init.d
update-rc.d $SERVER defaults

cp $PWD/runlevel/$CLIENT /etc/init.d
update-rc.d $CLIENT defaults







var mqtt = require('mqtt');     // for the MQTT-client
var config = require('config'); // for simple configuration
var schedule = require('node-schedule');

var client = mqtt.connect('mqtt://' + config.get('MQTT.server'));
var controller = config.get("controller");

var cronTab = config.get("cronTab");


function irrigate(valves, volume) {
    for (var item in valves) {
        var msg = {
            valve: item,
            volume: volume
        }
        client.publish(controller.topic + "/" + controller.volume.topic,
            JSON.stringify(msg),
            function (err) {
                console.log("error: " + JSON.stringify(msg));
            }
        );
    }
}

client.on('connect', function () {
    console.log("connected...");
    client.publish('presence', 'Hello mqtt');

    for (var item in cronTab) {
        if (cronTab[item].hasOwnProperty('cronJob')) {

            var j = schedule.scheduleJob(cronTab[item].cronJob,
                function () {
                    // TODO: transform date string to date object
                    irrigate(cronTab[item].valve, cronTab[item].volume);
                    console.log("set cronJob: " + cronTab[item])
                });

        }
    }

})


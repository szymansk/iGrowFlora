var mqtt = require('mqtt');     // for the MQTT-client
var config = require('config'); // for simple configuration
var schedule = require('node-schedule');

var client = mqtt.connect('mqtt://' + config.get('MQTT.server'));
var controller = config.get("controller");

var cronTab = config.get("cronTab");


function irrigate(valve, volume) {

    var dateTime = require('node-datetime');
    var dt = dateTime.create();
    var formatted = dt.format('Y-m-d H:M:S');

    var msg = {
        valve: valve,
        volume: volume,
        timeStamp: formatted
    }

    console.log(formatted + ": " + JSON.stringify(msg));

    client.publish(controller.topic + "/" + controller.volume.topic,
        JSON.stringify(msg),
        { qos: 2 },
        function (err) {
            console.log(JSON.stringify(msg));
        }
    );

}

client.on('connect', function () {
    console.log("connected...");
    client.publish('presence', 'Hello mqtt');

    for (var item in cronTab) {
        console.log(cronTab[item])
        if (cronTab[item].hasOwnProperty('cronJob')) {

            var j = schedule.scheduleJob(cronTab[item].cronJob,
                irrigate.bind(null, cronTab[item].valve, cronTab[item].volume)
            );
        }
    }

})


var mqtt = require('mqtt');     // for the MQTT-client
var onoff = require('onoff');   // for turning on/off the valves
var config = require('config'); // for simple configuration

var client = mqtt.connect('mqtt://' + config.get('MQTT.server'));
var Gpio = onoff.Gpio;

var valves = config.get("valves");
var controller = config.get("controller");
var sensor = config.get("sensor");

for (var item in valves) {
  if (valves[item].hasOwnProperty('GPIO')) {
    console.log(valves[item].GPIO)
    if (valves[item].GPIO != 9999) {
      valves[item].ctr = new Gpio(valves[item].GPIO, 'out');
    } else {
      console.log('MOCKSENSOR: ' + valves[item].sensorID)
    }
    console.log('register valve ' + item + ' to GPIO ' + valves[item].GPIO + ' and sensor ' + valves[item].sensorID);
  }
}
var soilMoistureControl = config.get('controller');

client.on('connect', function () {
  console.log("connected...");
  client.subscribe(sensor.topic + "/" + sensor.moisture.topic);
  client.publish('presence', 'Hello mqtt');
})

client.on('message', function (topic, message) {

  // soil moisture control
  if (topic == sensor.topic + "/" + sensor.moisture.topic) {
    var jsonContent = JSON.parse(message);

    //console.log(jsonContent);

    for (var item in valves) {
      if (valves[item].hasOwnProperty('sensorID') &&
        jsonContent.ID == valves[item].sensorID) {
       
        var valvestate = -1;
        var thresholdt = controller.threshold;
       
        if (valves[item].hasOwnProperty('threshold')) {
          threshold = valves[item].threshold;
        }

        if (item != "MOCKUP") {
          if (jsonContent.sensorReadings.soilMoisture >= threshold &&
            jsonContent.sensorReadings.soilMoisture < 1024) {

            client.publish(valves.topic + "/" + item, 'open',
              function (err) {
                //console.log("#valve open")
              });
            valves[item].ctr.write(valves.open,
              function (err) {
                // console.log("valve open")
              });

            //close valve after a given time
            /*settimeout(function () {
              valves[item].ctr.write(valves.close,  
                function(err) { 
                  //console.log("valve close");
              })     
              valvestate = valves.close;
            }, controller.timeout);*/
            valvestate = valves.open;
          } else {
            client.publish(valves.topic + "/" + item, 'close',
              function (err) {
                //console.log("valve close");
              });
            valves[item].ctr.write(valves.close,
              function (err) {
                //console.log("valve close");
              })
            valvestate = valves.close;
          }
        }
        console.log("%d %s %d %d %d",
          jsonContent.timeStamp.sec,
          item,
          valves[item].sensorID,
          jsonContent.sensorReadings.soilMoisture,
          valvestate,
          threshold)
      }
    }
  }
})



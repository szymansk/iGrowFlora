var mqtt = require('mqtt');     // for the MQTT-client
var onoff = require('onoff');   // for turning on/off the valves
var config = require('config'); // for simple configuration

var client = mqtt.connect('mqtt://' + config.get('MQTT.server'), { "username":config.get('MQTT.username'), "password":config.get('MQTT.password')});
var Gpio = onoff.Gpio;

var valves = config.get("valves");
var controller = config.get("controller");
var sensor = config.get("sensor");

var mean_value = [0,0,0,0];
var alpha = 0.97

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

function switchValve(valve, state, msg = {
        valve: valve,
        volume: "unknown",
        intervall: "unknown"
      }
) {

  var top =""
  var action = valves.close
  if (state == "open") {
    top = "/opened"
    action = valves.open
  } else {
    top = "/closed"
    action = valves.close   
  }

//  console.log(valve + " " + state)

  try {
    client.publish(valves.topic + top,
      JSON.stringify(msg),
      { qos: 1 },
      function (err) {
      });
  } catch (e) {
    console.log(e);
  }

    //console.log(valve)
  valves[valve].ctr.write(action,
    function (err) {
      //console.log(err)
    })
}

client.on('connect', function () {
  console.log("connected...");
  client.subscribe(sensor.topic + "/#");
  client.subscribe(controller.topic + "/#");
  client.publish('presence', 'Hello mqtt');
})

function handleTimer(msg) {
  switchValve(msg.valve, "open", msg);
  //close valve after specified time
  setTimeout(switchValve, msg.intervall, msg.valve, "close", msg);
}

client.on('message', function (topic, message) {

  //console.log(topic + " " +message)

  var splitTopic = topic.split("/")


  // timer control
  var depth = 0
  if (splitTopic[depth] == controller.topic) {
    depth++
    var jsonContent = JSON.parse(message);

    if (splitTopic[depth] == controller.timer.topic) {

      var msg = {
        valve: jsonContent.valve,
        volume: jsonContent.intervall * controller.volume.milliliterPerMS,
        intervall: jsonContent.intervall
      }

      handleTimer(msg)

    }  // volume control
    else if (splitTopic[depth] == controller.volume.topic) {

      var msg = {
        valve: jsonContent.valve,
        volume: jsonContent.volume,
        intervall: jsonContent.volume / controller.volume.milliliterPerMS
      }

      handleTimer(msg)

    }
  } // soil moisture control
  else if (splitTopic[depth] = sensor.topic) {
      var jsonContent = JSON.parse(message);
      
      depth++
    if (splitTopic[depth] == sensor.moisture.topic) {

      for (var item in valves) {
        if (valves[item].hasOwnProperty('sensorID') &&
          valves[item].controller == "moisture" &&
          jsonContent.ID == valves[item].sensorID) {

          var valvestate = -1;
          var threshold = controller.threshold;

          if (valves[item].hasOwnProperty('threshold')) {
            threshold = valves[item].threshold;
          }

          if (item != "MOCKUP") {
//            if (jsonContent.sensorReadings.soilMoisture <= threshold) {
	      if (mean_value[Number(item)] <= threshold) {

              if (valves[item].energySource == "line") {
                  switchValve(Number(item), "open")
              } else {
                var msg = {
                  valve: Number(item),
                  volume: valves[item].volume,
                  intervall: valves[item].volume / controller.volume.milliliterPerMS
                }
                handleTimer(msg)
              }
              valvestate = valves.open;
            } else {
              if (valves[item].energySource == "line") {
                switchValve(Number(item), "close")
                valvestate = valves.close;
              } else {
                //console.log("will be closed by volume control")
              }
            }
          }
	    if ( mean_value[Number(item)] == 0 ) {
		mean_value[Number(item)] = jsonContent.sensorReadings.soilMoisture
	    } else {
		mean_value[Number(item)] = (alpha)*mean_value[Number(item)] + (1-alpha)*jsonContent.sensorReadings.soilMoisture
	    }
          console.log("%d %s %d %d %d %d %d",
            jsonContent.timeStamp.sec,
            item,
            valves[item].sensorID,
            jsonContent.sensorReadings.soilMoisture,
            jsonContent.sensorReadings.temperature,
            jsonContent.voltage,
            valvestate,
		      threshold,
		      mean_value[Number(item)])
        }
      }
    }
  }
})



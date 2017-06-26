var mosca = require('mosca')
var config = require('config')


var moscaSettings = config.MQTT.moscaSettings;

moscaSettings.persistence.factory = mosca.persistence.Mongo;
//console.log(moscaSettings)

var server = new mosca.Server(moscaSettings);

server.on('ready', setup);

server.on('clientConnected', function(client) {
	//console.log('client connected', client.id);		
});

// fired when a message is received
server.on('published', function(packet, client) {
  //console.log('Published %s %s', packet.topic, packet.payload.toString('utf8'));
});

// fired when the mqtt server is ready
function setup() {
  console.log('Mosca server is up and running')
}


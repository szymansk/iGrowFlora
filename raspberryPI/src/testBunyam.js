var mosca = require("mosca");
var server = new mosca.Server({
  http: {
    port: 3001,
    bundle: true,
    static: './'
  }
});

server.on('ready', setup);	//on init it fires up setup()

// fired when the mqtt server is ready
function setup() {
  console.log('Mosca server is up and running')
}

// fired when a message is published
server.on('published', function(packet, client) {
console.log('Published', packet);
console.log('Client', client);
});
// fired when a client connects
server.on('clientConnected', function(client) {
console.log('Client Connected:', client.id);
});

// fired when a client disconnects
server.on('clientDisconnected', function(client) {
console.log('Client Disconnected:', client.id);
});
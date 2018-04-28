-- file : application.lua
local module = {}  
--local chirp = require("chirp")

m = nil

local mqtt_data = {}
mqtt_data.ID = nil
mqtt_data.timeStamp = {}
mqtt_data.timeStamp.sec = 0
mqtt_data.timeStamp.usec = 0
mqtt_data.sensorReadings = {}

-- Sends a simple ping to the broker
local function send_ping()  
    m:publish(config.ENDPOINT .. "ping","id=" .. config.ID,0,0)
end

-- Sends a soil moisture value to the broker
local function send_soilMoisture() 
    mqtt_data.ID = config.ID;

    num_meas = config.numMeas --todo make configurable
    mqtt_data.sensorReadings.soilMoisture = 0
    mqtt_data.sensorReadings.temperature = 0
    mqtt_data.voltage = 0

    for i=1,num_meas do
        mqtt_data.sensorReadings.soilMoisture = mqtt_data.sensorReadings.soilMoisture + chirp.read_moisture()
        mqtt_data.sensorReadings.temperature  = mqtt_data.sensorReadings.temperature + chirp.read_temperature()
        mqtt_data.voltage                     = mqtt_data.voltage + adc.readvdd33()               
    end
    mqtt_data.sensorReadings.soilMoisture = mqtt_data.sensorReadings.soilMoisture/num_meas;
    mqtt_data.sensorReadings.temperature  = mqtt_data.sensorReadings.temperature/num_meas;
    mqtt_data.voltage                     = mqtt_data.voltage/num_meas;
            
    mqtt_data.timeStamp.sec, mqtt_data.timeStamp.usec = rtctime.get();
    
    dat = sjson.encode(mqtt_data);    
    print(dat)
    m:publish(config.ENDPOINT .. "soilMoisture/" .. config.ID, dat,0,0)
end

-- Sends my id to the broker for registration
local function register_myself()  
    m:subscribe("configuration/nodemcu",1,
        function(conn)
            print("Successfully subscribed to data endpoint")
        end)
end

local function handle_connection_error(errno)
--syslogclient = net.createUDPSocket()
--syslogclient:send(514, config.HOST, "<133>Hallo")

    if errno == mqtt.CONN_FAIL_SERVER_NOT_FOUND then
        return "There is no broker listening at the specified IP Address and Port"
    elseif errno == mqtt.CONN_FAIL_NOT_A_CONNACK_MSG then
        return "The response from the broker was not a CONNACK as required by the protocol"
    elseif errno ==mqtt.CONN_FAIL_DNS then
        return "DNS Lookup failed"
    elseif errno ==mqtt.CONN_FAIL_TIMEOUT_RECEIVING then
        return "Timeout waiting for a CONNACK from the broker"
    elseif errno ==mqtt.CONN_FAIL_TIMEOUT_SENDING then
        return "Timeout trying to send the Connect message"
    elseif errno ==mqtt.CONNACK_ACCEPTED then
        return "No errors. Note: This will not trigger a failure callback."
    elseif errno ==mqtt.CONNACK_REFUSED_PROTOCOL_VER then
        return " The broker is not a 3.1.1 MQTT broker."
    elseif errno ==mqtt.CONNACK_REFUSED_ID_REJECTED then
        return "The specified ClientID was rejected by the broker. (See mqtt.Client())"
    elseif errno ==mqtt.CONNACK_REFUSED_SERVER_UNAVAILABLE then
        return "The server is unavailable."
    elseif errno ==mqtt.CONNACK_REFUSED_BAD_USER_OR_PASS then
        return "The broker refused the specified username or password."
    elseif errno ==mqtt.CONNACK_REFUSED_NOT_AUTHORIZED then
        return "The username is not authorized."
    else 
        return errno
    end
end


local function subscriptionHandler(conn, topic, data) 
 
    if topic == "configuration/nodemcu" then
         --dat = sjson.decode(data)
         print(topic .. ": " .. data)

         --val = sjson.encode(data)
         
        -- print(dat)
    elseif data ~= nil then
      print(topic .. ": " .. data)
    end

      
end


local function pub_off() 
    tmr.stop(6); -- turn auto reconnection timeour off
end

local function goDsleep() 

    dat = {}
    dat.ID = config.ID
    dat.deepSleepUS = config.deepSleepUS
    dat.timeStamp = {}
    dat.timeStamp.sec = 0
    dat.timeStamp.usec = 0

    dat.timeStamp.sec, dat.timeStamp.usec = rtctime.get();
    
    m:publish(config.ENDPOINT .. "soilMoisture/deepSleep", sjson.encode(dat),0,0)
    rtctime.dsleep(config.deepSleepUS)
end

local function pub_on()

    if not config.deepSleep then
        tmr.alarm(6, config.repeatMeasEveryMS, tmr.ALARM_AUTO, send_soilMoisture ) -- turn pub on
    else
        tmr.alarm(6, config.repeatMeasEveryMS, tmr.ALARM_AUTO, send_soilMoisture ) -- turn pub on
       --send_soilMoisture()
        tmr.alarm(5, config.repeatMeasEveryMS * config.measBeforeDS + config.repeatMeasEveryMS/2, tmr.ALARM_SINGLE, goDsleep ) -- turn pub on
    end 
end

local function init(con) 
    tmr.stop(5); -- turn auto reconnection timeour off
    register_myself();  -- register to topics
    -- And then pings each 1000 milliseconds
    pub_off();
    pub_on();
end

local function reconnect (client)
    pub_off(); -- turn pub off
    client:close();
    client:connect(config.HOST, config.PORT, 0, 0, 
        init, -- sub and fire pub
        function(client, reason)
            print("no connection to with reason " .. handle_connection_error(reason));
            tmr.alarm(5, 10*1000, tmr.ALARM_AUTO, -- enable auto reconnection
                function () 
                    reconnect(client);
                end)
         end)
end
    
local function mqtt_start()  
    m = mqtt.Client(config.ID, 120, config.mqtt_cfg.user, config.mqtt_cfg.password)

    --config.ID = node.chipid()
    --m = mqtt.Client(config.ID, 120, 'pi', 'vulam,.')
    -- register message callback beforehand
    m:on("message", subscriptionHandler)    
    m:on("offline", reconnect)


    print("====================================");
    print("Connecting MQTT:");
    print("ID:   " .. config.ID);
    print("HOST: " .. config.HOST);
    print("PORT: " .. config.PORT);
    print("USER: " .. config.mqtt_cfg.user);
    print("PASS: " .. config.mqtt_cfg.password);
    
    
    -- Connect to broker
   m:connect(config.HOST, config.PORT, 0, 0, 
        init,
        function(client, reason)
            print("no connection to with reason " .. handle_connection_error(reason));
            reconnect(client); -- auto reconnect
        end) 
end

function module.start()  
  mqtt_start()
end

return module  

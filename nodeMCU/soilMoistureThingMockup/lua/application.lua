-- file : application.lua
local module = {}  
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

    num_meas = 100 --todo make configurable
    meas = 0
    found = 0
    for i=1,num_meas do
        meas = meas + adc.read(0);
        found = i
    end
    mqtt_data.sensorReadings.soilMoisture = meas/num_meas;
    
    dat = sjson.encode(mqtt_data);    
    print(dat);
    
    mqtt_data.timeStamp.sec, mqtt_data.timeStamp.usec = rtctime.get();
    m:publish(config.ENDPOINT .. "soilMoisture", dat,0,0)
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
    end
end


local function connect_and_fire() 
    m:close();
    m:connect(config.HOST, config.PORT, 0, 0, 
        function(con) 
            register_myself()   
            send_soilMoisture();
            --tmr.delay(10); -- waiting for new config data
            --m:close();
        end,
        function(client, reason)
            print("no connection to with reason " .. handle_connection_error(reason));
        end) 
   
end

local function subscriptionHandler(conn, topic, data) 
 
    if topic == "configuration/nodemcu" then
         --dat = sjson.decode(data)
         print(topic .. ": " .. data)
        -- print(dat)
    elseif data ~= nil then
      print(topic .. ": " .. data)
    end

      
end


local function pub_off() 
    tmr.stop(6); -- turn auto reconnection timeour off
end

local function pub_on()
    tmr.alarm(6, 1000, tmr.ALARM_AUTO, send_soilMoisture) -- turn pub on
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
    m = mqtt.Client(config.ID, 120)
    -- register message callback beforehand
    m:on("message", subscriptionHandler)    
    m:on("offline", reconnect)

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

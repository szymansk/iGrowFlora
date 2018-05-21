-- file: setup.lua
local module = {}

-- setup SNTP for the RTC timestamp
local function SNTP_start() 
    -- Single shot sync time with a server on the local network.
    
    print(config.SNTP)
    sntp.sync(config.SNTP,
        function(sec, usec, server, info)
            rtctime.set(sec, usec);
            
            local tm = rtctime.epoch2cal(rtctime.get())
            print('SNTP sync', server)
            print(string.format("UTC: %04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
            
            app.start()
        end,
        function(errno, errinfo)
            print('STNP error: ' .. errno .."/" .. errinfo)
        end,
        true --autorepeat
    )
end

local function wifi_wait_ip()  
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is ".. wifi.sta.getip())
    print("====================================")

    print("Configuring SNTP and RTC:");
    SNTP_start()
  end
end

local function wifi_start(list_aps)  
    if list_aps then
        for key,value in pairs(list_aps) do
            if config.station_cfg.ssid == key then

                local sec_key = secret.read_key()
                config.station_cfg.pwd = crypto.decrypt(secret.encryption, sec_key, config.station_cfg.secret)
                wifi.sta.config(config.station_cfg)
                config.station_cfg.pwd = ""
                wifi.setmode(wifi.STATION);
                
                print("Connecting to " .. key .. " ... ")
                --config.SSID = nil  -- can save memory
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("Error getting AP list")
    end
end

-- configure adc
local function adc_start()
    if adc.force_init_mode(adc.INIT_VDD33)
    then
        node.restart()
        return -- don't bother continuing, the restart is scheduled
    end
end

function module.read_config()
    local files = file.list()
    if files[config.config_file] then
        print("Config file exists")
    else
        print("Config file does NOT exist")
        return nil        
    end
    local config_file = file.open(config.config_file,"r")
    local conf = config_file.read()
    config_file.close()
    collectgarbage()
    
    print(conf)
    if (conf == nil) then
        print ("cannot read config file")
        return nil
    end
    local var = sjson.decode(conf)

    collectgarbage()
    return var

end

function module.write_config()
    local files = file.list()
    if files[config.config_file] then
        print("Config file exists")   
    else
        print("Creating config file")
    end

    print("writing config to file")
    local conf_file = file.open(config.config_file, "w+")
    conf_file.write(string.gsub(sjson.encode(config),",",",\n"))
    conf_file.close()
    collectgarbage()
    
end

function module.start()  
    local val = module.read_config();
    if val ~= nil then
        config = val
    else
        module.write_config();
    end

    ------encrypt plain password------
    if (config.mqtt_cfg.password ~= "" ) then
        print("replace mqtt pass")
        secret.key = secret.read_key()
        config.mqtt_cfg.secret = crypto.encrypt(secret.encryption, secret.key, config.mqtt_cfg.password)
    
        local pass = crypto.decrypt(secret.encryption, secret.key, config.mqtt_cfg.secret)
        print("encrypted " .. config.mqtt_cfg.secret .. " : " .. pass)
        config.mqtt_cfg.password = ""
        module.write_config();
    end
    
    if (config.station_cfg.pwd ~= "" ) then
        print("replace wifi pass ")
        secret.key = secret.read_key()
        config.station_cfg.secret = crypto.encrypt(secret.encryption, secret.key, config.station_cfg.pwd)
    
        local pass = crypto.decrypt(secret.encryption, secret.key, config.station_cfg.secret)
        print("encrypted " .. config.station_cfg.secret .. " : " .. pass)
        config.station_cfg.pwd = ""
        module.write_config();
    end
    ------------

    -- set chipid
    if (config.ID ~= node.chipid()) then
        config.ID = node.chipid()
        module.write_config()
        print("renew ID to " .. config.ID )
    end

    print("Configuring Wifi ...");
    wifi.setmode(wifi.STATION);
    wifi.sta.getap(wifi_start);
    print("Configuring adc as battery monitor...");
    adc_start();
    chirp.setup(config.chirp.sda, config.chirp.scl)
end

return module  

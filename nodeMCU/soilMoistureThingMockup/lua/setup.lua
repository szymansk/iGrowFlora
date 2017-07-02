-- file: setup.lua
local module = {}

-- setup SNTP for the RTC timestamp
local function SNTP_start() 
    -- Single shot sync time with a server on the local network.
    _, reset_reason = node.bootreason()
    if reset_reason == 5 then 
        print("Wake-up from deep sleep rtc should be fine.") 
        rtc_tm = rtctime.get()
        tm = rtctime.epoch2cal(rtc_tm)
        print(string.format("UTC: %04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
        if rtc_tm ~= 0 then return end-- we do not need to contact the NTP server
    end
    
    print(config.SNTP)
    sntp.sync(config.SNTP,
        function(sec, usec, server, info)
            rtctime.set(sec, usec);
            
            tm = rtctime.epoch2cal(rtctime.get())
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
    print("IP is "..wifi.sta.getip())
    print("====================================")

    print("Configuring SNTP and RTC:");
    SNTP_start()
  end
end

local function wifi_start(list_aps)  
    if list_aps then
        for key,value in pairs(list_aps) do
            if config.station_cfg.ssid == key then
                wifi.sta.config(config.station_cfg)
                wifi.setmode(wifi.STATION);
                --wifi.sta.config(key,config.SSID[key])
                --wifi.sta.connect()
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
    files = file.list()
    if files["config.json"] then
        print("Config file exists")
    else
        print("Config file does NOT exist")
        return nil        
    end
    config_file = file.open("config.json","r")
    conf = config_file.read()

    print(conf)

    var = sjson.decode(conf)
    config_file.close()
    
    return var

end

function module.write_config()
    files = file.list()
    if files[config.config_file] then
        print("Config file exists")
    else
        print("Config file does NOT exist")
        return -1        
    end

    conf_file = file.open(config.config_file, "w+")

    conf_file.write(string.gsub(sjson.encode(config),",",",\n"))

    conf_file.close()
    
end

function module.start()  
  val = module.read_config();
  if val ~= nil then
    config = val
  end

  print("Configuring Wifi ...");
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start);
  print("Configuring adc as battery monitor...");
  adc_start();
  chirp.setup(config.chirp.sda, config.chirp.scl)
end

return module  

-- file: setup.lua
local module = {}

-- setup SNTP for the RTC timestamp
local function SNTP_start() 
    -- Single shot sync time with a server on the local network.
    print(config.SNTP)
    sntp.sync(config.SNTP,
        function(sec, usec, server, info)
            rtctime.set(sec, usec);
            print('SNTP sync', sec, usec, server)
            
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
    if adc.force_init_mode(adc.INIT_ADC)
    then
        node.restart()
        return -- don't bother continuing, the restart is scheduled
    end
end

function module.start()  
  print("Configuring Wifi ...");
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start);
  print("Configuring adc ...");
  adc_start();
end

return module  

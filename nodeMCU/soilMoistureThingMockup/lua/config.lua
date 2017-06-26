-- file : config.lua
local module = {}
--connect to Access Point (DO save config to flash)

module.station_cfg={}
module.station_cfg.ssid="furzmulde"
module.station_cfg.pwd="eineanderewelt"
module.station_cfg.save=true

module.HOST = "192.168.178.35"  -- raspi
module.PORT = 1883  
module.ID = node.chipid()

module.deppSleepUS = 60*1000*1000 -- usec
module.reconnectTimeoutMS = 60*1000 -- msec
module.repeatMeasEveryMS = 1000 --msec

module.SNTP = {"129.70.132.33", "134.119.8.130", "131.234.137.63", "5.9.80.113"}

module.ENDPOINT = "nodemcu/"  
return module 

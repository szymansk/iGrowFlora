-- file : chirp.lua
local module = {}  

-- connection to nodemcu
local id  = 0 -- always 0

-- chirp! registers
local reg_moisture = 0
local reg_temp     = 5

-- commands
local cmd_reset   = 6

function module.setup(sda, scl)
    -- initialize i2c, set pin1 as sda, set pin2 as scl
    print("setting up i2c for chirp!")
    print("sda: "..sda.." scl: "..scl)
    local speed = i2c.setup(id, sda, scl, i2c.SLOW)
    print("speed: "..speed)
end

function module.chirp_scan()

    local addr = 0

    while addr ~= 128 do
        print("addr " .. addr)
        i2c.start(id)
        local err = i2c.address(id, addr, i2c.TRANSMITTER)
        i2c.stop(id)
        if not err then
            print("addr " .. addr .. ": NACK")
            --return -1
        else 
            print("addr " .. addr .. ": ACK")
            --return addr
        end
        addr = addr + 1;
       tmr.delay(1000)
    end
end

-- user defined function: read from reg_addr content of dev_addr
function read_reg(dev_addr, reg_addr, len)
    i2c.start(id)
    local err = i2c.address(id, dev_addr, i2c.TRANSMITTER)
    if not err then
        print("chirp NAK")
        return -1
    end
    err = i2c.write(id, reg_addr)
    if err ~= 1 then
        print("chirp cannot write")
        return -1
    end
    i2c.stop(id)
    i2c.start(id)
    err = i2c.address(id, dev_addr, i2c.RECEIVER)
    if not err then
        print("chirp cannot read")
        return -1
    end
    local c = i2c.read(id, len)
    i2c.stop(id)
    --print("read: ".. c .. " " .. string.len(c))
    return c
end

-- user defined function: read from reg_addr content of dev_addr
function write_val(dev_addr, val)
    i2c.start(id)
    i2c.address(id, dev_addr, i2c.TRANSMITTER)
    i2c.write(id, val)
    i2c.stop(id)
end
-- To read soil moisture, read 2 bytes from register 0
function module.read_moisture() 
    local val = read_reg(config.chirp.addr, reg_moisture, 2)
    local erg = string.byte(val,2) + string.byte(val,1)*256
    return erg
end

-- not working with rugged version. sensor is covered
-- To read light level, start measurement by writing 3 to the device I2C address, wait for 3 seconds, read 2 bytes from register 4
function module.read_light()
    
end

--To read temperature, read 2 bytes from register 5
function module.read_temperature()
    local val = read_reg(config.chirp.addr, reg_temp, 2)
    local erg = string.byte(val,2) + string.byte(val,1)*256
    return erg
end

-- To reset the sensor, write 6 to the device I2C address.
function module.reset_chirp()
    write_cal(config.chirp.addr, cmd_reset)
end

-- To change the I2C address of the sensor, write a new address (one byte [1..127]) to register 1; the new address will take effect after reset
function module.change_i2c_addr(new_addr)
    reset_chirp()
end

return module

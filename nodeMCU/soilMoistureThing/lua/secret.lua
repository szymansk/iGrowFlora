-- file: secret.lua
local module = {}

module.key_file = "security.key"
module.key = nil;
module.encryption = "AES-CBC"


function module.read_key()
    if key == nil then
        local files = file.list()
        if files[module.key_file] then
            print("key file exists")
        else
            print("key file does NOT exist")
            return nil    
        end
        local key_file = file.open(module.key_file,"r")
        module.key = key_file.read()
    end
    
    print("key : " .. module.key)
    return module.key
end

return module
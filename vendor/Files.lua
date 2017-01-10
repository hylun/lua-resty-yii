--文件上传处理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local len = string.len
local type = type
local match = ngx.re.match
local io_open = io.open

local upload = require "resty.upload" 

local _M = {_VERSION='0.01'}

-- 接收上传文件，保存为savename
function _M.receive(key,savename)
    local chunk_size = 4096  
    local form,err = upload:new(chunk_size) 
    if not form then  
        return nil,err
    end  
    form:set_timeout(10000) -- 10 sec

    local file,filename,filelen = nil,nil,0
    while true do
        local typ, res, err = form:read()  
        if not typ then  
            return nil,err
        end  
        if typ == "header" and res[1] ~= "Content-Type" then
            local ma = match(res[2],'(.+)name="(.+)"(.+)filename="(.+)"(.*)') 
            if savename and ma and ma[2]==key then  
                file = io_open(savename,"w+")  
                if not file then  
                    return nil,'failed to open file '..savename  
                end
                filename = ma[4]  
            end  
        elseif typ == "body" and file then  
            filelen = filelen + len(res)      
            file:write(res)  
        elseif typ == "part_end" and file then  
            file:close()  
            file = nil  
        elseif typ == "eof" then  
            break    
        end  
    end
    if filename then
        return {name=savename,len=filelen,filename=filename},nil
    else
        return nil,'not found upload file for '..key
    end
end 

return _M


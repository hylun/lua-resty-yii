--memchache处理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local require = require

local memcached = require "resty.memcached"

local _M = {
    _VERSION='0.01',
    timeout=1000,
    host = "127.0.0.1",
    port = "11211",
}

function _M.__index(self, key)
    return _M[key] or function(...)
    
        local memc, err = memcached:new()
        if not memc then
            return nil,err
        end

        memc:set_timeout(self.timeout) -- 1 sec

        local ok, err = memc:connect(self.host, self.port)
        if not ok then
            return nil,err
        end
        
        local ok, err = memc[key](memc,...)
        
        memc:set_keepalive(10000, 100) --放回连接池
        
        return ok, err
    end
end

function _M.new(self,config)
    config = config or {}
    return setmetatable(config,self)
end

return _M

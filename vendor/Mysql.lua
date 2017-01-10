--memchache处理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local require = require

local mysql = require "resty.mysql"

local _M = {
    _VERSION='0.01',
    host = "127.0.0.1",
    port = 3306,
    database = "mytest",
    user = "root",
    password = "",
    charset = "utf8", 
    timeout = 1000,
    max_packet_size = 1024 * 1024,
}

_M.__index = _M

function _M.new(self,config)
    config = config or {}
    return setmetatable(config,self)
end

function _M.query(self,... )
    local db, err = mysql:new()
    if not db then return nil,err end

    db:set_timeout(self.timeout) -- 1 sec

    local ok, err, errcode, sqlstate = db:connect{
        host = self.host,
        port = self.port,
        database = self.database,
        user = self.user,
        password = self.password,
        max_packet_size = self.max_packet_size,
    }

    if not ok then return nil,err end

    local ok, err = db:get_reused_times()
    if (not ok or ok==0) and self.charset then 
        db:query('SET NAMES '..self.charset)
    end
    
    local res, err, errcode, sqlstate = db:query(...)
    if not ok then return nil,err end

    -- 放入连接池
    db:set_keepalive(10000, 100)
    
    return res, err
end

return _M


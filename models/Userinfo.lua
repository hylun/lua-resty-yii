--用户模块
--Copyright (C) Yuanlun He.

--[[如果是数据库表格，可以如下：
return require('ActiveRecord'){
    
    tableName = function()
        return 'userinfos'
    end
}
]]

local require = require
local tonumber = tonumber

local util = require("vendor.Util")

local _M = require("vendor.Model"):new{_version='0.0.1'}

local userinfos = {
    {
        id = '100',
        username = 'admin',
        password = 'admin',
    },
    {
        id = '101',
        username = 'demo',
        password = 'demo',
    }
}

function _M.getUserByName(username)
    local user = nil
    for k,v in pairs(userinfos) do
        if v.username==username then
            user = v
        end
    end
    return user
end 

return _M

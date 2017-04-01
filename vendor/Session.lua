--session处理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local require = require
local next = next
local ipairs = ipairs
local sub = string.sub
local find = string.find
local ngx_md5 = ngx.md5
local ngx_now = ngx.now
local ngx_var = ngx.var
local ngx_header = ngx.header
local ngx_shared = ngx.shared

local util = require("vendor.Util")
local req = require("vendor.Request")

local _M = {
	_VERSION='0.01',
	exptime = 1800, --默认session失效时间30分钟
    cache = ngx_shared['session_cache'], --默认使用ngx的缓存
}

local function get_sessionid() --获取已设置的cookie
    local cookies = ngx_header['Set-Cookie'] or {}
    cookies = type(cookies)=='table' and cookies or {cookies}
    for _,v in ipairs(cookies) do
        local i,j = v:find('=')
        if i and '_sessionid'==v:sub(1,i-1) then
            return v:sub(i+1)
        end 
    end
    return nil
end

function _M.start()
	local id = req.cookie('_sessionid') or get_sessionid()
	if not id then
		local ip = ngx_var.remote_addr or ''
		id = ngx_md5(ip..ngx_now())
		util.set_cookie('_sessionid',id)
	end
	return 'session_'..id
end

function _M.get(key,default)
	local id = _M.start()
	--ngx.say('get',id)
	local vars = util.json_decode(_M.cache:get(id)) or {}
	return not key and vars or vars[key] or default
	--]] return _M.cache:get(id..'_'..key)
end

function _M.set(key, value)
	local id = _M.start()
	--ngx.say('set',id,key)
    local vars = _M.get()
    vars[key] = value
    return _M.cache:set(id, util.json_encode(vars), _M.exptime)
    --]] return _M.cache:set(id..'_'..key, value, _M.exptime)
end

--直接通过值来获取对应的session值
_M.__index = function(self, key)
 	return _M.get(key)
end

--直接通过值来设置session
_M.__newindex = function(self, key, value)
    return _M.set(key, value)
end

return setmetatable(_M, _M)

--]] return _M


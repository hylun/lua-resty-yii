--上下文,单例模式
--version:0.0.1
--Copyright (C) Yuanlun He.

local require = require
local pairs = pairs
local pcall = pcall
local sub = string.sub
local ngx = ngx

local _M = {
	_VERSION='0.01',
	web = require("config.web"),		--站点配置信息表
	lang = require("config.lang"),		--语言包配置信息
	session = require("config.session"),--站点Session类
	user = require("vendor.User"),		--站点用户工具类
	request = require("vendor.Request"),--站点请求处理类
}

function _M:out(res)
	if ngx.status>0 then ngx.exit(ngx.status) end
	if res then ngx.say(res) end
end

local function getController(app)
	local con = require('vendor.Controller')
	local act = app.request.get('act') or con.class
	local p = act:find("%.")
	local class = p and act:sub(1,p-1) or act

	local ok,res = pcall(require,"controllers."..class)
	if not ok then ngx.log(ngx.ERR,res) end
	res = (ok and res or con):new(app)
	res.class = class
	res.action = ok and (p and act:sub(p+1) or res.action) or 'notFound' 

	return res
end

function _M:new()
	local app = {}
	for k,v in pairs(self) do
		app[k] = v
	end

	return getController(app)
end

return _M

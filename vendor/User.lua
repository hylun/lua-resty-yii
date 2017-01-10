--用户管理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local type = type

local util = require "vendor.Util"
local request = require "vendor.Request"
local session = require "vendor.Session"

local _M = {_VERSION='0.01'}

function _M.login(user,exprise)
	if type(user)~='table' then return false end
	local res = nil
	exprise = exprise or user.exprise
	if exprise and exprise > 0  then 
		user.exprise = exprise
		sso = util.aes_encrypt(util.json_encode(user))
		res = util.set_cookie('_sso',sso,exprise)
	else 
		--session.user = user或session['user'] = user
		res = session.set('user',user)
	end
	return res~=nil
end

function _M.logout()
	util.set_cookie('_sso',nil)
	session['user'] = nil
end

function _M.__index(table, key)
	local userinfo = nil
	local sso = request.cookie('_sso')
	if sso then
		userinfo = util.json_decode(util.aes_decrypt(sso))
	else
		userinfo = session['user']
	end

	if key == 'isLogin' then return userinfo end

	return userinfo and userinfo[key] or nil
end

function _M.__newindex(table, key, value)
	--设置此类为只读对象，不可以设置新属性
end

return setmetatable(_M, _M)

--登录逻辑处理
--version:0.0.1
--Copyright (C) Yuanlun He.

local require = require

local _M = require("vendor.Model"):new{_version='0.0.1'}

local rememberMe = false
local Userinfo = require('models.Userinfo')

function _M.rules()
	return {
		{{'username','password'}, 'trim'},
		{'username', 'required',message='请填写登录账号'},
		--{'username', 'email'}, --用户名必须为email时设置
        {'password', 'required',message='请填写登录密码'},
        --使用自定义方法校验参数
        {'password','checkPass'}
	}
end

function _M:checkPass(key)
	if self:hasErrors() then return end

	local user = Userinfo.getUserByName(self.username)
	if not user then 
		self:addError('username','账号不存在')
	elseif user.password ~= self.password then
		self:addError('password','密码错误')
	else
		self.userinfo = user
	end
end

function _M:login(user)
	if not self:validate() then return false end
	
	return user.login(self.userinfo, rememberMe and 3600*24*30 or 0)
end

return _M

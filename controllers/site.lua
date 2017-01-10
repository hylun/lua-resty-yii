--site Controller
--version:0.0.1
--Copyright (C) Yuanlun He.

local Pager = require("vendor.Pager")

local _M = require("vendor.Controller"):new{_VERSION='0.01'}

function _M:indexAction()	
	return self:render('index')
end

function _M:loginAction()
	if self.user.isLogin then return self:goHome() end

	local model = require('models.LoginForm'):new()
	
	if model:load(self.request.post()) and model:login(self.user) then 
		return self:goHome()
    end

	return self:render('login',{
		model = model
	})
end

function _M:logoutAction()
	self.user.logout()
	return self:goHome()
end

function _M:guideAction()
	return self:render('guide')
end

return _M

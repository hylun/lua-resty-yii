--controller基类
--version:'0.0.1'
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local require = require
local table = table
local pcall = pcall
local pairs = pairs
local type = type
local find = string.find
local sub = string.sub
local ngx = ngx
local ngx_log = ngx.log
local ngx_var = ngx.var
local ngx_header = ngx.header

local _M = {
	_VERSION='0.01',
	class='site',--默认访问的class为site
	action='index',--默认访问的action为index
	layout='main',--默认使用的布局为main
}

--新建controller实例
function _M:new(o)
	o = o or {}
	for k,v in pairs(self) do
		if not o[k] then
			o[k] = v
		end
	end
	return o
end

--执行controller的Action方法
function _M:run()
	local mod = self[self.action..'Action']
	if type(mod)~='function' then
		return self:notFound()
	end
	
	if not self:before() then return end
	local ok,res = pcall(mod,self)
	if not ok then
		ngx_log(ngx.ERR,res)
		local err = res:sub(1,res:find("\n"))
		res = self:showError(err)
	end
	self:after(ok,res)

	return res
end

--执行controller的Action前的过滤方法
function _M:before()
	return true
end

--执行controller的Action后的追加方法
function _M:after()
	return true
end

--返回首页
function _M:goHome()
	return self:redirect(ngx_var.uri)
end

--返回上一页
function _M:goBack()
	local url = ngx_var.http_referer
	return self:redirect(url)
end

--渲染页面
function _M:render(view,params)
	params = params or {}
	setmetatable(params, {__index = self})

	local template = require("vendor.resty.template")

	local dir = view:find('/') and view or self.class..'/'..view
	
	params.contentView = template.compile(require(dir))(params)

	return template.compile(require("layout/"..self.layout))(params)
end

--页面没有找到
function _M:notFound()
	return self:showError(self.lang.notFound)
end

--显示错误页面
function _M:showError(err)
	return self:render('site/error',{err=err})
end

--页面跳转
function _M:redirect(url)
	url = url or (type(self)=='string' and self or ngx_var.uri)
	ngx_header["Location"] = url
	ngx.status = 302
	return nil
end

--根据参数生成链接地址
function _M:createUrl(params)
	params = params or {}
	local url = ngx_var.uri..'?'
	local get = self.request.get()
	for k,v in pairs(get) do
		if params[k]==nil then  
			url = url..k..'='..v..'&' 
		end
	end
	if type(params)=='table' then
		for k,v in pairs(params) do 
			url = url..k..'='..v..'&' 
		end 
	else
		url = url..params
	end
	return url:sub(1,-1)
end

return _M

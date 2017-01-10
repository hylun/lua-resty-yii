--model基类
--version:'0.0.1'
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local require = require
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local match = ngx.re.match

local lang = require("config.lang")
local util = require("vendor.Util")

local _M = {_VERSION='0.01'}

--新建Model
function _M:new(o)
	o = o or {}
	o.err = {} --存储错误信息
	for k,v in pairs(self) do
		if not o[k] then
			o[k] = v
		end
	end
	return o
end
	
--加载数据
function _M:load(data)
	if not next(data) then return false end
	for k,v in pairs(data) do
		if type(v)~='function' then 
			self[k] = v
		end 
	end
	return true
end

--校验规则
function _M:rules()
	return {}
end

--是否有错
function _M:hasErrors()
	return self.err and next(self.err) or false
end

--添加错误
function _M:addError(key,err)
	self.err = self.err or {}
	self.err[key] = err
end

--根据规则校验参数
function _M:validate()
	local rules = self:rules()
	if not next(rules) then return true end

	for k,v in pairs(rules) do
		local func = v[2]
		self[func](self,v[1],v)
	end
	return not self:hasErrors()
end

--参数trim
function _M:trim(key)
	key = type(key)=='table' and key or {key}
	for _,k in ipairs(key) do
		if self[k] then self[k] = util.trim(self[k]) end
	end
end

--参数intval
function _M:intval(key)
	key = type(key)=='table' and key or {key}
	for _,k in ipairs(key) do
		if self[k] then self[k] = util.intval(self[k]) end
	end
end

--检查参数是否为空
function _M:required(key,rule)
	key = type(key)=='table' and key or {key}
	for _,k in ipairs(key) do
		if self.err[k]==nil and (self[k]==nil or self[k]=='') then
			local msg = rule.message or lang.required
			self:addError(k,msg) 
		end
	end
end

--检查参数是否符合正则规则
function _M:match(key,rule)
	if not rule.pattern then return end
	key = type(key)=='table' and key or {key}
	for _,k in ipairs(key) do
        -- 用ngx的正则性能更高,参数"o"是开启缓存必须的
		if self.err[k]==nil and match(self[k], rule.pattern, "o")==nil then
			local msg = rule.message or lang.matchErr
			self:addError(k,msg) 
		end
	end
end

--检查参数是否是邮箱地址
function _M:email(key,rule)
	key = type(key)=='table' and key or {key}
	rule.pattern = [[^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$]]
	for _,k in ipairs(key) do
		if self.err[k]==nil and match(self[k], rule.pattern, "o")==nil then
			local msg = rule.message or lang.emailErr
			self:addError(k,msg) 
		end
	end
end

return _M

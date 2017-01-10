--活动记录
--version:'0.0.1'
--Copyright (C) Yuanlun He.

local require = require
local type = type

local Model = require('vendor.Model')
local Query = require('vendor.Query')

return function(_M)

	_M = Model:new(_M) --继承Model
	_M._VERSION = '0.01'
	_M.db = _M.db or require('config.db')

	--返回查询对象
	function _M.new(data)
		local query = Query(data)
		query.use(_M.db).from(_M.tableName())
		return query
	end

	--返回查询对象
	function _M.find(s)
		local query = _M.new()
		if type(s)=='table' then query.where(s) end
		if type(s)=='string' then query.select(s) end
		return query
	end

	--返回一行符合条件的结果集
	function _M.findOne(cond)
		return _M.new().where(cond).one()
	end

	--返回所有符合条件的结果集
	function _M.findAll(cond)	
		return _M.new().where(cond).all()
	end

	--根据sql返回结果集
	function _M.findSql(sql)	
		return _M.new().sql(sql)
	end

	return _M

end

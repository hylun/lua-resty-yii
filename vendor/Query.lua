--查询构建器
--version:'0.0.1'
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local table_insert = table.insert
local table_concat = table.concat
local require = require
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type

local util = require("vendor.Util")
local mescape = util.mescape
local intval = util.intval
local in_array = util.in_array

return function(data)
	
	data = data or {}

	local _M = {_VERSION = '0.01'}
	local self = {feild = '*',cond = '1'}

	--返回私有字段
	function _M.get(key)
		return self[key]
	end

	--加载数据
	function _M.new(d)
		data = d and d or {}
		return setmetatable(data,{__index=_M})
	end

	--设置要操作的库
	function _M.use(db)
		self.db = db
		return _M
	end

	--设置要操作的表
	function _M.from(tableName)
		self.table = tableName
		if not self.db then _M.use() end
		return _M
	end

	--设置select的字段
	function _M.select(feild)
		if type(feild)=='string' and feild~='' then 
			self.feild = feild
		elseif type(feild)=='table' and next(feild) then 
			self.feild = '`'..table_concat(feild,'`,`')..'`'
		else
			self.feild = '*'
		end
		return _M
	end

	--添加参数
	local function andWhere(cond)
		local res = ''
		local isstr = (type(cond[1])=='string')
		if isstr and (cond[1]=='and' or cond[1]=='or') then
			cond[2] = type(cond[2])=='table' and andWhere(cond[2]) or cond[2]
			cond[3] = type(cond[3])=='table' and andWhere(cond[3]) or cond[3]
			res = res..' ('..cond[2]..' '..cond[1]..' '..cond[3]..') '
			return res
		end

		if isstr and (cond[1]=='between' or cond[1]=='not between') then
			res = res..' `'..cond[2]..'` '..cond[1]..' '..mescape(cond[3])..' AND '..mescape(cond[4])..' '
			return res
		end

		if isstr and (cond[1]=='in' or cond[1]=='not in') then
			local t = {}
			for i,j in pairs(cond[3]) do t[i] = mescape(j) end 
			res = res..' `'..cond[2]..'` '..cond[1]..' ('..table_concat(t,",") ..') '
			return res
		end

		if isstr and in_array(cond[1],{'<','>','=','<=','>=','!=','=>','=<'}) then
			res = res..' `'..cond[2]..'` '..cond[1]..' '..mescape(cond[3])
			return res
		end

		local t = {}
		for k,v in pairs(cond) do
			if type(v)=='table' and next(v) then
				if type(k)=='number' then
					table_insert(t,andWhere(v))
				else
					for i,j in pairs(v) do v[i] = mescape(j) end 
					v = table_concat(v,",") 
					table_insert(t,'`'..k..'` IN ('..v..')')
				end
			else
				if type(k)=='number' then
					table_insert(t,v)
				else
					table_insert(t,'`'..k..'`='..mescape(v))
				end
			end
		end
		res = '('..table_concat(t,') AND (')..')'

		return res
	end

	--设置where条件
	function _M.where(cond,params)
		if type(cond)=='string' and cond~='' then
			self.cond = cond
			_M:addParams(params)
		elseif type(cond)=='table' and next(cond) then 
			self.cond = andWhere(cond)
		else
			self.cond = '1'
		end
		return _M
	end

	--添加查询参数
	function _M.addParams(params)
		if params  and next(params) and self.cond then
			for k,v in pairs(params) do 
				self.cond = self.cond:gsub(k,mescape(v)) 
			end
		end
		return _M
	end

	--设置orderBy
	function _M.orderBy(orderby)
		if type(orderby)=='string' and orderby~='' then 
			self.order = orderby
		elseif type(orderby)=='table' and next(orderby) then
			local t = {}
			for k,v in pairs(orderby) do table_insert(t,k..' '..v) end  
			self.order = table_concat(t,',')
		else
			self.order = nil
		end
		return _M
	end

	--设置groupBy
	function _M.groupBy(groupby)
		if type(groupby)=='string' and groupby~='' then 
			self.group = groupby
		elseif type(groupby)=='table' and next(groupby) then
			self.group = '`'..table_concat(groupby,'`,`')..'`'
		else
			self.group = nil
		end
		return _M
	end

	--设置offset
	function _M.offset(offset)
		offset = offset and intval(offset) or 0
		if offset > 0 then 
			self.start = offset 
		else
			self.start = nil
		end
		return _M
	end

	--设置limit
	function _M.limit(limit)
		limit = limit and intval(limit) or 0
		if limit > 0 then 
			self.size = limit 
		else
			self.size = nil
		end
		return _M
	end

	--设置分页查询
	function _M.page(page)
		page = page and page or {}
		if page.limit then self.size = page.limit end
		if page.offset then self.start = page.offset end
		return _M
	end

	--返回所有符合条件的结果集
	function _M.all()
		self.sql = 'SELECT '..self.feild
		..' FROM '..self.table
		..(self.cond and ' WHERE '..self.cond or '')
		..(self.group and ' GROUP BY '..self.group or '')
		..(self.order and ' ORDER BY '..self.order or '')
		..(self.size and ' LIMIT '..self.size or '')
		..(self.start and ' OFFSET '..self.start or '');	
		local res,err = self.db:query(self.sql)
		self.err = err
		return _M.new(res)
	end

	--返回结果集的第一行
	function _M.one()
		self.sql = 'SELECT '..self.feild
		..' FROM '..self.table
		..(self.cond and ' WHERE '..self.cond or '')
		..(self.group and ' GROUP BY '..self.group or '')
		..(self.order and ' ORDER BY '..self.order or '')
		..' LIMIT 1';
		local res,err = self.db:query(self.sql)
		self.err = err
		return _M.new(res and res[1] or {})
	end

	--返回所有符合条件的条数
	function _M.count()
		local s = self.feild:find(',') and 'count(1)' or 'count('..self.feild..')'
		self.sql = 'SELECT '..s
		..' FROM '..self.table
		..(self.cond and ' WHERE '..self.cond or '')
		..(self.group and ' GROUP BY '..self.group or '')
		..(self.order and ' ORDER BY '..self.order or '');
		local res,err = self.db:query(self.sql)
		self.err = err
		return res and intval(res[1][s]) or 0
	end

	--根据sql返回结果集
	function _M.sql(sql)
		self.sql = 	sql
		return self.db:query(self.sql)
	end

	--获取主键
	function _M.primaryKey()
		if not self.tableSchema then
			self.tableSchema = {}
			for i,v in ipairs(self.db:query('desc '..self.table)) do
				self.tableSchema[v.Field] = v
				if v.Key == "PRI" then self.primaryKey = v.Field end
			end
		end
		return self.primaryKey
	end

	--保存
	function _M.save(d)
		return self.sql and _M.update(d) or _M.insert(d)
	end

	--插入数据
	function _M.insert(d)
		data = d and _M.new(d) or data

		local keys,values = {},{}
		for k,v in pairs(data) do 
			if in_array(type(v),{'string','number','boolean'}) then
				table_insert(keys,k) 
				table_insert(values,mescape(v))
			end
		end  
		self.sql = 'INSERT INTO `'..self.table..'`'
		..' (`'..table_concat(keys,'`,`')..'`)'
		..' VALUES ('..table_concat(values,',')..')';
		local res,err = self.db:query(self.sql)
		self.err = err				
		--res = {"insert_id":0,"server_status":2,"warning_count":0,"affected_rows":1}

		if res then
			self.insert_id = res.insert_id
			self.affected_rows = res.affected_rows
		end

		return res and data or _M.new()
	end

	--更新数据
	function _M.update(d)
		
		data = d and _M.new(d) or data

		local t = {}
		for k,v in pairs(data) do 
			table_insert(t,'`'..k..'`='..mescape(v)) 
		end  
		self.sql = 'UPDATE `'..self.table..'`'
		..' SET '..table_concat(t,',')
		..' WHERE '..(self.cond and self.cond or addWhere(data));

		local res,err = self.db:query(self.sql)
		self.err = err	

		if res then
			self.affected_rows = res.affected_rows
		end			
		
		return res and data or _M.new()
	end

	--删除数据
	function _M.delete(d)
		data = d and _M.new(d) or data
		self.sql = 'DELETE FROM `'..self.table..'`'
		..' WHERE '..(self.cond and self.cond or addWhere(data));
		local res,err = self.db:query(self.sql)
		self.err = err	
		--res={"insert_id":0,"server_status":2,"warning_count":0,"affected_rows":1}
		if res then
			self.affected_rows = res.affected_rows
		end			
		
		return res and res.affected_rows or 0
	end

	return setmetatable(data,{__index=_M})
end

--session处理类
--version:0.0.1
--Copyright (C) Yuanlun He.

local setmetatable = setmetatable
local require = require
local pairs = pairs
local type = type
local tonumber = tonumber
local ceil = math.ceil
local floor = math.floor
local ngx_get_args = ngx.req.get_uri_args

return function (_M)
	_M = _M or {}
	_M._VERSION	  = '0.01'
	_M.pageSize   = _M.pageSize or 10		--每页显示条数
	_M.buttonSize = _M.buttonSize or 10	--显示的按钮数
	_M.totalCount = _M.totalCount or 0		--总页数
	_M.pageParam  = _M.pageParam or 'page'	--分页的参数
	_M.class 	  = _M.class or 'pagination' --分页的样式
	_M.prevButton = _M.prevButton or '&laquo;' --向前翻按钮
	_M.nextButton = _M.nextButton or '&raquo;' --向后翻按钮

	local get = ngx_get_args()
	_M.now = floor(tonumber(get[_M.pageParam]) or 0)
	_M.now = (_M.now and _M.now>1) and _M.now or 1
	_M.offset = (_M.now-1) * _M.pageSize
	if _M.offset>=_M.totalCount then
		_M.now = 1
		_M.offset = 0
	end
	_M.limit = _M.pageSize
	
	_M.render = function(opts)
		if _M.now==1 and _M.totalCount <= (_M.offset+_M.pageSize) then return nil end 

		opts = opts or {}
		for k,v in pairs(opts) do _M[k] = v end

		local max = ceil(_M.totalCount/_M.pageSize)

		local url = '?'
		get[_M.pageParam] = nil
		for k,v in pairs(get) do
			url = url..k..'='..v..'&' 
		end
		url =url .._M.pageParam..'='
		
		local str = '<ul class="'.._M.class..'">'

		if _M.now <= 1 then 
			str = str ..'<li class="prev disabled"><span>'.._M.prevButton..'</span></li>'
		else
			str = str ..'<li class="prev"><a href="'..url..(_M.now-1)..'">'.._M.prevButton..'</a></li>'
		end

		local start = floor((_M.now-2)/(_M.buttonSize-2))*(_M.buttonSize-2)
		start = start+_M.buttonSize>max and max-_M.buttonSize or start
		start = start>=0 and start or 0
		for i = start+1,start+_M.buttonSize do
			if i > max or _M.buttonSize<3 then break end
			str = str..'<li'..(i==_M.now and ' class="active"' or '')..'><a href="'..url..i..'">'..i..'</a></li>'
		end

		if _M.now >= max then 
			str = str ..'<li class="next disabled"><span>'.._M.nextButton..'</span></li>'
		else
			str = str ..'<li class="next"><a href="'..url..(_M.now+1)..'">'.._M.nextButton..'</a></li>'
		end

		return str ..'</ul>'
	end

	return _M

end





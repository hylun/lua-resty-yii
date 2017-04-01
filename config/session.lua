--数据库配置
--Copyright (C) Yuanlun He.

local require = require
local ngx_shared = ngx.shared

local _M = require('vendor.Session')
--_M._VERSION= '0.01'
--_M.exptime = 1800, --修改session失效时间时，打开默认30分钟
--_M.cache = ngx_shared['session_cache'], --使用ngx的缓存时打开，此为默认项
 --使用memcached缓存打开以下配置
--_M.cache = require("vendor.Memcache"):new{host="127.0.0.1",port="11211"},
return _M

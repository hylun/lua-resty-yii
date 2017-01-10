--工具方法，网络收集
--Copyright (C) Yuanlun He.
-- http://en.wikipedia.org/wiki/Trim_(programming)

local setmetatable = setmetatable
local require = require
local pcall = pcall
local pairs = pairs
local type = type
local floor = math.floor
local tonumber = tonumber
local gsub = string.gsub
local find = string.find
local sub = string.sub
local gsub = string.gsub
local string_char = string.char
local ngx_header = ngx.header
local ngx_cookie_time = ngx.cookie_time
local ngx_time= ngx.time
local table_insert = table.insert
local escape = ndk.set_var.set_quote_sql_str

local json = require "cjson"
local aes = require "resty.aes"
local resty_str = require "resty.string"

local _M = {_VERSION='0.01'}

function _M.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function _M.ltrim(s)
  return (s:gsub("^%s*", ""))
end

function _M.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

-- 字符串 split 分割
function _M.split(s, p)
    local rt= {}
    gsub(s, '[^'..p..']+', function(w) table_insert(rt, w) end )
    return rt
end

--字符串转整数
function _M.intval(str)
	return floor(tonumber(str) or 0)
end

--转义sql参数
function _M.mescape(val)
	return val and escape(val) or ''
end

--检查变量是否为空
function _M.empty(val)
	return val==nil or (type(val)=='string' and val=='')
		   or (type(val)=='number' and val==0)
		   or (type(val)=='table' and next(val)==nil )
		   or (type(val)=='boolean' and val==false )
end

--检查值是否在一个表里
function _M.in_array(val,arr)
	for _,v in pairs(arr) do
		if v==val then return true end 
	end
	return false
end

--字符串转json
function _M.json_decode( str )
    if not str then return nil end
    local json_value = nil
    pcall(function (str) json_value = json.decode(str) end, str)
    return json_value
end

--json转字符串
function _M.json_encode( obj )
    if not obj then return nil end
    local str = nil
    pcall(function (obj) str = json.encode(obj) end, obj)
    return str
end

local AES_KEY = "My_Key_For_AES-256-CBC"
local AES_SALT = "My_Salt"

--AES-256-CBC解密
function _M.aes_decrypt(str,key,salt)
    key = key or AES_KEY
    salt = salt or AES_SALT
    local aesn = aes:new(key, salt, aes.cipher(256,"cbc"), aes.hash.sha512, 5)
    str = str:gsub('..', function (cc) return string_char(tonumber(cc, 16)) end)
    return aesn:decrypt(str)
end

--AES-256-CBC加密
function _M.aes_encrypt(str,key,salt)
    key = key or AES_KEY
    salt = salt or AES_SALT
    local aesn = aes:new(key, salt, aes.cipher(256,"cbc"), aes.hash.sha512, 5)
    return resty_str.to_hex(aesn:encrypt(str))
end

--设置cookie
function _M.set_cookie(name,value,expire,path,domain,secure,httponly)
    if not name then return end

    local cookies = ngx_header['Set-Cookie'] or {}
    cookies = type(cookies)=='table' and cookies or {cookies}

    expire = (value==nil or value=='') and -3600 or expire --删除cookie

    cookies[#cookies+1] = name..'='..(value or '')
    ..(expire and ';Expires='..ngx_cookie_time(ngx_time()+expire) or '')
    ..(path and ';Path='..path or '')
    ..(domain and ';Domain='..domain or '')
    ..(secure and ';Secure' or '')
    ..(httponly and ';Httponly' or '');

    ngx.header["Set-Cookie"] = cookies
    return cookies
end

return _M






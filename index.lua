--web  入口
--version:1.0.0
--Copyright (C) Yuanlun He.
local require = require
local package = package
local pack_path = package.path
local find = string.find
local sub = string.sub
local ngx = ngx
local ngx_var = ngx.var
local ngx_header = ngx.header

--设置默认输出类型
ngx_header["Content-Type"] = "text/html; charset=utf-8"

--根目录
local root = ngx_var.document_root:sub(1,-4)

--添加类加载路劲
local p = root.."?.lua;"..root.."views/?.lua.html;"
if pack_path:sub(1,#p)~=p then package.path = p..pack_path end

--初始化请求生命周期内的全局变量
ngx.ctx = require("vendor.Application"):new()

--设置根目录
ngx.ctx.web.root = root

--执行请求
ngx.ctx:out(ngx.ctx:run())
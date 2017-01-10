--memcache
--Copyright (C) Yuanlun He.

local require = require

return require('vendor.Memcache'):new{
    host = "127.0.0.1",
    port = "11211",
}

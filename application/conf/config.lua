--[[
* @name : config.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description :
--]]

local config = require "lapis.config"

--###############################公共配置#################################################

--------------------------数据库用户名密码公用配置----------------------------------------

config("development", {
 --    code_cache = "off",
	-- site_name  = "Slither Admin Dev",
	-- port       = 9050,
	mysql      = {
        host = "192.168.16.221",
        port = "3306",
        user = "root",
        password = "CS---107",
        database = "slither-monitor",
	},
})

config("production", {
	-- code_cache = "on",
	-- site_name  = "Slither Admin",
	-- port       = 9050,
	mysql      = {
        host = "192.168.16.221",
        port = "3306",
        user = "root",
        password = "CS---107",
        database = "slither-monitor",
	},
})

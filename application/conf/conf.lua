--[[
* @name : conf.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017-04-01
* description : 
--]]


local api_config = {

--###############################公共配置#################################################

--------------------------数据库用户名密码公用配置----------------------------------------

    -- root用户
    DB_ROOT_USER = "root",
    -- root密码
    DB_ROOT_PASSWORD = "CS---107",

    -- 读数据库用户名
    -- DB_USER_R = "hddef_ro",
    -- -- 读数据库密码
    -- DB_PASSWORD_R = "hd-RO-4w6WnbCyi9f4P0Ii",

    -- -- 写数据库用户名
    -- DB_USER_W = "hddef_rw",
    -- -- 写数据库密码
    -- DB_PASSWORD_W = "hd-RW-4w6WnbCyi9f4P0Ii",


-----------------------服务器监控-------------------------------------

    mysql_api_r_0 = {
        host       = "192.168.16.221",
	    database   = "slither-monitor",
    },

    mysql_api_w_0 = {
        host       = "192.168.16.221",
	    database   = "slither-monitor",
    },

}

return api_config

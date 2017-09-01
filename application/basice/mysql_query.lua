--[[
* @name : mysql_query.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/04/01
* description : mysql
--]]

local tools    = require("basice.tools")
local mysqldb  = require("basice.mysql_pool")
local config   = require("conf.conf")

local mybo = {}

function mybo:get_db_node(is_read)
    local db_node_name = nil

    if is_read then
        db_node_name = "mysql_api_r_0"
    else
        db_node_name = "mysql_api_w_0"
    end

    return db_node_name
end


function mybo:query_mysql( sql )

    local db_node_name = self:get_db_node(true)

    local dbconfig = tools:get_db_config(config[db_node_name],config.DB_ROOT_USER,config.DB_ROOT_PASSWORD)

    if not dbconfig then
    	ngx.log(ngx.ERR,"dbconfig is not exist")
        return false,"dbconfig is not exist"
    end

    local ret, res, errno, sqlstate = mysqldb:query(sql,dbconfig)
    if ret ~= 0 then
    	ngx.log(ngx.ERR,res)
        return false,res
    end

    return true,res
end

return mybo
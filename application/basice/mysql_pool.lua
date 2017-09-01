--[[
* @name : mysql_pool.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : 
--]]

-- local dbConfig = require("config")
local mysql = require("resty.mysql")

local mysql_pool = {
    keep_alive_timeout = 1000*300
}

--[[
    先从连接池取连接,如果没有再建立连接.
    返回:
        false,出错信息.
        true,数据库连接
--]]
function mysql_pool:get_connect(config)

    local client, errmsg = mysql:new()
    if not client then
        return 210103, (errmsg or "nil"),-1,-1
    end

    client:set_timeout(config.timeout)  -- 10秒

    local result, errmsg, errno, sqlstate = client:connect(config)
    if not result then
        return 210101, (errmsg or "nil"), (errno or -1),(sqlstate or -1)
    end

    local query = "SET NAMES utf8"
    local result, errmsg, errno, sqlstate = client:query(query)
    if not result then
        return 210102, (errmsg or "nil") , (errno or -1) ,(sqlstate or -1)
    end

    return 0, client,0,0
end

--[[
    查询
    有结果数据集时返回结果数据集
    无数据数据集时返回查询影响
    返回:
        false,出错信息,sqlstate结构.
        true,结果集,sqlstate结构.
--]]
function mysql_pool:query(sql,config)
    local ret, client,no,state = self:get_connect(config)
    -- ngx.say(ret)
    if ret ~= 0 then
        return ret, client, no,state
    end

    local result, errmsg, errno, sqlstate = client:query(sql)
    -- self:close(config)

    if not result then
        return 210102, errmsg, errno,sqlstate
    end

    -- 判断是否使用连接池
    local times, err = client:get_reused_times()
    -- ngx.say(times)

    client:set_keepalive(mysql_pool.keep_alive_timeout,1024)
    -- client:close()

    return 0, result, (errno or 0) ,(sqlstate or 0)
end

return mysql_pool



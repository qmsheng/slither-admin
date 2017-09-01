--[[
* @name : userlist.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : 查询用户列表信息
--]]

local Model   = require("lapis.db.model").Model
local Servers = Model:extend("servers")
local json_lib = require("basice.sim_json_lib")
local cjson    = json_lib:new()

return function(self)
    self.page_title = "UserList"
    require("lapis.db").query("set names utf8")

    local allData = Servers:select()
    local lastData = allData[#allData]
    self.userData = cjson:json_decode(lastData.online_users) or {}
	return { render = "userlist" }
end

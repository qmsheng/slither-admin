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
    self.page_title = "RoomList"
    require("lapis.db").query("set names utf8")

    local allData = Servers:select()
    local lastData = allData[#allData]
    self.roomData = cjson:json_decode(lastData.room_info) or {}
	return { render = "roomlist" }
end

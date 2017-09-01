--[[
* @name : room_info.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : 查询用户房间详细信息
--]]

local Model    = require("lapis.db.model").Model
local Servers  = Model:extend("servers")
local json_lib = require("basice.sim_json_lib")
local cjson    = json_lib:new()

return function(self)
    self.page_title = "RoomInfo"
    require("lapis.db").query("set names utf8")
    self.userID = self.params.roomID

    local allData = Servers:select()
    local lastData = allData[#allData]
    self.roomInfo = cjson:json_decode(lastData.room_info) or {}
    self.roomInfo = self.roomInfo[tonumber(self.userID)]
	return { render = "roominfo" }
end

--[[
* @name : user.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : 查询用户详细信息
--]]

local Model    = require("lapis.db.model").Model
local Servers  = Model:extend("servers")
local json_lib = require("basice.sim_json_lib")
local cjson    = json_lib:new()

return function(self)
    require("lapis.db").query("set names utf8")
    self.page_title = "UserInfo"
    self.userID = self.params.userID

    local allData = Servers:select()
    local lastData = allData[#allData]
    self.userData = cjson:json_decode(lastData.online_users)or {}
    self.userData = self.userData[tonumber(self.userID)]
    return {render = "userinfo"}
end

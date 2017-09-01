--[[
* @name : kick_off.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : 踢用户下线
--]]

local tools    = require("basice.tools")
local model    = require("model.get_slither_server_model")
local json_lib = require("basice.sim_json_lib")
local cjson    = json_lib:new()

local function return_action(self, info)
	self.kickoff = info
	return { render = "kickoff" }
end

return function(self)
    self.page_title = "KickOff"
    self.userID = self.params.userID

    local res_query = model:kick_online_user(self.userID)

    if res_query.status ~= ngx.HTTP_OK then
		errinfo = string.format("get_slither_server_model status:%s wrong back", res_query.status)
		return return_action(self, errinfo)
	end
	local info = cjson:json_decode(res_query.body) or {}
	if next(info) == nil then
		errinfo = string.format("get_slither_server_model decode string failed:[%s]", res_query.body)
		return return_action(self, errinfo)
	end

    return return_action(self, info)
end


--[[
* @name : close_room.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/28
* description : 关闭房间
--]]

local tools    = require("basice.tools")
local model    = require("model.get_slither_server_model")
local json_lib = require("basice.sim_json_lib")
local cjson    = json_lib:new()

local function return_action(self, info)
	self.closeroom = info
	return { render = "closeroom" }
end

return function(self)
    self.page_title = "CloseRoom"
    self.userID = self.params.roomID

    local res_query = model:close_user_room(self.userID)

    if res_query.status ~= ngx.HTTP_OK then
		errinfo = string.format("close_user_room status:%s wrong back", res_query.status)
		return return_action(self, errinfo)
	end
	local info = cjson:json_decode(res_query.body) or {}
	if next(info) == nil then
		errinfo = string.format("close_user_room decode string failed:[%s]", res_query.body)
		return return_action(self, errinfo)
	end

    return return_action(self, info)
end


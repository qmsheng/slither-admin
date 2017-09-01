--[[
* @name : app.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : main
--]]

local lapis          = require("lapis")
local json_lib       = require("basice.sim_json_lib")
local cjson          = json_lib:new()
local app            = lapis.Application()
local capture_errors = require("lapis.application").capture_errors
local csrf           = require "lapis.csrf"
local db             = require("lapis.db")
local Model          = require("lapis.db.model").Model
local Servers        = Model:extend("servers")
local check_auth     = require "controller.check_auth"
local UserList       = require("controller.user_list")
local RoomInfo       = require("controller.room_info")
local Index          = require("controller.index")
local UserInfo       = require("controller.user_info")
local Serverinfo     = require("controller.server_info")
local KickOff        = require("controller.kick_off")
local RoomList       = require("controller.room_list")
local CloseRoom       = require("controller.close_room")
local ngx_var        = ngx.var
local headers        = ngx.req.get_headers()

local app = lapis.Application()
app:enable("etlua")
app.layout = require "views.layout"

app:before_filter(check_auth)

app:get("/", Index)


local function get_read_ip()
    if headers["proxy_add_x_forwarded_for"] then
        return headers["proxy_add_x_forwarded_for"]
    elseif headers["X-Forwarded-For"] then
        return headers["X-Forwarded-For"]
    elseif ngx_var.remote_addr then
        return ngx_var.remote_addr
    else
        return ''
    end
end

app:post("/user/", function(self)
    
    -- 临时处理
    ngx.exit(ngx.HTTP_OK)


    db.query("set names utf8")
    ngx.req.read_body()
	-- print("self.params.ip %s",ngx.req.get_body_data())
    local body_data = cjson:json_decode(ngx.req.get_body_data())
    local host_ip = get_read_ip()

    local onlineUsers = (body_data).users
    local roomInfo = (body_data).room
    local roomPlayerCounts = (body_data).roomNum

    Servers:create({
      ip = host_ip,
      online_users = cjson:json_encode(onlineUsers),
      room_info    = cjson:json_encode(roomInfo),
      room_counts  = cjson:json_encode(roomPlayerCounts),
      ts           = db.raw("now()"),
    })

    ngx.exit(ngx.HTTP_OK)
end)

app:match("/userlist", UserList)
app:match("/roomlist", RoomList)
app:match("/checkuser/:userID", UserInfo)
app:match("/serverinfo", Serverinfo)
app:match("/kickoff/:userID", KickOff)
app:match("/checkroom/:roomID", RoomInfo)
app:match("/closeroom/:roomID", CloseRoom)

return app

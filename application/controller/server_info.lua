--[[
* @name : server_info.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/17
* description : server基本信息查询
--]]

local mysql_query    = require("basice.mysql_query")
local json_lib       = require("basice.sim_json_lib")
local cjson          = json_lib:new()
local ngx_var        = ngx.var
local headers        = ngx.req.get_headers()
local tcpsock_send_http       = require("model.tcpsock_send_http")

local G = {
		-- 查询最新数据
		sql_select_user_info = "SELECT * FROM `servers` WHERE 1 ORDER BY id desc limit 1",
}

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


local function get_onlineuser_onlineroom()
	local tab_user, tab_room, online_user_count, online_room_count = {}, {}, 0, 0
	local ok, ser_info = mysql_query:query_mysql( G.sql_select_user_info )
	if not ok then
		return 0, 0
	end

	tab_user = cjson:json_decode(ser_info[1].online_users) or {}
	tab_room = cjson:json_decode(ser_info[1].room_info) or {}

	online_user_count = #tab_user or 0
	online_room_count = #tab_room or 0

	return online_user_count, online_room_count
end


local function get_ori_uri(request_uri)
	if not request_uri then
		return ""
	end
	local from, to, err = ngx.re.find(request_uri, "\\?", "jo")
	if err then
		return ""
	end
	local end_s = -1
	if from then end_s = from -1 end
	return string.sub(request_uri, 1,end_s)
end


local function get_status()
	-- 域名 
	local domain = ngx_var.Host
	-- 请求时刻
	local time = ngx_var.time_local
	-- 请求地址IP
	local remote_ip = get_read_ip()
	-- 客户端信息状态
	local http_user_agent = ngx_var.http_user_agent
	-- 请求uri
	-- local rewrite_uri = ngx_var.uri
	local uri = get_ori_uri(ngx_var.request_uri)

	local online_user_count, online_room_count = get_onlineuser_onlineroom()
	-- 请求的uri参数
	local query_string = ngx_var.query_string or ""

	local tab_status = {{
		['1)域名'] = domain,},{
		['2)在线用户总数'] = online_user_count,},{
		['3)在线房间总数'] = online_room_count,},{
		['4)服务器IP'] = remote_ip,},{
		['5)请求uri'] = uri,},{
		['6)请求的uri参数'] = query_string,},{
		['7)请求时刻'] = time,},{
		['8)客户端信息状态'] = http_user_agent,},{
	}}

	return tab_status
end


return function(self)
	self.page_title = "ServerInfo"
    self.server_info = get_status()
    return {render = "serverinfo"}
end

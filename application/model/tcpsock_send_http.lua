--[[
* @name : tcpsock_send_http.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/04/06
* description : basice tcpsock send http
--]]

local http           = require("basice.http")
local json_lib       = require("basice.sim_json_lib")
local cjson          = json_lib:new()

local _M = {}

function _M:http_request_get(uri, tab_args, tab_headers)
	local headers
	local tab_args = tab_args or {}

	if tab_args and type(tab_args) ~= 'table' then
		return false, 'the second parameter type is not a table'
	end

	if tab_headers and type(tab_headers) == 'table' then
		headers = tab_headers
	end

	local str_args = ngx.encode_args(tab_args)
	uri = uri .. '?' .. str_args

    local httpc = http.new()
    local res, err = httpc:request_uri(
										uri, 
										{
											method = "GET",
											headers = 
											{
												["Content-Type"] = "application/x-www-form-urlencoded",
											}
										}
									  )

    if not res then
        return false, 'http get request err:' .. err
    end

    return true, res
end

function _M:http_request_post(uri, tab_body, tab_headers)
	local headers
	local tab_body = tab_body or {}

	if tab_body and type(tab_body) ~= 'table' then
		return false, 'the second parameter type is not a table'
	end

	if tab_headers and type(tab_headers) == 'table' then
		headers = tab_headers
	end

    local str_body = ngx.encode_args(tab_body)

    local httpc = http.new()
    local res, err = httpc:request_uri(
										uri, 
										{
											method = "POST",
											body = str_body,
											headers = 
											{
												["Content-Type"] = "application/x-www-form-urlencoded",
											}
										}
									  )

    if not res then
        return false, 'http post request err:' .. err
    end

    return true, res
end

return _M

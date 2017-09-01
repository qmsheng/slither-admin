--[[
* @name : backend_websocket_tcp.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/04/07
* description : websocket
--]]

local server = require "resty.websocket.server"
local string_sub     = string.sub
local string_format  = string.format

local _M = {}

function _M:new()
    local socket, err = server:new{
        timeout = 60 * 1000,        -- 60s
        max_payload_len = 65535,
    }

    if not socket then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        ngx.exit(444)
    end

    return socket
end

function _M:socket_recv_frame( socket )

    local data, typ, err = socket:recv_frame()

    if not data then
        if string_sub(err, -7) == "timeout" then
            return false     -- recv next message
        end

        ngx.log(ngx.ERR, "failed to receive a frame: ", err)
        ngx.exit(444)
    end

    return true, data, typ
end

function _M:socket_send_close( socket )

    local bytes, err = socket:send_close(1000, "enough, enough!")
    if not bytes then
        return false, string_format("failed to send the close frame: %s", err)
    end

    return true
end

function _M:socket_send_pong( socket, data )

    local bytes, err = socket:send_pong(data)
    if not bytes then
        return false, string_format("failed to send frame: %s", err)
    end

    return true
end

function _M:socket_send_text( socket, json_data )

    local bytes, err = socket:send_text( json_data )
    if not bytes then
        ngx.log(ngx.ERR, "failed to send a text frame: ", err)
        ngx.exit(444)
    end
end

function _M:run_action( action_func_name )

    local socket = self:new()

    local running = true

    while running do

        local ok, data, typ = self:socket_recv_frame( socket )
        if not ok then
            running = false
        end

        if typ == "close" then
            -- send a close frame back:

            local ok, err = self:socket_send_close( socket )
            if not ok then
                ngx.log(ngx.ERR, err)
            end
        elseif typ == "ping" then
            -- send a pong frame back:

            local ok, err = self:socket_send_pong( socket, data )
            if not ok then
                ngx.log(ngx.ERR, err)
            end
        elseif typ == "pong" then
            -- just discard the incoming pong frame

        else
            ngx.log(ngx.ERR, "received a frame of type ", typ, " and payload ", data)
        end

        -- socket:set_timeout(1000)  -- change the network timeout to 1 second          //后期可以用来实时更新超时
        local json_data = action_func_name( data )
        self:socket_send_text( socket, json_data )
    end
end

return _M

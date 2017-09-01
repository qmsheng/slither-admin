--[[
* @name : backend_socket_tcp.lua
* @author : qmsheng
* @version : 1.0.0
* @data : 2017-03-31
* description : 后端 server tcp 操作类
--]]

local _M = {}

--[[
      用ngx.ctx保存当前请求的连接信息，来优化1个请求
      在不同阶段需要多次访问backend的问题
--]]
function _M:get_connect(host, port, suffix)
    if ngx.ctx[string.format("%s:%s:%s", host,port,suffix)] then
        return ngx.ctx[string.format("%s:%s:%s", host,port,suffix)],nil
    end

    local sock = ngx.socket.tcp()
    if not sock then
        return false,"failed to init cosocket instance"
    end

    local ok, err = sock:connect(host, port)
    if not ok then
        return false,string.format("CONNECT ERR[%s:%s]: %s",host,port, err)
    end
    sock:settimeout(6000) -- 10 sec

    ngx.ctx[string.format("%s:%s:%s", host,port,suffix)] = sock
    return ngx.ctx[string.format("%s:%s:%s", host,port,suffix)],nil
end

--[[
    将正常连接放入连接池，异常的连接一定要丢弃
--]]
function _M:get_close(host, port, suffix)
    if ngx.ctx[string.format("%s:%s:%s", host,port,suffix)] then
        local pool_max_idle_time = 1000*300  -- 5 mins
        local pool_size = 1024
        local ok, err = ngx.ctx[string.format("%s:%s:%s", host,port,suffix)]:setkeepalive(pool_max_idle_time, pool_size)
        ngx.ctx[string.format("%s:%s:%s", host,port,suffix)] = nil
        if not ok then
            return false,string.format("failed to put current connection to connect_poll due to %s", err)
        end
    end
    return true,"succ"
end

--[[
    初始化 cosocket 实例
--]]
function _M:new(sock_config)

    if type(sock_config) ~= "table" then
        return false,"backend config is not well-defined"
    end

    local client, err = self:get_connect(sock_config.host, sock_config.port, 1)
    -- 清空 socket 的缓存
    ngx.ctx[sock_config.host .. ":" .. sock_config.port .. ":1"] = nil
    if not client then
        return false,err
    end

    return client,nil
end

--[[
    生产者 --> 消费者 ping-pong 模型，并弹出当前 socket (用于多次应答)
--]]
function _M:ping_pong(sock, raw_plain)

    local ok, err = sock:send(raw_plain .. "\r\n\r\n")
    if not ok then
        return false,string.format("failed to send packet due to %s", err)
    end

    -- 不建议使用行缓冲(无法解析多个\r\n的情况)
    -- local response, err, partial = sock:receive("*l")
    local reader = sock:receiveuntil("\r\n\r\n")
    local response, err, partial = reader()

    if not response then
        return false,string.format("failed to read response due to %s, occurs at %s", err, partial)
    end

    return response,nil
end

--[[
    send 生产者 --> 消费者 ping-pong 模型，最后将 socket 放入连接池
--]]
function _M:send_close(sock_config, raw_plain, conn_suffix)

    if type(sock_config) ~= "table" then
        return false,"backend config is not well-defined"
    end

    local client, err = self:get_connect(sock_config.host, sock_config.port, conn_suffix or 1)
    if not client then
        return false,err
    end

    local ok, err = client:send(raw_plain .. "\r\n\r\n")
    if not ok then
        return false,string.format("SEND ERR: %s", err)
    end

    -- 不建议使用行缓冲(无法解析多个\r\n的情况)
    -- local response, err, partial = sock:receive("*l")
    local reader = client:receiveuntil("\r\n\r\n")
    local response, err, partial = reader()

    if not response then
        return false,string.format("REV ERR: %s;BYTES: %s", err, partial)
    end

    -- 关闭连接操作(直接关闭，不放入连接池)
--     local ok, err = client:close()
--     if not ok then
--         return false,string.format("failed to close current connection due to %s", err)
--     end

    -- 关闭连接操作(默认使用连接池)
    local ok, err = self:get_close(sock_config.host, sock_config.port, conn_suffix or 1)
    if not ok then
        return false,err
    end

    return response,nil
end

--[[
    send 的多线程实现
--]]
function _M:send_multi(sock_config, raw_list)

    if type(sock_config) ~= "table" then
        return false,"backend config is not well-defined"
    elseif type(raw_list) ~= "table" then
        return false,"raw_list is not well-defined"
    end

    -- refer https://github.com/openresty/lua-nginx-module/issues/332
    local thread, result = {}, {}
    for i=1,#raw_list do
        thread[i] = ngx.thread.spawn(self.send_close, self, sock_config, raw_list[i], i)
    end

    for i=1,#thread do
        local ok, res, err = ngx.thread.wait(thread[i])
        table.insert(result, res or err)
    end

    return result,nil
end

return _M

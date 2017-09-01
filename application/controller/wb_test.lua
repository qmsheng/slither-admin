

local json_lib       = require("basice.sim_json_lib")
local cjson          = json_lib:new()
local mysql_query    = require("basice.mysql_query")

local backend_websocket_tcp       = require("model.backend_websocket_tcp")


function test( data )

    local qms

    if type(data) == 'string' then
        local args = cjson:json_decode(data) or "0"

        if type(args) == 'table' then
            qms = args.qms
        else
            qms = args
        end
    elseif type(data) == 'number' then
        qms = tostring(data)
    end

    if qms == 'test' then
        local ok, ser_info = mysql_query:query_mysql( 'SELECT * FROM `servers` WHERE 1 ORDER BY id desc limit 1' )
        if not ok then
            return 0
        end

        local str_user = ser_info[1].online_users

        return str_user
    end

    return 0
end



backend_websocket_tcp:run_action( test )



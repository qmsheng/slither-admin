-- @Date    : 2017-03-24 17:19:50
-- @Author  : qmsheng 
-- @Version : 1.0
-- @Description : 

local mt = {
	host = "192.168.16.30:8001",
	method_get = "/proxy_http"
}


function mt:kick_online_user(sid)
	local tab_args = {
			action = "user.kickuser",
			id     = sid
		}

	local str_args = ngx.encode_args(tab_args)
    return ngx.location.capture( self.method_get,{ args={
                          pass_proxy_host = self.host,
                          pass_proxy_url  = string.format("/slither/?%s", str_args)
                          }
                      }
    )
end

function mt:close_user_room(roomid)
	local tab_args = {
			action = "user.removeroom",
			roomid     = roomid
		}

	local str_args = ngx.encode_args(tab_args)
    return ngx.location.capture( self.method_get,{ args={
                          pass_proxy_host = self.host,
                          pass_proxy_url  = string.format("/slither/?%s", str_args)
                          }
                      }
    )
end


return mt
-- @Date    : 2017/04/06
-- @Author  : qmsheng 
-- @Version : 1.0
-- @Description : capture同步非阻塞/capture_multi异步非阻塞

local _M = {
	host = "192.168.16.30:8001",
	method_get = "/proxy_http"
}

function _M:ngx_location_capture(tab_args, host)

	host = host or self.host

	if not tab_args or type(tab_args) ~= 'table' then
		return false, 'the first parameter type is not a table'
	end

	local str_args = ngx.encode_args(tab_args)
    local res = ngx.location.capture( self.method_get,{ args={
                          pass_proxy_host = host,
                          pass_proxy_url  = string.format("/slither/?%s", str_args)
                          }
                      }
    )

    return true, res
end

function _M:ngx_location_capture_multi(tabs_args)

	local tabs_args = tabs_args or {}

    local all = {}

    for _, tab_args in pairs(tabs_args) do

    	if not tab_args or type(tab_args) ~= 'table' then
			return false, 'the first parameter type is not a two-dimensional table'
		end

        local args = {}

        for key, val in pairs(tab_args) do
            args = {
                key = val,
            }
        end
        local tab_req = {
                            self.method_get,
                            {
                                args = args,
                                -- demo
								-- args = {
		                        --     pass_proxy_host = '',
		                        --     pass_proxy_url  = '',
		                        -- }
                            }
                        }
        table.insert(all, tab_req)
    end

    return true, ngx.location.capture_multi(all)
end

return _M

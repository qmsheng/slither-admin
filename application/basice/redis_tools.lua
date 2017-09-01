--[[ 
作者 qmsheng
创建日期：2017-03-27
描述：封装基于httpredis2module模块的操作，封装成对象化操作
必须要基于redis location操作，location代码如下：
location = /redis {
                set_unescape_uri $query $arg_query;
                redis2_query $query;
                redis2_pass backend;
            }

--]]

local sub = string.sub
local byte = string.byte
local concat = table.concat
local null = ngx.null
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local error = error

local tools = require ("tools")
local _R = { 
	version = "0.1", 
	pass
}

local redis_tools = { }

function redis_tools:set( k,v )
	local res = ngx.location.capture( "/redis_set",{
			args = {
			    key = k,
			    value=v,
			}
		} )
	
	if res.status~=200 then
	    return nil,res.body,false;
	else
	    return res.body,"ok",true;
	end
end

function redis_tools:get( k )
	local res = ngx.location.capture("/redis_get",{
			    args={
				    key = k
				}
			})

	if res.status~=200 then
	    return false,res.body;
    else
        return redis_tools:read_reply( res.body )
	end
end


function redis_tools:set2(key,value)
local res = ngx.location.capture("/redis",
                { args = { query = "ping\\r\\n" } }
            )
            ngx.print("[" .. res.body .. "]")

end


function redis_tools:select( rds_db )
    local parser = require 'redis.parser'
    --[[
    local res = ngx.location.capture("/redis",
        { args = { query = "select 1\r\n" } }
    )
    ngx.print("[" .. res.body .. "]")
    --]]

    local res = ngx.location.capture("/redis",
        { args = { query = "set db1 123\r\n" } }
    )

    --local resa, typ = parser.parse_reply(res.body)
    --ngx.say(typ);
    --ngx.say(resa);ngx.exit(200);
    --ngx.print("[" .. res.body .. "]")

    local res1 = ngx.location.capture("/redis_get",
        { args = { key = "db0_1" } }
    )
    local resa, typ = parser.parse_reply(res1.body)
--    ngx.say(typ);
    ngx.say(resa);ngx.exit(200);
    --ngx.print("[" .. res.body .. "]")

end


--[[
-- 对tcp 获取到的redis数据进行解析，提取值
-- redis_receive_str   tcp获取的的原始值
-- --]]
function redis_tools:read_reply( redis_receive_str)
    if not redis_receive_str then
        return false,nil;
    end

    local prefix = byte(redis_receive_str)

    if prefix==36 then	--符号$，对redis进行get操作后的数据处理
        --处理不存在的key和值为空的key的情况
        local str_len = tonumber(sub(redis_receive_str,2))
        if str_len then
            if str_len<1 then
                return false,nil
            elseif str_len==0 then
                return true,null
            end
        end


        local find_crlf = string.find( redis_receive_str,"\r\n" )  --获取第一个换行符位置，以便获取第一个换行符左边字符串总数值
        local str_len = sub( redis_receive_str,2,find_crlf )  --获取第一个换行符左边字符串总数值
        local redis_value = sub( redis_receive_str,find_crlf+2,str_len+find_crlf+1)    --获取redis的值

        return true,redis_value;
    elseif prefix==43 then --符号+

        return true,sub(line, 2)
    elseif prefix==42 then --符号*


    elseif prefix==58 then --符号:

        return true,tonumber(sub(redis_receive_str, 2))
    elseif prefix==45 then --符号-，不存在的key
        return false, sub(redis_receive_str, 2)

    else
        return nil, "unkown prefix: \"" .. prefix .. "\""
    end
end



return redis_tools

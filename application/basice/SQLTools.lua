--[[
* @name : SQLtools.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017-03-27
* description : sql 语句工具类
--]]

local SQLtools = {}

local tools = require ("tools")

--[[
* 组装sql where 只有一个id 条件
--]]
function SQLtools:pack_sql_one_id(sql,boole,name,value)
    if value == nil then
        return boole,sql
    end

    -- if string.len(value) < 1 then
    --     return boole,sql
    -- end

    local value_type = type(value)
    if value_type == "number" then
        if boole then
            sql = string.format("%s%s%s%s%d",sql," and ",name,"=",value)
        else
            sql = string.format("%s%s%s%s%d",sql," where ",name,"=",value)
            boole = true
	    end
    elseif value_type == "string" then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name,"=",tools:quote_sql_str(value))
        else
            sql = string.format("%s%s%s%s%s",sql," where ",name,"=",tools:quote_sql_str(value))
            boole = true
        end
    end
    return boole,sql

end

--[[
* 组装sql where 大于|小于 条件
--]]
function SQLtools:pack_sql_ne_id(sql,boole,name,value)
    if value == nil then
        return boole,sql
    end

    if string.len(value) < 1 then
        return boole,sql
    end

    if boole then
        sql = string.format("%s%s%s%s",sql," and ",name,value)
    else
        sql = string.format("%s%s%s%s",sql," where ",name,value)
        boole = true
    end
    return boole,sql

end

--[[
* 组装sql where 多id 条件
--]]

function SQLtools:pack_sql_id(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local id = tools:split(value,",")  --多参数逗号分隔
    local size = table.getn(id)

    if size < 2 then
        if tonumber(id[1]) == nil then
	    return boole,sql
	end
        if boole then
            sql = string.format("%s%s%s%s%d",sql," and ",name," = ",tonumber(id[1]))
        else
            sql = string.format("%s%s%s%s%d",sql," where ",name," = ",tonumber(id[1]))
	    boole = true
        end
    else
        local is_first = true
        if boole then
            for i = 1,size ,1 do
    	        repeat
        		    if tonumber(id[i]) == nil then
        		        break
        		    end
        	            if is_first then
        		        sql = string.format("%s%s%s%s%d",sql," and ",name," in ( ",tonumber(id[i]))
                        is_first = false
        		    else
        		        sql = string.format("%s%s%d",sql,",",tonumber(id[i]))
        		    end
                until true
	        end
        else
    	    for i = 1,size ,1 do
    	        repeat
        		    if tonumber(id[i]) ==nil then
        		        break
        		    end
        	            if is_first then
        		        sql = string.format("%s%s%s%s%d",sql," where ",name," in ( ",tonumber(id[i]))
                        is_first = false
        		    else
        		        sql = string.format("%s%s%d",sql,",",tonumber(id[i]))
        		    end
        		    boole = true
    		    until true
    	    end
        end
	    sql = string.format("%s%s",sql,")")
    end

    return boole,sql
end

--[[
* 组装sql where 多id(字符串) 条件
--]]

function SQLtools:pack_sql_str_id(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local id = tools:split(value,",")  --多参数逗号分隔
    local size = table.getn(id)

    if size < 2 then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name," = ",tools:quote_sql_str(id[1]))
        else
            sql = string.format("%s%s%s%s%s",sql," where ",name," = ",tools:quote_sql_str(id[1]))
	    boole = true
        end
    else
        local is_first = true
        if boole then
	    for i = 1,size ,1 do
	        repeat
    		    if string.len( string.match(id[i],"%s*(.-)%s*$") ) == 0 then
    		        break
    		    end
                if is_first then
    		        sql = string.format("%s%s%s%s%s",sql," and ",name," in ( ",tools:quote_sql_str(id[i]))
                    is_first = false
    		    else
    		        sql = string.format("%s%s%s",sql,",",tools:quote_sql_str(id[i]))
    		    end
            until true
	    end

        else
           for i = 1,size ,1 do
	        repeat
    		    if string.len( string.match(id[i],"%s*(.-)%s*$") ) == 0 then
    		        break
    		    end
                if is_first then
    		        sql = string.format("%s%s%s%s%s",sql," where ",name," in ( ",tools:quote_sql_str(id[i]))
                    is_first = false
    		    else
    		        sql = string.format("%s%s%s",sql,",",tools:quote_sql_str(id[i]))
    		    end
    		    boole = true
            until true
	    end

        end

        sql = string.format("%s%s",sql,")")
    end

    return boole,sql
end

--[[
* 组装分页sql  条件
--]]

function SQLtools:pack_sql_page(sql,start,limit)

    local local_start = tonumber(start)
    local local_limit = tonumber(limit)

    if local_start == nil then
        if local_limit ~= nil then
	        -- if local_limit > 60 then
	        --     local_limit = 60
	        -- end
            sql = string.format("%s%s%d",sql," limit ",local_limit)
        else
            return sql
	    end
    else
        if local_limit == nil then
    	    -- if local_start > 60 then
    	    --     local_start = 60
    	    -- end
            sql = string.format("%s%s%d",sql," limit ",local_start)
	    else
    	    -- if local_limit > 60 then
    	    --     local_limit = 60
    	    -- end
            sql = string.format("%s%s%d%s%d",sql," limit ",local_start,",",local_limit)
	    end
    end
    return sql
end

--[[
* 组装sql where like 条件
--]]
function SQLtools:pack_sql_like(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local local_name = tools:quote_sql_str(value)
    local_name = "'%" ..string.gsub(local_name, "'", "") .."%'"

    if boole then
        sql = string.format("%s%s%s%s%s",sql," and ",name," like ",local_name)
    else
        sql = string.format("%s%s%s%s%s",sql," where ",name," like ",local_name)
	    boole = true
    end

    return boole,sql
end

--[[
* 组装sql where or like 条件
--]]
function SQLtools:pack_sql_or_like(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local local_name = tools:quote_sql_str(value)
    local_name = "'%" ..string.gsub(local_name, "'", "") .."%'"

    if boole then
        sql = string.format("%s%s%s%s%s",sql," or ",name," like ",local_name)
    else
        sql = string.format("%s%s%s%s%s",sql," where ",name," like ",local_name)
	    boole = true
    end

    return boole,sql
end

--[[
* 组装sql where like 条件(使用索引)
--]]
function SQLtools:pack_sql_index_like(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local local_name = tools:quote_sql_str(value)
    -- local_name = string.gsub(local_name, "'", "") .."%'"
    local_name = "'" .. string.gsub(local_name, "'", "") .."'"

    if boole then
        sql = string.format("%s%s%s%s%s",sql," and ",name," like ",local_name)
    else
        sql = string.format("%s%s%s%s%s",sql," where ",name," like ",local_name)
	    boole = true
    end

    return boole,sql
end

--[[
* 组装sql where 条件
--]]
function SQLtools:pack_sql_where(sql,boole,name,value)
    -- local local_sql =""
    if value == nil then
        return boole,sql
    end

    local value_type = type(value)
    if value_type == "number" then
        if boole then
            sql = string.format("%s%s%s%s%d",sql," and ",name,"=",value)
        else
            sql = string.format("%s%s%s%s%d",sql," where ",name,"=",value)
            boole = true
	    end
    elseif value_type == "string" then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name,"=",tools:quote_sql_str(value))
        else
            sql = string.format("%s%s%s%s%s",sql," where ",name,"=",tools:quote_sql_str(value))
            boole = true
        end
    end

    return boole,sql
end


--[[
* 组装sql where time条件
--]]
function SQLtools:pack_sql_where_time(sql,boole,name,starttime,endtime)
    -- local local_sql =""
    if name == nil then
        return boole,sql
    end

    if starttime ~= nil then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name," >= " ,tools:quote_sql_str(starttime))
        else
	        sql = string.format("%s%s%s%s%s",sql," where ",name," >= " ,tools:quote_sql_str(starttime))
            boole = true
	    end
    end

    if endtime ~= nil then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name," <= " ,tools:quote_sql_str(endtime))
        else
	        sql = string.format("%s%s%s%s%s",sql," where ",name," <= " ,tools:quote_sql_str(endtime))
            boole = true
	    end
    end

    return boole,sql
end

--[[
* 组装sql where time 条件(无 =)
--]]
function SQLtools:pack_sql_where_time_less(sql,boole,name,starttime,endtime)
    -- local local_sql =""
    if name == nil then
        return boole,sql
    end

    if starttime ~= nil then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name," >= " ,tools:quote_sql_str(starttime))
        else
	        sql = string.format("%s%s%s%s%s",sql," where ",name," >= " ,tools:quote_sql_str(starttime))
            boole = true
	    end
    end

    if endtime ~= nil then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," and ",name," < " ,tools:quote_sql_str(endtime))
        else
	        sql = string.format("%s%s%s%s%s",sql," where ",name," < " ,tools:quote_sql_str(endtime))
            boole = true
	    end
    end

    return boole,sql
end

--[[
* 组装sql insert 语句
--]]
function SQLtools:pack_sql_insert(sql_insert,sql_value,boole,name,value)
    if value == nil then
        return boole,sql_insert,sql_value
    end

    -- if string.len(value) < 1 then
    --     return boole,sql_insert,sql_value
    -- end

    if name == nil then
        return boole,sql_insert,sql_value
    end

    local value_type = type(value)

    if boole == nil then
        local start, endpos = string.find(sql_insert, "%(%s*%w")
	if start == nil then
	    boole = false
	else
	    boole = true
	end

    end

    if value_type == "number" then
        if boole then
            sql_insert = string.format("%s%s%s",sql_insert," , ",name)
	        sql_value = string.format("%s%s%d",sql_value," , ",value)
        else
	        sql_insert = string.format("%s%s",sql_insert,name)
            sql_value = string.format("%s%d",sql_value,value)
            boole = true
	    end
    elseif value_type == "string" then
        if boole then
            sql_insert = string.format("%s%s%s",sql_insert," , ",name)
	        sql_value = string.format("%s%s%s",sql_value," , ",tools:quote_sql_str(value))
        else
            sql_insert = string.format("%s%s",sql_insert,name)
	        sql_value = string.format("%s%s",sql_value,tools:quote_sql_str(value))
            boole = true
        end
    end

    return boole,sql_insert,sql_value
end


--[[
* 组装sql update 语句
--]]
function SQLtools:pack_sql_update(sql,boole,name,value)
    if value == nil then
        return boole,sql
    end

    if name == nil then
        return boole,sql
    end

    local value_type = type(value)
    if value_type == "number" then
        if boole then
            sql = string.format("%s%s%s%s%d",sql," , ",name,"=",value)
        else
	        sql = string.format("%s%s%s%d",sql,name,"=",value)
            boole = true
	    end
    elseif value_type == "string" then
        if boole then
            sql = string.format("%s%s%s%s%s",sql," , ",name,"=",tools:quote_sql_str(value))
        else
            sql = string.format("%s%s%s%s",sql,name,"=",tools:quote_sql_str(value))
            boole = true
        end
    end

    return boole,sql
end

--[[
* 组装sql update 字段自增 语句
--]]
function SQLtools:pack_sql_update_add(sql,boole,name,value)
    if value == nil then
        return boole,sql
    end

    if name == nil then
        return boole,sql
    end

    if boole then
        sql = string.format("%s%s%s%s%s%s%d",sql," , ",name,"=",name,"+",value)
    else
        sql = string.format("%s%s%s%s%s%d",sql,name,"=",name,"+",value)
        boole = true
    end

    return boole,sql
end

return SQLtools

--[[
* @name : tools.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017-03-27
* description :
--]]

local cjson = require "cjson"
local os_time = os.time

local tools = {}

function tools:encodeData(code,message,data,name)
    local res = {}
    res["code"] = code
    res["message"] = message
    if data == nil then
        res["data"] = {}
	    return res
    end

    res["data"] = data

    return res
end

function tools:errorinfo(code,message)
    return self:encodeData(tonumber(code),message,nil)
end

-- 计划舍弃掉(模块冲突)
function tools:get_object(rootpath,object_name)
    local ok, app = pcall(require, object_name)
    if not ok then
        package.path = package.path .. rootpath .. "/?.lua;"
	    app = require(object_name)
    end
    return app
end

-- 替代原来的 get_object
function tools:get_package_object(rel_path,object_name)
    local rel_path = rel_path
    -- 判断是否以 "/" 开头
    if string.byte(rel_path) == 47 then
        rel_path = string.sub(rel_path, 2)
    end
    local module_name = rel_path .. "/" .. object_name
    module_name = string.gsub(module_name, "/", ".")
    local ok, app = pcall(require, module_name)
    if not ok then
        -- 清空掉异常状态
        package.loaded[module_name] = nil
        ngx.status = 404
        return { run = function ()
            ngx.say(cjson.encode(self:encodeData(404,"have no this module found : " .. module_name)))
        end}
    end
    return app
end


function tools:get_request_param()
    local method = ngx.req.get_method()
    local args = {}
    if method == "POST" then
        ngx.req.read_body()
        args = ngx.req.get_post_args()
    elseif method == "GET" then
        args = ngx.req.get_uri_args()
    else
        return false ,nil
    end

    return true , args
 end

function tools:quote_sql_str(str)
    if str == nil or string.len(str) < 1 then
        return "''"
    end
    -- 使用 ngx.req.get_uri_args 会默认 decode arg
    -- 所以str 必须是已经 decode 过的 string()，解决%转义为空的问题
    -- return ngx.quote_sql_str(ngx.unescape_uri(str))
    return ngx.quote_sql_str(str)
end

-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function tools:split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char, 1, true);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

--[[
* 发送UDP操作日志，并打印到本地日志文件
* 参数，table类型
--]]

function tools:logs(data)
    local config = require("config")
    local json = cjson.encode(data)
    local sock = ngx.socket.udp()

    local ok, err = sock:setpeername(config.UDP_SERVER_HOST_DEFAULT or "logs.anyanapi.com", config.UDP_SERVER_PORT_DEFAULT or 20001)
    if ok then
        ok, err = udpsock:send(data )
        sock:close()
    end

    require "rolling_file"
    local logger = logging.rolling_file(config.UDP_LOG_NAME or "/data/logs/upd/data_api_access.log", config.UDP_LOGS_MAX or (10*1024),config.UDP_LOGS_FILE_MUX_NUM or 5)
    logger:info(data)
    return
end
-- 加载root_path 下所有lua文件
-- root_path 目录
function tools:loadluapath(root_path)
    if root_path == nil then
        return
    end
    local root_path = root_path .. "/?.lua;"
    if string.find(package.path,root_path,1,true) == nil then
        package.path = package.path .. root_path
    end
end

-- 加载指定lua文件
-- root_path 目录
function tools:loadluafile(file_path)
    if file_path == nil then
        return
    end
    if string.find(package.path,file_path,1,true) == nil then
        package.path = package.path .. ";" .. file_path
    end
end


function tools:send_config_udp_logs(code,node,filename)
    if code == nil then
        return
    end

    local data = {}
    data["codeid"] = code
    data["client_ip"] = ngx.var.remote_addr
    data["time"] = ngx.localtime()
    data["config_node"] = node
    data["config_file"] = filename

    local ok, jsondata = pcall(cjson.encode, data)
    if not ok then
        jsondata = string.format("%s{%s}%s","begin",jsondata,"end")
    else
        jsondata = string.format("%s%s%s","begin",jsondata,"end")
    end
    self:logs(jsondata)
end

function tools:send_mysql_udp_logs(codeid,mysql,nodename,filename,sql,errorno,sqlstate)
    if code == nil then
        return
    end
    local data = {}
    data["codeid"] = code
    data["mysql"] = mysql
    data["node_name"] = nodename
    data["config_file"] = filename
    data["sql"] = sql
    data["errorno"] = errorno
    data["sqlstate"] = sqlstate
    data["client_ip"] = ngx.var.remote_addr
    data["time"] = ngx.localtime()

    local ok, jsondata = pcall(cjson.encode, data)
    if not ok then
        jsondata = string.format("%s{%s}%s","begin",jsondata,"end")
    else
        jsondata = string.format("%s%s%s","begin",jsondata,"end")
    end
    self:logs(jsondata)
end


-- 迭代器
function tools:pairsByKeys(data)
    local a = {}
    for n in pairs(data) do
        a[#a+1] = n
    end
    table.sort(a)
    local i = 0
    return function()
    i = i + 1
    return a[i], data[a[i]]
    end
end

--[[
业务紧密函数，不做他用

将配置文件数据分库table转换为单层table，转换后方便检查数据分布分布
如:转换前
    tables = {
        [0] = {
	        max_sn = 40000000,
        },

        [1] = {
	        max_sn = 80000000,
        },
        [2] = {
	        max_sn = 10000000,
        },
    }
转换后：
    tables = {
        [40000000] = 0,

        [80000000] =1,
    }

--]]
function tools:table_convert(tables)
    local tb_data={}
    for k,v in pairs(tables) do
        tb_data[v.max_sn] = k
    end
    return tb_data
end

function tools:get_data_range(tables,id)
    local db_sn = 0
    if type(tables) ~= "table" then
        return db_sn
    end

    for key, value in self:pairsByKeys(self:table_convert(tables)) do
        if id <= key then
            db_sn = value
	        break;
	    end
    end
    return db_sn
end


function tools:get_db_range_node(tables,id,key_word)
    local db_node = nil
    if tables == nil then
        return db_node
    end
    if type(tables) ~= "table" then
        return db_node
    end

    for key, value in self:pairsByKeys(tables) do
        if id == key then
            db_node = value[key_word]
	        break;
	    end
    end
    return db_node
end

--[[
   获取数据库访问配置。
   public_node 数据库公用配置节点
   access_node 业务数据访问配置
   注意：
       所有配置项优先使用业务访问配置项，方便后期单独配置
--]]

function tools:get_db_config(node,user,password)
    local node_new = {}                          

    node_new["host"] = node.host

    node_new["port"] = node.port or 3306

    node_new["database"] = node.database

    node_new["timeout"] = node.timeout or 10 * 1000

    node_new["max_packet_size"] = node.max_packet_size or 1024*1024

    node_new["user"] = node.user or user

    node_new["password"] = node.password or password

    return node_new
end

-- 打印一个变量，可以是string，number或table
function tools:print_r(ar,sp)
    if sp == nil then
        sp="";
    end
    if type(ar)=="table" then
        local k,v;
        ngx.say("{<br>");
        for k,v in pairs(ar) do
            if type(v)=="table" then
                ngx.print(sp,"　",k,"=");
                tools:print_r(v,sp.."　");
            else
                ngx.say(sp,"　",k,"=\"",v,"\",<br>");
            end
        end
        ngx.say(sp,"}<br>");
    else
        ngx.say(sp,ar,"<br>");
    end
end

-- table:       转换为树形结构
-- res:         需转换的table
-- keyNodeId:   标识ID标识字段
-- keyParentId: 父节点id标识字段

function tools:table_totree(res,keyNodeId, keyParentId , keyChildrens)
    if type(res) ~= "table" then
        return {}
    end

    local tree = {}

    local refs ={}

    for key, value in pairs(res) do
        res[key][keyChildrens] = {}
        refs[value[keyNodeId]] = value;
    end

    for key, value in pairs(res) do
        parentId = value[keyParentId]
        repeat
            if parentId then
                if refs[parentId] == nil then
	                table.insert(tree,value)
	                break
                end
                local parent = refs[parentId]
                table.insert(parent[keyChildrens],value)
           else
                table.insert(tree,value)
           end
        until true
    end
    return tree
end

function tools:decodeJson(jsondata)
    return pcall(cjson.decode, jsondata)
end

function tools:decodeData(jsondata, ...)
    local ok, object = pcall(cjson.decode, jsondata)
    if not ok then
        return false, object
    end

    if not next(object.data) then
        return true, {}
    end

    local res = {}
    for i=1,select('#', ...) do
        local arg = select(i, ...)
        res[i] = object.data[1][arg] or nil
    end

    return true, res
end

-- 解析json
function tools:json_decode( json_str )
    local ok,data = pcall( cjson.decode,json_str )

    if not ok then
        return false,json_str
    end

    return true,data;
end


function tools:converTimestamp(str)
    if tonumber(str) then
        return str
    end

    local pattern = "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"
    local year,mon,day,hour,min,sec = str:match(pattern)
    local timestamp = os.time({year = year, month = mon, day = day, hour = hour, min = min, sec = sec})
    return timestamp
end

return tools

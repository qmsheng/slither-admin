--[[
* @name : index.lua
* @author : qmsheng
* @version : 1.0
* @data : 2017/03/27
* description : main目录
--]]

local menu = {
    "userlist","roomlist","serverinfo"
}

return function(self)
    self.page_title = "Index"
    self.menu = menu
    return {render = "index"}
end

local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')
local doAction = require('actions/action')

---@type RunningDir
local runningDir = luaUtils.RunningDir:new()

local function search()
  local command = string.format('/lua run "%s"', "inventory/export")
  doAction(command)
end

return search
local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')
local remoteAction = require('actions/remoteAction')

---@type RunningDir
local runningDir = luaUtils.RunningDir:Parent()

local function search()
  local command = string.format('/lua run "%s"', runningDir:GetRelativeToMQLuaPath("/export"))
  remoteAction(command)
end

return search
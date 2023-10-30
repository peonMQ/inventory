local runningDir = require('lib/runningdir')
local remoteAction = require('actions/remoteAction')

---@type RunningDir
local exportScriptPath = runningDir:Parent():GetRelativeToMQLuaPath("/export")

local function search()
  local command = string.format('/lua run "%s"', exportScriptPath)
  remoteAction(command)
end

return search
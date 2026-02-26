local mq = require 'mq'
local logger = require('knightlinc/Write')
local runningDir = require('lib/runningdir')
local remoteAction = require('actions/remoteAction')

---@type RunningDir
local searchScriptPath = runningDir:Parent():GetRelativeToMQLuaPath("/linkitem")

---@param character string
---@param item SearchItemResult
local function linkitem(character, item)
  logger.Debug('Trigger linkitem action')
  if character == mq.TLO.Me.Name() then
    mq.cmdf("/say %s", item.ItemLink)
  else
    local command = string.format('/lua run %s "%s"', searchScriptPath, item.ItemId)
    remoteAction(command, character)
  end
end

return linkitem
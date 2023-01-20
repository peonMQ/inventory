--- @type Mq
local mq = require 'mq'
local logger = require('utils/logging')
local broadcaster = require('broadcast/broadcastinterface')()

---@param command string
---@param character? string
local function doAction(command, character)
  if broadcaster then
    if character then
      broadcaster.ExecuteCommand(command, {character})
    else
      broadcaster.ExecuteAllCommand(command, true)
    end
  else
    logger.Warn("Dannet or EQBC is required to do remote item pickups")
  end
end

return doAction
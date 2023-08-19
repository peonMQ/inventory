--- @type Mq
local mq = require 'mq'
local logger = require('utils/logging')
local doAction = require('actions/action')

---@param character string
---@param item SearchItem
local function useitem(character, item)
  if item.InventorySlot >= 2000 then
    logger.Warn("Cannot use item from a bankslot.")
    return
  end

  local command = string.format('/useitem "%s"', item.Name)
  if character == mq.TLO.Me.Name() then
    mq.cmd(command)
  else
    doAction(command, character)
  end
end

return useitem
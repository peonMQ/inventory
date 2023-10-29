local mq = require 'mq'
local logger = require('utils/logging')
local doAction = require('actions/action')

---@param character string
---@param item SearchItem
local function pickupItem(character, item)
  if item.InventorySlot >= 2000 then
    logger.Warn("Cannot pick up item from a bankslot.")
    return
  end

  local command = ""
  local packslot = item.InventorySlot - 22
  if item.BagSlot > -1 then
    command = string.format('/nomodkey /itemnotify in pack%d %d leftmouseup', packslot, item.BagSlot+1)
  else
    command = string.format('/nomodkey /itemnotify pack%d leftmouseup', packslot)
  end

  if character == mq.TLO.Me.Name() then
    mq.cmd(command)
  else
    doAction(command, character)
  end
end

return pickupItem
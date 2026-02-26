local mq = require 'mq'
local logger = require('knightlinc/Write')
local remoteAction = require('actions/remoteAction')

---@param character string
---@param item SearchItemResult
local function requestItem(character, item)
  if item.InventorySlot >= 2000 then
    logger.Warn("Cannot pick up item from a bankslot.")
    return
  end

  local spawn = mq.TLO.Spawn('pc ='..character)
  if not spawn() or spawn.Distance3D() > 15 then
    logger.Warn("Character not online or outisde trade range.")
    return
  end

  local command = ""
  local packslot = item.InventorySlot - 22
  if item.BagSlot > -1 then
    command = string.format('/nomodkey /itemnotify in pack%d %d leftmouseup', packslot, item.BagSlot+1)
  else
    command = string.format('/nomodkey /itemnotify pack%d leftmouseup', packslot)
  end

  remoteAction(command, character)
  mq.delay(200)
  remoteAction('/mqtar '..mq.TLO.Me.CleanName(), character)
  mq.delay(200)
  remoteAction('/click left target', character)
  mq.delay(2000, function() return mq.TLO.Window('TradeWnd').Open() end)
  mq.delay(200)
  remoteAction('/timed 5 /yes', character)
  mq.delay(500)
  mq.cmdf('/yes')
end

return requestItem
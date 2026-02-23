local mq = require 'mq'
local logger = require 'knightlinc/Write'
local broadcast = require('broadcast/broadcast')

broadcast.prefix = broadcast.ColorWrap('[LinkItem]', 'Cyan')
logger.prefix = string.format("\at%s\ax", "[LinkItem]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

local args = {...}

---@param itemId number
local function linkItem(itemId)
  if not itemId or not tonumber(itemId) then
    logger.Warn("ItemId is not valid <%s>", itemId)
    return
  end

  local item = mq.TLO.FindItem(itemId)

  if not item() then
    item = mq.TLO.FindItemBank(itemId)
  end

  if not item() then
    broadcast.Fail("Item with Id not found <%s>", itemId)
  else
    local reportString = string.format('<%s>', item.ItemLink("CLICKABLE")())
    broadcast.SuccessAll("%s", reportString)
  end

  logger.Info("Completed linkItem for %s", itemId)
end

linkItem(args[1])
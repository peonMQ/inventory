--- @type Mq
local mq = require('mq')
local logger = require('utils/logging')
local luautils = require('utils/lua-table')

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
    logger.Warn("ItemId not found <%s>", itemId)
  else
    local reportString = string.format('<%s>', item.ItemLink("CLICKABLE")())
    mq.cmdf("/say %s", reportString)
  end

  logger.Info("Completed linkItem for <%s>", itemId)
end

linkItem(args[1])
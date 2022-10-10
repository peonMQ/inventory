--- @type Mq
local mq = require('mq')
local logger = require('utils/logging')
local luautils = require('utils/lua')

---@type RunningDir
local runningDir = luautils.RunningDir:new()
runningDir:AppendToPackagePath()

--- @type SearchItem
local searchItem = require(runningDir:Parent():GetRelativeToMQLuaPath('common/searchitem'))

local next = next
local maxInventorySlots = 32
local maxBankSlots = 8

---@param item item
---@return SearchItem
local function convert(item)
  return searchItem:new(item.ID(), item.Name(), item.Stack(), item.ItemSlot(), item.ItemSlot2())
end

local function exportInventory()
  local export = {
    inventory = {},
    bank = {}
  }

  local inventory = mq.TLO.Me.Inventory
  for i=1, maxInventorySlots do
    local item = inventory(i) --[[@as item]]
    if item() then
      export.inventory[#export.inventory+1] = convert(item)
    end

    if item.Container() and item.Container() > 0 then
      for i=1,item.Container() do
        local containerItem = item.Item(i)
        if containerItem() then
          export.inventory[#export.inventory+1] = convert(containerItem)
        end
      end
    end
  end
  

  local bank = mq.TLO.Me.Bank
  for i=1, maxBankSlots do
    local item = bank(i) --[[@as item]]
    if item() then
      export.inventory[#export.inventory+1] = convert(item)
    end

    if item.Container() and item.Container() > 0 then
      for i=1,item.Container() do
        local containerItem = item.Item(i)
        if containerItem() then
          export.inventory[#export.inventory+1] = convert(containerItem)
        end
      end
    end
  end

  if not next(export) then
    logger.Info("No items to export.")
    return
  end

  local configDir = mq.configDir.."/"
  local serverName = mq.TLO.MacroQuest.Server()
  local fileName =  string.format("%s/%s/Export/Inventory/%s.lua", configDir, serverName, mq.TLO.Me.Name())
  luautils.SaveTable(fileName, export)
end

exportInventory()
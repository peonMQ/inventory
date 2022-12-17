--- @type Mq
local mq = require('mq')

local function findItemLink(id)
  local item = mq.TLO.FindItem(id)
  if item() ~= nil then
      return item.ItemLink("CLICKABLE")()
  end

  return nil
end

---@class SearchItem
---@field public Id number
---@field public Name string
---@field public Amount number
---@field public InventorySlot number
---@field public BagSlot number
---@field public ItemLink string
local SearchItem = {Id = 0, Name = "", Amount = 0, InventorySlot = 0, BagSlot = -1, ItemLink= ""}

---@param id number
---@param name string
---@param amount number
---@param inventorySlot number
---@param bagSlot number
---@return SearchItem
function SearchItem:new (id, name, amount, inventorySlot, bagSlot)
  self.__index = self
  local o = setmetatable({}, self)
  o.Id = id or error("Id required.")
  o.Name = name or error("Name is required.")
  o.Amount = amount or error("Amount is required.")
  o.InventorySlot = inventorySlot or error("InventorySlot is required.")
  o.BagSlot = bagSlot or -1
  o.ItemLink = findItemLink(id) or ""
  return o
end

---@return string
function SearchItem:HumanInventorySlot ()
  if self.InventorySlot == 0 then
    return "Charm"
  elseif self.InventorySlot == 1 then
    return "Left Ear"
  elseif self.InventorySlot == 2 then
      return "Head"
  elseif self.InventorySlot == 3 then
      return "Face"
  elseif self.InventorySlot == 4 then
      return "Right Ear"
  elseif self.InventorySlot == 5 then
      return "Neck"
  elseif self.InventorySlot == 6 then
    return "Shoulder"
  elseif self.InventorySlot == 7 then
      return "Arms"
  elseif self.InventorySlot == 8 then
      return "Back"
  elseif self.InventorySlot == 9 then
      return "Left Wrist"
  elseif self.InventorySlot == 10 then
      return "Right Wrist"
  elseif self.InventorySlot == 11 then
    return "Ranged"
  elseif self.InventorySlot == 12 then
      return "Hands"
  elseif self.InventorySlot == 13 then
      return "Mainhand"
  elseif self.InventorySlot == 14 then
      return "Offhand"
  elseif self.InventorySlot == 15 then
      return "Left Finger"
  elseif self.InventorySlot == 16 then
    return "Right Finger"
  elseif self.InventorySlot == 17 then
      return "Chest"
  elseif self.InventorySlot == 18 then
      return "Legs"
  elseif self.InventorySlot == 19 then
      return "Feet"
  elseif self.InventorySlot == 20 then
      return "Waist"
  elseif self.InventorySlot == 21 then
      return "Powersource"
  elseif self.InventorySlot == 22 then
      return "Ammo"
  elseif self.InventorySlot >= 23 and self.InventorySlot <= 32 then
      return "Bag"..(self.InventorySlot-22)
  elseif self.InventorySlot >= 2000 and self.InventorySlot <= 2023 then
      return "Bank"..(self.InventorySlot-2000+1)
  elseif self.InventorySlot >= 2500 and self.InventorySlot <= 2501 then
      return "SharedBank"..(self.InventorySlot-2500+1)
  end

  error("Unable to translate inventoryslot: "..self.InventorySlot)
end

---@return boolean
function SearchItem:CanPickUp ()
  return self.InventorySlot >= 23 and self.InventorySlot <= 32
end

---@return string
function SearchItem:HumanBagSlot ()
  if self.BagSlot > -1 then
    return ""..(self.BagSlot+1)
  end

  return ""
end

---@return string
function SearchItem:ToReportString ()
  return string.format("%s;%s;%s;%s;%s", self.Id, self.Name, self.Amount, self.InventorySlot, self.BagSlot)
end

---@param searchTerms string
---@return boolean
function SearchItem:MatchesSearchTerms(searchTerms)
  local text = self.Name:lower()
  for searchTerm in string.gmatch(searchTerms:lower(), "%S+") do
    if not text:find(searchTerm) then
      return false
    end
  end

  return true
end

return SearchItem
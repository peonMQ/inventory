local mq = require('mq')
local logger = require 'knightlinc/Write'

---@param item item
---@return string[]
local function parseClasses(item)
  local classes = {}
  for i=1, item.Classes() do
    classes[#classes+1] = item.Class(i).Name()
  end

  return classes
end

---@param item item
---@return string[]
local function parseWornSlots(item)
  local classes = {}
  for i=1, item.WornSlots() do
    classes[#classes+1] = item.WornSlot(i).Name()
  end

  return classes
end

local function findItemLink(id)
  local item = mq.TLO.FindItem(id)
  if item() ~= nil then
      return item.ItemLink("CLICKABLE")()
  end
  
  item = mq.TLO.FindItemBank(id)
  if item() ~= nil then
      return item.ItemLink("CLICKABLE")()
  end

  return nil
end

local function findItemIcon(id)
  local item = mq.TLO.FindItem(id)
  if item() ~= nil then
      return item.Icon()
  end

  item = mq.TLO.FindItemBank(id)
  if item() ~= nil then
      return item.Icon()
  end

  return nil
end

---@class SearchItem
---@field public Id number
---@field public Name string
---@field public Type string
---@field public Icon number
---@field public Amount number
---@field public InventorySlot number
---@field public BagSlot number
---@field public Container number
---@field public Damage number
---@field public Classes string[]
---@field public WornSlots string[]
---@field public ItemLink string
local SearchItem = {Id = 0, Name = "", Type = "", Icon = 0, Amount = 0, InventorySlot = 0, BagSlot = -1, Container = 0, Damage = 0, Classes = {}, WornSlots = {}, ItemLink= ""}

---@param id number
---@param name string
---@param type string
---@param amount number
---@param inventorySlot number
---@param bagSlot number
---@param container number
---@param icon number
---@param damage number
---@param classes string[]
---@param wornSlots string[]
---@param itemLink string|nil
---@return SearchItem
function SearchItem:new (id, name, type, amount, inventorySlot, bagSlot, container, icon, damage, classes, wornSlots, itemLink)
  self.__index = self
  local o = setmetatable({}, self)
  o.Id = id or error("Id required.")
  o.Name = name or error("Name is required.")
  o.Type = type or error("Type is required.")
  o.Amount = amount or error("Amount is required.")
  o.InventorySlot = inventorySlot or error("InventorySlot is required.")
  o.BagSlot = bagSlot or -1
  o.Container = container or 0
  o.Damage = damage or 0
  o.Classes = classes or error("Classes is required.")
  o.WornSlots = wornSlots or error("WornSlots is required.")
  o.ItemLink = itemLink or findItemLink(id) or ""
  o.Icon = findItemIcon(id) or icon or 0
  return o
end


---@param item item
---@param prefixNum? number
---@return SearchItem
function SearchItem:convert (item, prefixNum)
  return SearchItem:new(item.ID(), item.Name(), item.Type(), item.Stack(), item.ItemSlot() + (prefixNum or 0), item.ItemSlot2(), item.Container(), item.Icon(), item.Damage(), parseClasses(item), parseWornSlots(item), item.ItemLink("CLICKABLE")())
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

---@return boolean
function SearchItem:IsInBank ()
  return self.InventorySlot >= 2000 and self.InventorySlot <= 2023
end

---@return boolean
function SearchItem:IsEquipped ()
  return self.InventorySlot >= 0 and self.InventorySlot <= 22
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
  return string.format("<%s;%s;%s;%s;%s;%s>", self.Id, self.Name, self.Amount, self.InventorySlot, self.BagSlot, self.Icon)
end

return SearchItem
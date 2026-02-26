---@class SearchItemResult
---@field public CharacterName string
---@field public Online boolean
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
local SearchItemResult = {CharacterName  = "", Online = false, Id = 0, Name = "", Type = "", Icon = 0, Amount = 0, InventorySlot = 0, BagSlot = -1, Container = 0, Damage = 0, Classes = {}, WornSlots = {}, ItemLink= ""}

---@param character string
---@param online boolean
---@param item SearchItem
---@return SearchItemResult
function SearchItemResult:convert (character, online, item)
  self.__index = self
  local o = setmetatable({}, self)
  o.CharacterName = character or error("CharacterName is required.")
  o.Online = online or false
  o.Id = item.Id
  o.Name = item.Name
  o.Type = item.Type
  o.Amount = item.Amount
  o.InventorySlot = item.InventorySlot
  o.BagSlot = item.BagSlot
  o.Container = item.Container
  o.Damage = item.Damage
  o.Classes = item.Classes
  o.WornSlots = item.WornSlots
  o.ItemLink = item.ItemLink
  o.Icon = item.Icon
  return o
end

---@return string
function SearchItemResult:HumanInventorySlot ()
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
function SearchItemResult:CanPickUp ()
  return self.InventorySlot >= 23 and self.InventorySlot <= 32
end

---@return boolean
function SearchItemResult:IsInBank ()
  return self.InventorySlot >= 2000 and self.InventorySlot <= 2023
end

---@return boolean
function SearchItemResult:IsEquipped ()
  return self.InventorySlot >= 0 and self.InventorySlot <= 22
end

---@return string
function SearchItemResult:HumanBagSlot ()
  if self.BagSlot > -1 then
    return ""..(self.BagSlot+1)
  end

  return ""
end

return SearchItemResult
local logger = require 'knightlinc/Write'


---@param inputstr string
---@param separator string
---@return table
local function split (inputstr, separator)
  if separator == nil then
     separator = "%s"
  end

  local subStrings={}
  for subString in string.gmatch(inputstr, "([^"..separator.."]+)") do
     table.insert(subStrings, subString)
  end
  return subStrings
end

---@param item item
---@param searchTerms string
---@return boolean
local function matchesSearchTerms(item, searchTerms)
  local text = item.Name():lower()
  for searchTerm in string.gmatch(searchTerms:lower(), "%S+") do
    if not text:find(searchTerm) then
      return false
    end
  end

  return true
end

---@param item item
---@param filter string
---@return boolean
local function matchesSlotFilter(item, filter)
  if filter == "any" then
    return true
  end

  return item.WornSlot(filter)()
end

---@param item item
---@param filter string
---@return boolean
local function matchesTypeFilter(item, filter)
  if filter == "any" then
    return true
  end

  return (filter == 'weapon' and (item.Damage() > 0 or item.Type() == 'Shield'))
          or (filter == 'container' and item.Container() > 0)
          or item.Type() == filter
end

---@param item item
---@param filter string
---@return boolean
local function matchesClassFilter(item, filter)
  if filter == "any" then
    return true
  end

  if item.Classes() == 16 or item.Class(filter)() then
    return true
  end

  return false
end

---@param item item
---@param filter string
---@return boolean
local function matchesLocationFilter(item, isBank, filter)
  if filter == "any" then
    return true
  end

  return (filter == 'inventory' and not (isBank))
          or (filter == 'bank' and (isBank))
          or (filter == 'equiped' and item.ItemSlot() < 23)
end

---@class SearchParams
---@field public Terms string
---@field public SlotFilter string
---@field public TypeFilter string
---@field public ClassFilter string
---@field public LocationFilter string
local SearchParams = { Terms=""; SlotFilter="any", TypeFilter="any", ClassFilter="any", LocationFilter="any" }

---@param terms string
---@param slotFilter string
---@param typeFilter string
---@param classFilter string
---@param locationFilter string
---@return SearchParams
function SearchParams:new(terms, slotFilter, typeFilter, classFilter, locationFilter)
  self.__index = self
  local o = setmetatable({}, self)
  o.Terms = terms or error("Terms is required.")
  o.SlotFilter = slotFilter or "any"
  o.TypeFilter = typeFilter or "any"
  o.ClassFilter = classFilter or "any"
  o.LocationFilter = locationFilter or "any"
  return o
end

function SearchParams:Matches(item, isBank)
  if not matchesSearchTerms(item, self.Terms) then
    logger.Debug("Did not match terms for %s", item.Name())
    return false
  end

  if not matchesSlotFilter(item, self.SlotFilter) then
    logger.Debug("Did not match slotfilter for %sfor filter <%s>", item.Name(), self.SlotFilter)
    return false
  end

  if not matchesTypeFilter(item, self.TypeFilter) then
    logger.Debug("Did not match typefilter for %s for filter <%s>", item.Name(), self.TypeFilter)
    return false
  end

  if not matchesClassFilter(item, self.ClassFilter) then
    logger.Debug("Did not match classfilter for %s for filter <%s>", item.Name(), self.ClassFilter)
    return false
  end

  if not matchesLocationFilter(item, isBank, self.LocationFilter) then
    logger.Debug("Did not match locationfilter for %sfor filter <%s>", item.Name(), self.LocationFilter)
    return false
  end

  return true
end

function SearchParams:parse(paramsString)
  local params = split(paramsString, ";")
  if #params ~= 5 then
    logger.Error("Error in parsing search params");
  end

  return SearchParams:new(params[1], params[2], params[3], params[4], params[5])
end

---@return string
function SearchParams:ToSearchString ()
  return string.format("%s;%s;%s;%s;%s", self.Terms, self.SlotFilter, self.TypeFilter, self.ClassFilter, self.LocationFilter)
end

return SearchParams
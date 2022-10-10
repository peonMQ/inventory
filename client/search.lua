--- @type Mq
local mq = require('mq')
local logger = require('utils/logging')
local luautils = require('utils/lua')

---@type RunningDir
local runningDir = luautils.RunningDir:new()
runningDir:AppendToPackagePath()

--- @type SearchItem
local searchItem = require('inventory/common/searchitem')

local next = next
local args = {...}
local maxInventorySlots = 32
local maxBankSlots = 8

---@param item item
---@return SearchItem
local function convert(item)
  return searchItem:new(item.ID(), item.Name(), item.Stack(), item.ItemSlot(), item.ItemSlot2())
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
---@return boolean, SearchItem|nil
local function matchItem(item, searchTerms)
  if item() and matchesSearchTerms(item, searchTerms) then
    return true, convert(item)
  end

  return false, nil
end

---@param container item
---@param searchTerms string
---@return SearchItem[]
local function findItemInContainer(container, searchTerms)
  logger.Debug("findItemInContainer <%s> <%s>", container.Name(), container.Container())
  local searchResult = {}
  for i=1,container.Container() do
    local item = container.Item(i)
    local success, matchedItem = matchItem(item, searchTerms)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end
  end

  return searchResult
end

---@param searchTerms string
---@return SearchItem[]
local function findItemInInventory(searchTerms)
  logger.Debug("Seaching inventory for [%s]", searchTerms)
  local searchResult = {}
  local inventory = mq.TLO.Me.Inventory
  for i=1, maxInventorySlots do
    local item = inventory(i) --[[@as item]]
    local success, matchedItem = matchItem(item, searchTerms)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end

    if item.Container() and item.Container() > 0 then
      local containerSearchResult = findItemInContainer(item, searchTerms)
      luautils.TableConcat(searchResult, containerSearchResult)
    end
  end
  
  return searchResult
end

---@param searchTerms string
---@return SearchItem[]
local function findItemInBank(searchTerms)
  logger.Debug("Seaching bank for [%s]", searchTerms)
  local searchResult = {}
  local bank = mq.TLO.Me.Bank
  for i=1, maxBankSlots do
    local item = bank(i) --[[@as item]]
    local success, matchedItem = matchItem(item, searchTerms)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end

    if item.Container() and item.Container() > 0 then
      local containerSearchResult = findItemInContainer(item, searchTerms)
      luautils.TableConcat(searchResult, containerSearchResult)
    end
  end
  
  return searchResult
end

local function findItems(searchTerms)
  local searchResults = {}
  logger.Info("Starting search for <"..searchTerms..">")
  
  -- Search inventory
  local inventorySearchResult = findItemInInventory(searchTerms:lower())
  luautils.TableConcat(searchResults, inventorySearchResult)

  -- Search bank
  local bankSearchResult = findItemInBank(searchTerms:lower())
  luautils.TableConcat(searchResults, bankSearchResult)

  return searchResults
end

local minSearchTextLength = 3
---@param reportToo string
---@param searchTerms string
local function findAndReportItems(reportToo, searchTerms)
  if not reportToo then
    logger.Warn("<reportToo> is <nil>")
    return
  end

  if not searchTerms then
    logger.Warn("Searchtext is <nil>")
    return
  end
  
  if #searchTerms < minSearchTextLength then
    logger.Warn("Searchtext is to short <%d>, must me minimum %d characters.", #searchTerms, minSearchTextLength)
    return
  end

  local searchResults = findItems(searchTerms)

  if not next(searchResults) then
    logger.Info("Done, nothing found for <"..searchTerms..">", reportToo)
  else
    for _,searchitem in ipairs(searchResults) do 
      mq.cmdf('/bct %s <%s>', reportToo, searchitem:ToEQBCString())
    end
  
    logger.Info("Done search for <"..searchTerms..">", reportToo)
  end
end

findAndReportItems(args[1], args[2])
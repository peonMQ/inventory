local mq = require('mq')
local logger = require('utils/logging')
local luautils = require('utils/lua-table')
local broadcast = require('broadcast/broadcast')
local broadCastInterface = require('broadcast/broadcastinterface')()

--- @type SearchItem
local searchItem = require('common/searchitem')

local next = next
local args = {...}
local maxInventorySlots = 32
local maxBankSlots = 16

---@param item item
---@param prefixNum? number
---@return SearchItem
local function convert(item, prefixNum)
  return searchItem:new(item.ID(), item.Name(), item.Stack(), item.ItemSlot() + (prefixNum or 0), item.ItemSlot2())
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
---@param prefixNum? number
---@return boolean, SearchItem|nil
local function matchItem(item, searchTerms, prefixNum)
  if item() and matchesSearchTerms(item, searchTerms) then
    return true, convert(item, prefixNum)
  end

  return false, nil
end

---@param container item
---@param searchTerms string
---@param prefixNum? number
---@return SearchItem[]
local function findItemInContainer(container, searchTerms, prefixNum)
  logger.Debug("findItemInContainer <%s> <%s>", container.Name(), container.Container())
  local searchResult = {}
  for i=1,container.Container() do
    local item = container.Item(i)
    local success, matchedItem = matchItem(item, searchTerms, prefixNum)
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
    local success, matchedItem = matchItem(item, searchTerms, 2000)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end

    if item.Container() and item.Container() > 0 then
      local containerSearchResult = findItemInContainer(item, searchTerms, 2000)
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
    logger.Info("Done, nothing found for <%s>", searchTerms)
  else
    for _,searchitem in ipairs(searchResults) do
      if broadCastInterface then
        broadCastInterface.Broadcast(searchitem:ToReportString(), {reportToo})
      else
        logger.Warn("Dannet or EQBC is required to do online searches")
      end
    end

    if broadCastInterface then
      broadcast.Success("Completed search for <%s>", searchTerms)
    else
      logger.Info("Completed search for <%s>", searchTerms)
    end
  end
end

findAndReportItems(args[1], args[2])
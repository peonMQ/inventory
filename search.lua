local mq = require('mq')
local logger = require('knightlinc/Write')
local broadcast = require('broadcast/broadcast')
local broadCastInterface = require('broadcast/broadcastinterface')()

local searchItem = require 'common/searchitem'
local searchParams = require 'common/searchparams'

broadcast.prefix = '[Search]'
logger.prefix = string.format("\at%s\ax", "[Search]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

local next = next
local args = {...}
local maxInventorySlots = 22 + mq.TLO.Me.NumBagSlots()
local maxBankSlots = mq.TLO.Inventory.Bank.BagSlots()

---@param t1 table
---@param t2 table
---@return table
local function tableConcat(t1,t2)
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
  return t1
end

---@param item item
---@param prefixNum? number
---@return SearchItem
local function convert(item, prefixNum)
  return searchItem:new(item.ID(), item.Name(), item.Stack(), item.ItemSlot() + (prefixNum or 0), item.ItemSlot2())
end

---@param item item
---@param searchParams SearchParams
---@param isBank boolean?
---@param prefixNum? number
---@return boolean, SearchItem|nil
local function matchItem(item, searchParams, isBank, prefixNum)
  if item() and searchParams:Matches(item, isBank) then
    return true, convert(item, prefixNum)
  end

  return false, nil
end

---@param container item
---@param searchParams SearchParams
---@param isBank boolean?
---@param prefixNum? number
---@return SearchItem[]
local function findItemInContainer(container, searchParams, isBank, prefixNum)
  logger.Debug("findItemInContainer <%s> <%s>", container.Name(), container.Container())
  local searchResult = {}
  for i=1,container.Container() do
    local item = container.Item(i)
    local success, matchedItem = matchItem(item, searchParams, isBank, prefixNum)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end
  end

  return searchResult
end

---@param searchParams SearchParams
---@return SearchItem[]
local function findItemInInventory(searchParams)
  logger.Debug("Seaching inventory for [%s]", searchParams:ToSearchString())
  local searchResult = {}
  local inventory = mq.TLO.Me.Inventory
  for i=1, maxInventorySlots do
    local item = inventory(i) --[[@as item]]
    local success, matchedItem = matchItem(item, searchParams)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end

    if item.Container() and item.Container() > 0 then
      local containerSearchResult = findItemInContainer(item, searchParams)
      tableConcat(searchResult, containerSearchResult)
    end
  end

  return searchResult
end

---@param searchParams SearchParams
---@return SearchItem[]
local function findItemInBank(searchParams)
  logger.Debug("Seaching bank for [%s]", searchParams:ToSearchString())
  local searchResult = {}
  local bank = mq.TLO.Me.Bank
  for i=1, maxBankSlots do
    local item = bank(i) --[[@as item]]
    local success, matchedItem = matchItem(item, searchParams, true, 2000)
    if success then
      searchResult[#searchResult+1] = matchedItem
    end

    if item.Container() and item.Container() > 0 then
      local containerSearchResult = findItemInContainer(item, searchParams, true, 2000)
      tableConcat(searchResult, containerSearchResult)
    end
  end

  return searchResult
end

---@param searchParams SearchParams
---@return table<SearchItem>
local function findItems(searchParams)
  local searchResults = {}
  logger.Info("Starting search for <"..searchParams:ToSearchString()..">")

  -- Search inventory
  local inventorySearchResult = findItemInInventory(searchParams)
  tableConcat(searchResults, inventorySearchResult)

  -- Search bank
  local bankSearchResult = findItemInBank(searchParams)
  tableConcat(searchResults, bankSearchResult)

  return searchResults
end

---@param reportToo string
---@param params string
local function findAndReportItems(reportToo, params)
  if not reportToo then
    logger.Warn("<reportToo> is <nil>")
    return
  end

  if not params then
    logger.Warn("Search Params is <nil>")
    return
  end

  local searchParahms = searchParams:parse(params)
  local searchResults = findItems(searchParahms)

  if not next(searchResults) then
    logger.Info("Done, nothing found for <%s>", params)
  else
    for _,searchitem in ipairs(searchResults) do
      broadCastInterface.Broadcast(searchitem:ToReportString(), {reportToo})
    end

    broadcast.SuccessAll("Completed search for <%s>", params)
  end
end

findAndReportItems(args[1], args[2])
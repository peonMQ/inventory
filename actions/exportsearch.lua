local logger = require 'knightlinc/Write'
local repository = require 'inventoryRepository'
local broadcaster = require('broadcast/broadcastinterface')("EQBC")
local searchItemResult = require('common/searchitemresult')

local next = next

---@class ExportItem
---@field Id number
---@field Name string
---@field Amount number
---@field InventorySlot number
---@field BagSlot number

---@param inputstr string
---@param separator string|nil
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

local function contains_ignore_case(tbl, value)
    value = value:lower()
    for _, v in ipairs(tbl) do
        if v:lower() == value then
            return true
        end
    end
    return false
end

---@param searchParams SearchParams
---@param exportItems SearchItem[]
---@return SearchItem[]
local function matchItems(searchParams, exportItems)
  local toonFoundItems = {}
  for _, item in pairs(exportItems) do
    if item and searchParams:Matches(item) then
      logger.Debug('Matched item [%s]', item.Name)
      table.insert(toonFoundItems, item)
    end

    if not item then
      logger.Warn('Encountered nil item for')
    end
  end

  return toonFoundItems
end


---@param searchParams SearchParams
---@return SearchItemResult[]
local function search_db(searchParams)
  logger.Debug('Starting search in export files for offline characters')
  local clients = broadcaster.ConnectedClients()
  local exportedItems = repository.GetItems(split(searchParams.Terms))
  local foundItems = {}
  for characterName, items in pairs(exportedItems) do
    if not contains_ignore_case(clients, characterName:lower()) then
      local toonFoundItems = matchItems(searchParams, items)
      for _, value in ipairs(toonFoundItems) do
        table.insert(foundItems, searchItemResult:convert(characterName, false, value))
      end
    end
  end

  logger.Debug('Completed search in export files for offline characters')
  return foundItems
end

return search_db
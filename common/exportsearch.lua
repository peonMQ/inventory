--- @type Mq
local mq = require 'mq'
local packageMan = require 'mq/PackageMan'
local logger = require 'utils/logging'
local plugin = require 'utils/plugins'
local debugUtils = require 'utils/debug'
--- @type SearchItem
local searchItem = require 'common/searchitem'

local lfs = packageMan.Require('luafilesystem', 'lfs')

local configDir = mq.configDir
local serverName = mq.TLO.MacroQuest.Server()
local exportDir =  string.format("%s/%s/Export/Inventory", configDir, serverName)

local next = next

---@class ExportItem
---@field Id number
---@field Name string
---@field Amount number
---@field InventorySlot number
---@field BagSlot number

---@param filePath string
---@return { bank: ExportItem[], inventory: ExportItem[] }
local function loadExportInventory(filePath)
  local status, exportItems = pcall(loadfile, filePath)
  logger.Debug('Loading export file \a-y[%s]\ax with status <%s>', filePath, status)
  if status and exportItems then
    return exportItems() --[[@as { bank: ExportItem[], inventory: ExportItem[] }]]
  end

  return {bank = {}, inventory =  {}}
end

---@param exportItems { bank: ExportItem[], inventory: ExportItem[] }
---@return SearchItem[]
local function mapExport(exportItems)
  local searchItems = {}
  for _,item in ipairs(exportItems.bank) do
    table.insert(searchItems, searchItem:new(item.Id, item.Name, item.Amount, item.InventorySlot, item.BagSlot))
  end
  for _,item in ipairs(exportItems.inventory) do
    table.insert(searchItems, searchItem:new(item.Id, item.Name, item.Amount, item.InventorySlot, item.BagSlot))
  end
  return searchItems
end

local function contains(file, list)
  for _,str in ipairs(list) do
    if file:match('(.*)'..str..'.lua$') then
      return true
    end
  end

  return false
end

---@param directory string
---@param skipClients string[]
---@return string[]
local function getExportFiles(directory, skipClients)
  logger.Debug('Looking in dir \a-y[%s]\ax', directory)
  local files = {}
  for file in lfs.dir(directory) do
    if lfs.attributes(directory.."/"..file,"mode") == "file" then
      if not contains(file, skipClients) then
        table.insert(files, directory.."/"..file)
      else
        logger.Debug('Character is online, skipping export file \a-y[%s]\ax', file)
      end
    elseif file ~= "." and file ~= ".." and file ~= "..." and lfs.attributes(file,"mode")== "directory" then
        local subDirFiles = getExportFiles(directory..file, skipClients)
        for _,subDirFile in ipairs(subDirFiles) do
          table.insert(files, subDirFile)
        end
    end
  end
  return files
end

---@return string[]
local function fetchOnlineClients()
  local clients={}
  if not mq.TLO.Plugin("mq2dannet").IsLoaded() or (not mq.TLO.Plugin("mq2eqbc").IsLoaded() and not mq.TLO.EQBC.Connected()) then
    logger.Debug("Not connected to Dannet or EQBC, unable to find online clients for search.")
    return clients
  end

  local connectedClients = {}

  if mq.TLO.Plugin("mq2dannet").IsLoaded() then
    local peers = mq.TLO.DanNet.Peers():gsub(serverName.."_", "")
    connectedClients = string.gmatch(peers, "([^|]+)") --[[@as table]]
  elseif mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
    connectedClients = string.gmatch(mq.TLO.EQBC.Names(), "([^%s]+)") --[[@as table]]
  end

  for client in string.gmatch(mq.TLO.EQBC.Names(), "([^%s]+)") do
    table.insert(clients, client)
  end
  return clients
end

---@param searchTerms string
---@param exportFile string
---@return string, SearchItem
local function searchFile(searchTerms, exportFile)
  local _, _, characterName = string.find(exportFile, "(%a+).lua")
  logger.Debug('Starting search for character \a-y[%s]\ax', characterName)
  local exportItems = mapExport(loadExportInventory(exportFile))
  local toonFoundItems = {}
  for _, item in pairs(exportItems) do
    if item:MatchesSearchTerms(searchTerms) then
      logger.Debug('Matched item [] for character []', item.Name, characterName)
      table.insert(toonFoundItems, item)
    end
  end

  return characterName, toonFoundItems
end

---@param searchTerms string
---@return table<string, { online: boolean, searchResult: SearchItem }>
local function search(searchTerms)
  logger.Debug('Starting search in export files for offline characters')
  local clients = fetchOnlineClients()
  local exportFiles = getExportFiles(exportDir, clients)
  local foundItems = {}
  for _,exportFile in ipairs(exportFiles) do
    local characterName, toonFoundItems = searchFile(searchTerms, exportFile)
    if next(toonFoundItems) then
      foundItems[characterName] = { online = false, searchResult = toonFoundItems }
    end
  end

  logger.Debug('Completed search in export files for offline characters')
  return foundItems
end

return search
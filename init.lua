--- @type ImGui
require 'ImGui'

--- @type Mq
local mq = require 'mq'

local packageMan = require('mq/PackageMan')
packageMan.Require('luafilesystem', 'lfs')
packageMan.Require('lua-cjson', 'cjson')
packageMan.Require('lyaml')
packageMan.Require('lsqlite3')

local logger = require('utils/logging')

--- @type SearchItem
local searchItem = require('common/searchitem')
local search = require('actions/search')
local export = require('actions/export')
local renderTable = require('ui/items_table')

---@type table<string, { online: boolean, searchResult: SearchItem }>
local searchResult = {}

---@param value string
---@return integer
local function toInteger(value)
  local asNumber = tonumber(value)
  if not asNumber then
    return 0
  end

  return asNumber --[[@as integer]]
end

local function itemSearchReportEvent(line, sender, id, name, amount, inventorySlot, bagSlot)
  sender = string.gsub(" "..sender, "%W%l", string.upper):sub(2)
  local searchedItem = searchItem:new(toInteger(id), name, toInteger(amount), toInteger(inventorySlot), toInteger(bagSlot))
  local toonResult = searchResult[sender] or { online = true, searchResult = {} }
  table.insert(toonResult.searchResult, searchedItem)
  if not searchResult[sender] then
    searchResult[sender] = toonResult
  end
end

local serverName = mq.TLO.MacroQuest.Server()
mq.event("itemsearchreportdannet", string.format('[ %s_#1# ] <#2#;#3#;#4#;#5#;#6#>', serverName), itemSearchReportEvent)
mq.event("itemsearchreportdannetself", string.format('[ -->(%s_#1#) ] <#2#;#3#;#4#;#5#;#6#>', serverName), itemSearchReportEvent)
mq.event("itemsearchreporteqbc", '[#1#(msg)] <#2#;#3#;#4#;#5#;#6#>', itemSearchReportEvent)

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false
local searchterms = ""
local searchOffline = false
local EnterKeyId = 13

-- ImGui main function for rendering the UI window
local itemsearch = function()
  openGUI, shouldDrawGUI = ImGui.Begin('Item Search', openGUI)
  ImGui.SetWindowSize(430, 277, ImGuiCond.FirstUseEver)
  if shouldDrawGUI then
    ImGui.PushItemWidth(288)
    searchterms, _ = ImGui.InputTextWithHint("##searchterms", "search terms", searchterms)
    local isSearchFocused = ImGui.IsItemFocused()
    ImGui.PopItemWidth()

    ImGui.SameLine(300)
    if ImGui.Button("Search", 50, 22) or (isSearchFocused and ImGui.IsKeyPressed(EnterKeyId)) then
      searchResult = search(searchterms, searchOffline)
    end

    ImGui.SameLine(355)
    if ImGui.Button("Clear", 42, 22) then
      searchResult = {}
      searchterms = ""
    end

    ImGui.SameLine(401)
    if ImGui.Button("Export", 50, 22) then
      export()
    end

    ImGui.SameLine(461)
    searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

    renderTable(searchResult)
  end

  ImGui.End()

  if not openGUI then
      terminate = true
  end
end

mq.imgui.init('itemsearch', itemsearch)

while not terminate do
  mq.doevents()
  mq.delay(500)
end
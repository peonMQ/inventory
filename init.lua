local imgui = require 'ImGui'
local mq = require 'mq'

local packageMan = require 'mq/PackageMan'
packageMan.Require('luafilesystem', 'lfs')
packageMan.Require('lua-cjson', 'cjson')
packageMan.Require('lyaml')
packageMan.Require('lsqlite3')

local logger = require 'utils/logging'

--- @type SearchItem
local searchItem = require 'common/searchitem'
local search = require 'actions/search'
local export = require 'actions/export'
local renderOptions = require 'ui/search-options'
local renderTable = require 'ui/items_table'

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

local function itemSearchReportEvent(line, sender, id, name, amount, inventorySlot, bagSlot, icon)
  sender = string.gsub(" "..sender, "%W%l", string.upper):sub(2)
  local searchedItem = searchItem:new(toInteger(id), name, toInteger(amount), toInteger(inventorySlot), toInteger(bagSlot), toInteger(icon))
  local toonResult = searchResult[sender] or { online = true, searchResult = {} }
  table.insert(toonResult.searchResult, searchedItem)
  if not searchResult[sender] then
    searchResult[sender] = toonResult
  end
end

local serverName = mq.TLO.MacroQuest.Server()
mq.event("itemsearchreportdannet", string.format('[ %s_#1# ] <#2#;#3#;#4#;#5#;#6#;#7#>', serverName), itemSearchReportEvent)
mq.event("itemsearchreportdannetself", string.format('[ -->(%s_#1#) ] <#2#;#3#;#4#;#5#;#6#;#7#>', serverName), itemSearchReportEvent)
mq.event("itemsearchreporteqbc", '[#1#(msg)] <#2#;#3#;#4#;#5#;#6#;#7#>', itemSearchReportEvent)

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false
local searchterms = ""
local searchOffline = false
local EnterKeyId = 13 -- https://github.com/gallexme/LuaPlugin-GTAV/blob/master/scripts/keys.lua

local leftPanelDefaultWidth = 200
local leftPanelWidth = 200



local function LeftPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("left", leftPanelWidth, y-1, true) then
    searchResult = renderOptions(searchResult)
  end
  imgui.EndChild()
end

local function RightPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("right", x, y-1, true) then
    renderTable(searchResult)
  end
  imgui.EndChild()
end

-- imgui main function for rendering the UI window
local itemsearch = function()
  openGUI, shouldDrawGUI = imgui.Begin('Item Search', openGUI)
  imgui.SetWindowSize(430, 277, ImGuiCond.FirstUseEver)
  if shouldDrawGUI then
    LeftPaneWindow()
    imgui.SameLine()
    RightPaneWindow()
  end

  imgui.End()

  if not openGUI then
      terminate = true
  end
end

mq.imgui.init('itemsearch', itemsearch)

while not terminate do
  mq.doevents()
  mq.delay(500)
end
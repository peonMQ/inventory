local imgui = require 'ImGui'
local mq = require 'mq'
local logger = require('knightlinc/Write')
local packageMan = require 'mq/PackageMan'
packageMan.Require('luafilesystem', 'lfs')

local state = require 'state'
local searchItem = require 'common/searchitem'
local renderOptions = require 'ui/search-options'
local renderTable = require 'ui/items_table'

logger.prefix = string.format("\at%s\ax", "[Inventory]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end
-- logger.loglevel = 'debug'

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
  logger.Info("ItemSearchEvent <%s>", line)
  sender = string.gsub(" "..sender, "%W%l", string.upper):sub(2)
  local searchedItem = searchItem:new(toInteger(id), name, toInteger(amount), toInteger(inventorySlot), toInteger(bagSlot), toInteger(icon))
  local toonResult = state.SearchResult[sender] or { online = true, searchResult = {} }
  table.insert(toonResult.searchResult, searchedItem)
  if not state.SearchResult[sender] then
    state.SearchResult[sender] = toonResult
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
local leftPanelWidth = 200


local function LeftPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("left", leftPanelWidth, y-1, true) then
    renderOptions()
  end
  imgui.EndChild()
end

local function RightPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("right", x, y-1, true) then
    renderTable()
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
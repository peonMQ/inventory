local imgui = require 'ImGui'
local mq = require 'mq'
local logger = require('knightlinc/Write')
local packageMan = require 'mq/PackageMan'
packageMan.Require('luafilesystem', 'lfs')
packageMan.Require('lsqlite3')

local renderOptions = require 'ui/search-options'
local renderTable = require 'ui/items_table'

logger.prefix = string.format("[%s][\at%s\ax]", os.date("%X"), "Inventory")
-- logger.postfix = function () return string.format(" %s", os.date("%X")) end
-- logger.loglevel = 'debug'

require('actor')

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false
local leftPanelWidth = 200


local function LeftPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("left", leftPanelWidth, y-1, ImGuiChildFlags.None) then
    renderOptions()
  end
  imgui.EndChild()
end

local function RightPaneWindow()
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("right", x, y-1, ImGuiChildFlags.None) then
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
    
    local left_pos  = imgui.GetItemRectMinVec()
    local left_max  = imgui.GetItemRectMaxVec()

    imgui.SameLine()
    RightPaneWindow()

    imgui.GetWindowDrawList():AddRectFilled(
      ImVec2(left_max.x + 4, left_pos.y),
      ImVec2(left_max.x + 5, left_max.y),
      imgui.GetColorU32(ImGuiCol.Separator, 1.0)
    )
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
--- @type Mq
local mq = require 'mq'

local packageMan = require('mq/PackageMan')
packageMan.Require('luafilesystem', 'lfs')
packageMan.Require('lua-cjson', 'cjson')
packageMan.Require('lyaml')
packageMan.Require('lsqlite3')

local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')
local broadCastInterfaceFactory = require('broadcast/broadcastinterface')

local broadcaster = broadCastInterfaceFactory()

---@type RunningDir
local runningDir = luaUtils.RunningDir:new()
runningDir:AppendToPackagePath()

--- @type SearchItem
local searchItem = require('common/searchitem')
local exportSearch = require('common/exportsearch')
--- @type ImGui
require 'ImGui'

-- Constants
local ICON_WIDTH = 20
local ICON_HEIGHT = 20
local EQ_ICON_OFFSET = 500

-- EQ Texture Animation references
local animItems = mq.FindTextureAnimation("A_DragItem")

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

---@param character string
---@param item SearchItem
local function pickupItem(character, item)
  if item.InventorySlot >= 2000 then
    logger.Warn("Cannot pick up item from a bankslot.")
    return
  end

  local command = ""
  local packslot = item.InventorySlot - 22
  if item.BagSlot > -1 then
    command = string.format('/nomodkey /itemnotify in pack%d %d leftmouseup', packslot, item.BagSlot+1)
  else
    command = string.format('/nomodkey /itemnotify pack%d leftmouseup', packslot)
  end

  if character == mq.TLO.Me.Name() then
    mq.cmd(command)
  elseif broadcaster then
    broadcaster.ExecuteCommand(command, {character})
  else
    logger.Warn("Dannet or EQBC is required to do remote item pickups")
  end
end

---@param character string
---@param item SearchItem
local function useitem(character, item)
  if item.InventorySlot >= 2000 then
    logger.Warn("Cannot use item from a bankslot.")
    return
  end

  local command = string.format('/useitem "%s"', item.Name)
  if character == mq.TLO.Me.Name() then
    mq.cmd(command)
  elseif broadcaster then
    broadcaster.ExecuteCommand(command, {character})
  else
    logger.Warn("Dannet or EQBC is required to do remote item pickups")
  end
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

local ColumnID_Character = 0
local ColumnID_Icon = 1
local ColumnID_Name = 2
local ColumnID_Amount = 3
local ColumnID_InventorySlot = 4
local ColumnID_BagSlot = 5

local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable, ImGuiTableFlags.Sortable, ImGuiTableFlags.ContextMenuInBody, ImGuiTableFlags.Reorderable)

local EnterKeyId = 13



---Draws the individual item icon in the bag.
---@param character string
---@param online boolean
---@param item SearchItem The item object
local function draw_item_icon(character, online, item)
  if not item.Icon then
    return
  end

  -- Reset the cursor to start position, then fetch and draw the item icon
  local cursor_x, cursor_y = ImGui.GetCursorPos()
  animItems:SetTextureCell(item.Icon - EQ_ICON_OFFSET)
  ImGui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

  if ImGui.IsItemClicked(ImGuiMouseButton.Left) and online then
    pickupItem(character, item)
  end

  if ImGui.IsItemClicked(ImGuiMouseButton.Right) and online then
    useitem(character, item)
  end
end

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
      searchResult = {}
      if searchOffline then
        searchResult = exportSearch(searchterms)
      end

      if broadcaster then
        local command = string.format('/lua run %s %s "%s"', runningDir:GetRelativeToMQLuaPath("search"),  mq.TLO.Me.Name(), searchterms)
        broadcaster.ExecuteAllCommand(command, true)
      else
        logger.Warn("Dannet or EQBC is required to do online searches")
      end
    end

    ImGui.SameLine(355)
    if ImGui.Button("Clear", 42, 22) then
      searchResult = {}
      searchterms = ""
    end

    ImGui.SameLine(401)
    if ImGui.Button("Export", 50, 22) then
      if broadcaster then
        local command = string.format('/lua run "%s"', runningDir:GetRelativeToMQLuaPath("export"))
        broadcaster.ExecuteAllCommand(command, true)
      else
        logger.Warn("Dannet or EQBC is required to do perform exports")
      end
    end

    ImGui.SameLine(461)
    searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

    if ImGui.BeginTable('search_result_table', 6, tableFlags) then
      ImGui.TableSetupColumn('Character', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Character)
      ImGui.TableSetupColumn('', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Icon)
      ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
      ImGui.TableSetupColumn('Amount', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Amount)
      ImGui.TableSetupColumn('Inventory Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_InventorySlot)
      ImGui.TableSetupColumn('Bag Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_BagSlot)
    end

    ImGui.TableHeadersRow()

    for character, result in pairs(searchResult) do
      ImGui.TableNextRow()
      for k, item in ipairs (result.searchResult) do
        ImGui.TableNextColumn()
        if result.online then
          ImGui.PushStyleColor(ImGuiCol.Text, 0.56, 0.8, 0.32, 1)
          ImGui.Text(character)
          ImGui.PopStyleColor(1)
        else
          ImGui.Text(character)
        end
        ImGui.TableNextColumn()
          draw_item_icon(character, result.online, item)
        ImGui.TableNextColumn()
        ImGui.Text(item.Name)
        if ImGui.IsItemClicked(ImGuiMouseButton.Left) and item.ItemLink ~= "" then
          mq.cmdf("/say %s", item.ItemLink)
        end
        ImGui.TableNextColumn()
        ImGui.Text(item.Amount)
        ImGui.TableNextColumn()
        ImGui.Text(item:HumanInventorySlot())
        ImGui.TableNextColumn()
        ImGui.Text(item:HumanBagSlot())
      end
    end

    ImGui.EndTable()
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

--- 11010
--- 2593
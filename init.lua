--- @type Mq
local mq = require 'mq'

local packageMan = require('mq/PackageMan')
packageMan.Require('luafilesystem', 'lfs')
packageMan.Require('lua-cjson', 'cjson')
packageMan.Require('lyaml')
packageMan.Require('lsqlite3')

local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')

---@type RunningDir
local runningDir = luaUtils.RunningDir:new()
runningDir:AppendToPackagePath()

--- @type SearchItem
local searchItem = require('./common/searchitem')
local exportSearch = require('./common/exportsearch')
--- @type ImGui
require 'ImGui'


---@type table<string, SearchItem>
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
  local command = ""
  local packslot = item.InventorySlot - 22
  if item.BagSlot > 0 then
    command = string.format('/itemnotify in pack%d %d leftmouseup', packslot, item.BagSlot+1)
  else
    command = string.format('/itemnotify pack%d leftmouseup', packslot)
  end

  if character == mq.TLO.Me.Name() then
    mq.cmd(command)
  else
    if mq.TLO.Plugin("mq2dannet").IsLoaded() then
      mq.cmdf('/dex %s %s"', character, command)
    elseif mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
      mq.cmdf('/bct %s /%s"', character, command)
    else
      logger.Warn("Dannet or EQBC is required to do remote item pickups")
    end
  end
end

local function itemSearchReportEvent(line, sender, id, name, amount, inventorySlot, bagSlot)
  sender = string.gsub(" "..sender, "%W%l", string.upper):sub(2)
  local searchedItem = searchItem:new(toInteger(id), name, toInteger(amount), toInteger(inventorySlot), toInteger(bagSlot))
  local toonResult = searchResult[sender] or {}
  table.insert(toonResult, searchedItem)
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
local ColumnID_Name = 1
local ColumnID_Amount = 2
local ColumnID_InventorySlot = 3
local ColumnID_BagSlot = 4
local ColumnID_Actions = 5

local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable, ImGuiTableFlags.Sortable, ImGuiTableFlags.ContextMenuInBody, ImGuiTableFlags.Reorderable)

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
      searchResult = {}
      if searchOffline then
        searchResult = exportSearch(searchterms)
      end
      if mq.TLO.Plugin("mq2dannet").IsLoaded() then
        mq.cmdf('/dgae /lua run %s %s "%s"', runningDir:GetRelativeToMQLuaPath("client/search"),  mq.TLO.Me.Name(), searchterms)
      elseif mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
        mq.cmdf('/bcaa //lua run %s %s "%s"', runningDir:GetRelativeToMQLuaPath("client/search"),  mq.TLO.Me.Name(), searchterms)
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
      if mq.TLO.Plugin("mq2dannet").IsLoaded() then
        mq.cmdf('/dgae /lua run "%s"', runningDir:GetRelativeToMQLuaPath("client/export"))
      elseif mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
        mq.cmdf('/bcaa //lua run "%s"', runningDir:GetRelativeToMQLuaPath("client/export"))
      else
        logger.Warn("Dannet or EQBC is required to do perform exports")
      end
    end

    ImGui.SameLine(461)
    searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

    if ImGui.BeginTable('search_result_table', 6, tableFlags) then
      ImGui.TableSetupColumn('Character', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Character)
      ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
      ImGui.TableSetupColumn('Amount', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Amount)
      ImGui.TableSetupColumn('Inventory Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_InventorySlot)
      ImGui.TableSetupColumn('Bag Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_BagSlot)
      ImGui.TableSetupColumn('', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Actions)
    end

    ImGui.TableHeadersRow()

    for character, result in pairs(searchResult) do
      ImGui.TableNextRow()
      for k, item in ipairs (result) do
        ImGui.TableNextColumn()
        ImGui.Text(character)
        ImGui.TableNextColumn()
        local clicked = ImGui.SmallButton("Link##"..item.Id)
        if clicked and item.ItemLink ~= "" then
          mq.cmdf("/say %s", item.ItemLink)
        end
        ImGui.SameLine(50)
        ImGui.Text(item.Name)
        ImGui.TableNextColumn()
        ImGui.Text(item.Amount)
        ImGui.TableNextColumn()
        ImGui.Text(item:HumanInventorySlot())
        ImGui.TableNextColumn()
        ImGui.Text(item:HumanBagSlot())
        ImGui.TableNextColumn()
        if item:CanPickUp() then
          local clickedPickupItem = ImGui.SmallButton("Pickup##"..item.Id)
          if clickedPickupItem then
            pickupItem(character, item)
          end
        end
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
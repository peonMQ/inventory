--- @type Mq
local mq = require 'mq'
local logger = require('utils/logging')
local luaUtils = require('utils/lua')

---@type RunningDir
local runningDir = luaUtils.RunningDir:new()
runningDir:AppendToPackagePath()

--- @type SearchItem
local searchItem = require('common/searchitem')
local exportSearch = require('common/exportsearch')
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

local function itemSearchReportEvent(line, sender, id, name, amount, inventorySlot, bagSlot)
  local searchedItem = searchItem:new(toInteger(id), name, toInteger(amount), toInteger(inventorySlot), toInteger(bagSlot))
  local toonResult = searchResult[sender] or {}
  table.insert(toonResult, searchedItem)
  if not searchResult[sender] then
    searchResult[sender] = toonResult
  end 
end

mq.event("itemsearchreport", '[#1#(msg)] <#2#:#3#:#4#:#5#:#6#>', itemSearchReportEvent)

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

-- ImGui main function for rendering the UI window
local itemsearch = function()
  openGUI, shouldDrawGUI = ImGui.Begin('Item Search', openGUI)
  ImGui.SetWindowSize(430, 277, ImGuiCond.FirstUseEver)
  if shouldDrawGUI then
    ImGui.PushItemWidth(288)
    searchterms, _ = ImGui.InputTextWithHint("##searchterms", "search terms", searchterms)
    ImGui.PopItemWidth()

    ImGui.SameLine(300)
    if ImGui.Button("Search", 50, 22) then 
      searchResult = {}
      if searchOffline then
        searchResult = exportSearch(searchterms)
      end

      if mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
        mq.cmdf('/bcaa //lua run %s %s "%s"', runningDir:GetRelativeToMQLuaPath("client/search"),  mq.TLO.Me.Name(), searchterms)
      else
        logger.Warn("EQBC is required to do online searches")
      end
    end

    ImGui.SameLine(355)
    if ImGui.Button("Clear", 42, 22) then 
      searchResult = {}
      searchterms = ""
    end

    ImGui.SameLine(401)
    if ImGui.Button("Export", 50, 22) then 
      if mq.TLO.Plugin("mq2eqbc").IsLoaded() and mq.TLO.EQBC.Connected() then
        mq.cmd('/bcaa //lua run %s', runningDir:GetRelativeToMQLuaPath("client/export"))
      else
        logger.Warn("EQBC is required to do perform exports")
      end
    end

    ImGui.SameLine(461)
    searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

    if ImGui.BeginTable('search_result_table', 5) then
      ImGui.TableSetupColumn('Character', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Character)
      ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
      ImGui.TableSetupColumn('Amount', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Amount)
      ImGui.TableSetupColumn('Inventory Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_InventorySlot)
      ImGui.TableSetupColumn('Bag Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_BagSlot)
    end

    ImGui.TableHeadersRow()

    for character, result in pairs(searchResult) do
      ImGui.TableNextRow()
      for k, item in ipairs (result) do
        ImGui.TableNextColumn()
        ImGui.Text(character)
        ImGui.TableNextColumn()
        ImGui.Text(item.Name)
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
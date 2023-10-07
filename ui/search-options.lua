--- @type ImGui
require 'ImGui'

--- @type Mq
local mq = require 'mq'

local logger = require 'utils/logging'
local renderCombobox = require 'ui/combobox'
local autoinventory = require('actions/autoinventory')
local export = require('actions/export')
local search = require('actions/search')
local searchParams = require('common/searchparams')
local filters = require('ui/filters')


local minSearchTextLength = 3
local searchterms = ""
local searchOffline = false
local EnterKeyId = 13
local slotFilter = filters.SlotFilter[1]
local typeFilter = filters.TypeFilter[1]
local locationFilter = filters.LocationFilter[1]
local classFilter = filters.ClassFilter[1]

local function drawComboBoxFilter(label, filter, filterOptions)
  return renderCombobox(label, filter, filterOptions, function(option) return option.value end)
end

---@param searchResult table<string, { online: boolean, searchResult: SearchItem }>
local function renderSearchOptions(searchResult)
  local y = ImGui.GetCursorPosY()
  ImGui.SetCursorPosY(y+5)

  if ImGui.Button("Clear") then
    searchResult = {}
    searchterms = ""
  end

  ImGui.SameLine()
  if ImGui.Button("Export") then
    export()
  end

  ImGui.SameLine()
  if ImGui.Button("AutoInv.") then
    autoinventory()
  end

  y = ImGui.GetCursorPosY()
  ImGui.SetCursorPosY(y+5)
  ImGui.Separator()

  ImGui.Text('Search')
  ImGui.PushItemWidth(200)
  searchterms, _ = ImGui.InputText("##Search", searchterms)
  local isSearchFocused = ImGui.IsItemFocused()
  ImGui.PopItemWidth()

  slotFilter = drawComboBoxFilter("Slot", slotFilter, filters.SlotFilter)
  typeFilter = drawComboBoxFilter("Type", typeFilter, filters.TypeFilter)
  locationFilter = drawComboBoxFilter("Location", locationFilter, filters.LocationFilter)
  classFilter = drawComboBoxFilter("Class", classFilter, filters.ClassFilter)

  y = ImGui.GetCursorPosY()
  ImGui.SetCursorPosY(y+5)
  searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

  if ImGui.Button("Search") or (isSearchFocused and ImGui.IsKeyPressed(EnterKeyId)) then
    if #searchterms < minSearchTextLength then
      logger.Error("Searchtext is to short <%d>, must me minimum %d characters.", #searchterms, minSearchTextLength)
    else
      searchResult = search(searchParams:new(searchterms, slotFilter.key, typeFilter.key, classFilter.key, locationFilter.key), searchOffline)
    end
  end

  return searchResult
end

return renderSearchOptions
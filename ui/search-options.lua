local mq = require 'mq'
local imgui = require 'ImGui'

local logger = require 'knightlinc/Write'
local renderCombobox = require 'ui/combobox'
local autoinventory = require('actions/autoinventory')
local export = require('actions/export')
local search = require('actions/search')
local searchParams = require('common/searchparams')
local filters = require('ui/filters')


local minSearchTextLength = 3
local searchterms = ""
local searchOffline = false
local EnterKeyId = 13 -- https://github.com/gallexme/LuaPlugin-GTAV/blob/master/scripts/keys.lua
local slotFilter = filters.SlotFilter[1]
local typeFilter = filters.TypeFilter[1]
local locationFilter = filters.LocationFilter[1]
local classFilter = filters.ClassFilter[1]

local function drawComboBoxFilter(label, filter, filterOptions)
  return renderCombobox(label, filter, filterOptions, function(option) return option.value end)
end

---@param searchResult table<string, { online: boolean, searchResult: SearchItem }>
local function renderSearchOptions(searchResult)
  local y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)

  if imgui.Button("Clear") then
    searchResult = {}
    searchterms = ""
  end

  imgui.SameLine()
  if imgui.Button("Export") then
    export()
  end

  imgui.SameLine()
  if imgui.Button("AutoInv.") then
    autoinventory()
  end

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)
  imgui.Separator()

  imgui.Text('Search')
  imgui.PushItemWidth(200)
  searchterms, _ = imgui.InputText("##Search", searchterms)
  local isSearchFocused = imgui.IsItemFocused()
  imgui.PopItemWidth()

  slotFilter = drawComboBoxFilter("Slot", slotFilter, filters.SlotFilter)
  typeFilter = drawComboBoxFilter("Type", typeFilter, filters.TypeFilter)
  locationFilter = drawComboBoxFilter("Location", locationFilter, filters.LocationFilter)
  classFilter = drawComboBoxFilter("Class", classFilter, filters.ClassFilter)

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)
  searchOffline, _ = imgui.Checkbox('Incl. Offline', searchOffline)

  if imgui.Button("Search") or (isSearchFocused and imgui.IsKeyPressed(EnterKeyId)) then
    if #searchterms < minSearchTextLength then
      logger.Error("Searchtext is to short <%d>, must me minimum %d characters.", #searchterms, minSearchTextLength)
    else
      searchResult = search(searchParams:new(searchterms, slotFilter.key, typeFilter.key, classFilter.key, locationFilter.key), searchOffline)
    end
  end

  return searchResult
end

return renderSearchOptions
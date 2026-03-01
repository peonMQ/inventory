local mq = require 'mq'
local imgui = require 'ImGui'

local logger = require 'knightlinc/Write'
local state = require 'state'
local renderCombobox = require ('ui/controls/combobox')
local switchControl = require("ui/controls/switch")
local autoinventory = require('actions/autoinventory')
local clearState = require('actions/clearState')
local export = require('actions/export')
local search = require('actions/search')
local searchParams = require('common/searchparams')
local filters = require('ui/filters')


local minSearchTextLength = 3
local includeOffline = false
local inclAllOnline = true
local EnterKeyId = 13 -- https://github.com/gallexme/LuaPlugin-GTAV/blob/master/scripts/keys.lua
local slotFilter = filters.SlotFilter[1]
local typeFilter = filters.TypeFilter[1]
local locationFilter = filters.LocationFilter[1]
local classFilter = filters.ClassFilter[1]

local includeOfflineSwitch = switchControl.new({ id = "includeOfflineSwitch" })
local inclAllOnlineSwitch = switchControl.new({ id = "inclAllOnlineSwitch" })

local function drawComboBoxFilter(label, filter, filterOptions)
  return renderCombobox(label, filter, filterOptions, function(option) return option.value end)
end

local function renderSearchOptions()
  local y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)

  if imgui.Button("Clear") then
    clearState()
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
  state.Searchterms, _ = imgui.InputText("##Search", state.Searchterms)
  local isSearchFocused = imgui.IsItemFocused()
  imgui.PopItemWidth()

  imgui.PushItemWidth(200)
  slotFilter = drawComboBoxFilter("Slot", slotFilter, filters.SlotFilter)
  imgui.PopItemWidth()
  imgui.PushItemWidth(200)
  typeFilter = drawComboBoxFilter("Type", typeFilter, filters.TypeFilter)
  imgui.PopItemWidth()
  imgui.PushItemWidth(200)
  locationFilter = drawComboBoxFilter("Location", locationFilter, filters.LocationFilter)
  imgui.PopItemWidth()
  imgui.PushItemWidth(200)
  classFilter = drawComboBoxFilter("Class", classFilter, filters.ClassFilter)
  imgui.PopItemWidth()

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)
  includeOffline = includeOfflineSwitch:draw('Incl. Offline', includeOffline)

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)
  inclAllOnline = inclAllOnlineSwitch:draw('Incl. All Online', inclAllOnline)

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)

  if imgui.Button("Search") or (isSearchFocused and imgui.IsKeyPressed(ImGuiKey.Enter)) then
    if state.Searchterms ~= '*' and #state.Searchterms < minSearchTextLength then
      logger.Error("Searchtext is to short <%d>, must me minimum %d characters.", #state.Searchterms, minSearchTextLength)
    else
      search(searchParams:new(state.Searchterms, slotFilter.key, typeFilter.key, classFilter.key, locationFilter.key), includeOffline, inclAllOnline)
    end
  end

  y = imgui.GetCursorPosY()
  imgui.SetCursorPosY(y+5)
  imgui.Separator()
  if imgui.Button("Request item") then
    clearState()
  end
end

return renderSearchOptions
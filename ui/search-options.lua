--- @type ImGui
require 'ImGui'

--- @type Mq
local mq = require 'mq'

local autoinventory = require('actions/autoinventory')
local export = require('actions/export')
local search = require('actions/search')

local searchterms = ""
local searchOffline = false
local EnterKeyId = 13

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
  searchterms, _ = ImGui.InputText("Search", searchterms)
  local isSearchFocused = ImGui.IsItemFocused()
  ImGui.PopItemWidth()

  y = ImGui.GetCursorPosY()
  ImGui.SetCursorPosY(y+5)
  searchOffline, _ = ImGui.Checkbox('Incl. Offline', searchOffline)

  if ImGui.Button("Search") or (isSearchFocused and ImGui.IsKeyPressed(EnterKeyId)) then
    searchResult = search(searchterms, searchOffline)
  end

  return searchResult
end

return renderSearchOptions
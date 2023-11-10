local imgui = require 'ImGui'
local mq = require 'mq'
local state = require 'state'
local table = require 'ui/controls/table'
local useitem = require('actions/useitem')
local pickupItem = require('actions/pickup_item')
local linkItem = require('actions/linkItem')

-- EQ Texture Animation references
local animItems = mq.FindTextureAnimation("A_DragItem")

-- Constants
local ICON_WIDTH = 20
local ICON_HEIGHT = 20
local EQ_ICON_OFFSET = 500

local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable, ImGuiTableFlags.Sortable)

---Draws the individual item icon in the bag.
---@param character string
---@param online boolean
---@param item SearchItem The item object
local function draw_item_icon(character, online, item)
  if not item.Icon then
    return
  end

  animItems:SetTextureCell(item.Icon - EQ_ICON_OFFSET)
  imgui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

  if imgui.IsItemClicked(ImGuiMouseButton.Left) and online then
    pickupItem(character, item)
  end

  if imgui.IsItemClicked(ImGuiMouseButton.Right) and online then
    useitem(character, item)
  end
end

---@type TableColumnDefinition[]
local columnsDefinition = {
  {label = 'Character', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = '', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Name', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Amount', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Inventory Slot', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Bag Slot', flags = ImGuiTableColumnFlags.WidthFixed}
}

---@param searchResult table<string, { online: boolean, searchResult: SearchItem[] }>
local function renderRows(searchResult)
  for character, result in pairs(searchResult) do
    imgui.TableNextRow()
    for k, item in ipairs (result.searchResult) do
      imgui.TableNextColumn()
      if result.online then
        imgui.PushStyleColor(ImGuiCol.Text, 0.56, 0.8, 0.32, 1)
        imgui.Text(character)
        imgui.PopStyleColor(1)
      else
        imgui.Text(character)
      end
      imgui.TableNextColumn()
        draw_item_icon(character, result.online, item)
      imgui.TableNextColumn()
      imgui.Text(item.Name)
      if imgui.IsItemClicked(ImGuiMouseButton.Left) then
        linkItem(character, item)
      end
      imgui.TableNextColumn()
      imgui.Text(item.Amount)
      imgui.TableNextColumn()
      imgui.Text(item:HumanInventorySlot())
      imgui.TableNextColumn()
      imgui.Text(item:HumanBagSlot())
    end
  end
end

local function renderTable()
  local renderContent = function() return renderRows(state.SearchResult) end
  table.RenderTable('search_result_table', columnsDefinition, tableFlags, renderContent)
end

return renderTable
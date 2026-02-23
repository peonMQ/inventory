local imgui = require 'ImGui'
local mq = require 'mq'
local state = require 'state'
local uiTable = require 'ui/controls/table'
local useitem = require('actions/useitem')
local pickupItem = require('actions/pickup_item')

-- EQ Texture Animation references
local animItems = mq.FindTextureAnimation("A_DragItem")

-- Constants
local ICON_WIDTH = 20
local ICON_HEIGHT = 20
local EQ_ICON_OFFSET = 500

local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable)

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
  , {label = 'Quantity', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Inventory Slot', flags = ImGuiTableColumnFlags.WidthFixed}
  , {label = 'Bag Slot', flags = ImGuiTableColumnFlags.WidthFixed}
}

---@param searchResult table<string, { online: boolean, searchResult: SearchItem[] }>
local function renderRows(searchResult)

  -- build sorted key list
  local sortedKeys = {}
  for k in pairs(searchResult) do
    sortedKeys[#sortedKeys + 1] = k
  end
  
  if #sortedKeys > 1 then
    table.sort(sortedKeys)
  end

  for _, character in ipairs(sortedKeys) do
    local result = searchResult[character]
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
      if #item.ItemLink > 1 then
        imgui.TextColored(ImVec4(0.0, 1.0, 1.0, 1.0), item.Name)
        if imgui.IsItemClicked(ImGuiMouseButton.Left) then
          mq.cmdf('/executelink %s', item.ItemLink)
        end
      else
        imgui.Text(item.Name)
      end
      imgui.TableNextColumn()
      imgui.Text(string.format("%d", item.Amount))
      imgui.TableNextColumn()
      imgui.Text(item:HumanInventorySlot())
      imgui.TableNextColumn()
      imgui.Text(item:HumanBagSlot())
    end
  end
end

local function renderTable()
  local renderContent = function() return renderRows(state.SearchResult) end
  uiTable.RenderTable('search_result_table', columnsDefinition, tableFlags, renderContent)
end

return renderTable
--- @type ImGui
require 'ImGui'

--- @type Mq
local mq = require 'mq'

local useitem = require('actions/useitem')
local pickupItem = require('actions/pickup_item')

-- EQ Texture Animation references
local animItems = mq.FindTextureAnimation("A_DragItem")

-- Constants
local ICON_WIDTH = 20
local ICON_HEIGHT = 20
local EQ_ICON_OFFSET = 500

local ColumnID_Character = 0
local ColumnID_Icon = 1
local ColumnID_Name = 2
local ColumnID_Amount = 3
local ColumnID_InventorySlot = 4
local ColumnID_BagSlot = 5

local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable, ImGuiTableFlags.Sortable)


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

local function renderTable(searchResult)
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

return renderTable
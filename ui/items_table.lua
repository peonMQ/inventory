local imgui = require 'ImGui'
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
  local cursor_x, cursor_y = imgui.GetCursorPos()
  animItems:SetTextureCell(item.Icon - EQ_ICON_OFFSET)
  imgui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

  if imgui.IsItemClicked(ImGuiMouseButton.Left) and online then
    pickupItem(character, item)
  end

  if imgui.IsItemClicked(ImGuiMouseButton.Right) and online then
    useitem(character, item)
  end
end

local function renderTable(searchResult)
  if imgui.BeginTable('search_result_table', 6, tableFlags) then
    imgui.TableSetupColumn('Character', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Character)
    imgui.TableSetupColumn('', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Icon)
    imgui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
    imgui.TableSetupColumn('Amount', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Amount)
    imgui.TableSetupColumn('Inventory Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_InventorySlot)
    imgui.TableSetupColumn('Bag Slot', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_BagSlot)
  end

  imgui.TableHeadersRow()

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
      if imgui.IsItemClicked(ImGuiMouseButton.Left) and item.ItemLink ~= "" then
        mq.cmdf("/say %s", item.ItemLink)
      end
      imgui.TableNextColumn()
      imgui.Text(item.Amount)
      imgui.TableNextColumn()
      imgui.Text(item:HumanInventorySlot())
      imgui.TableNextColumn()
      imgui.Text(item:HumanBagSlot())
    end
  end

  imgui.EndTable()
end

return renderTable
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

local tableFlags = bit32.bor(
  ImGuiTableFlags.PadOuterX,
  ImGuiTableFlags.Hideable,
  ImGuiTableFlags.Sortable,
  ImGuiTableFlags.SortMulti
)

local previousSortCount = 0

---Draws the individual item icon in the bag.
---@param item SearchItemResult The item object
local function draw_item_icon(item)
  if not item.Icon then
    return
  end

  animItems:SetTextureCell(item.Icon - EQ_ICON_OFFSET)
  imgui.DrawTextureAnimation(animItems, ICON_WIDTH, ICON_HEIGHT)

  if imgui.IsItemClicked(ImGuiMouseButton.Left) and item.Online then
    pickupItem(item.CharacterName, item)
  end

  if imgui.IsItemClicked(ImGuiMouseButton.Right) and item.Online then
    useitem(item.CharacterName, item)
  end
end

---@type TableColumnDefinition[]
local columnsDefinition = {
  {label = '', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 0}
  , {label = 'Character', flags = bit32.bor(ImGuiTableColumnFlags.WidthFixed, ImGuiTableColumnFlags.DefaultSort), user_id = 1}
  , {label = '', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 2}
  , {label = 'Name', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 3}
  , {label = 'Quantity', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 4}
  , {label = 'Inventory Slot', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 5}
  , {label = 'Bag Slot', flags = ImGuiTableColumnFlags.WidthFixed, user_id = 6}
}

local function sortResults(results)
  local sortSpecs = imgui.TableGetSortSpecs()
  if not sortSpecs or sortSpecs.SpecsCount == 0 then
    return
  end

  if not sortSpecs.SpecsDirty and previousSortCount == #state.SearchResult then
    return
  end

  table.sort(results, function(a, b)
    for i = 1, sortSpecs.SpecsCount do
      local spec = sortSpecs:Specs(i)
      local column = spec.ColumnUserID
      local direction = spec.SortDirection

      local delta = 0

      if column == 1 then -- Character
        delta = a.CharacterName < b.CharacterName and -1 or (a.CharacterName > b.CharacterName and 1 or 0)

      elseif column == 3 then -- Name
        delta = a.Name < b.Name and -1 or (a.Name > b.Name and 1 or 0)

      elseif column == 4 then -- Quantity
        delta = a.Amount - b.Amount

      elseif column == 5 then -- Inventory Slot
        delta = a:HumanInventorySlot() < b:HumanInventorySlot() and -1
              or (a:HumanInventorySlot() > b:HumanInventorySlot() and 1 or 0)

      elseif column == 6 then -- Bag Slot
        delta = a:HumanBagSlot() < b:HumanBagSlot() and -1
              or (a:HumanBagSlot() > b:HumanBagSlot() and 1 or 0)
      end

      if delta ~= 0 then
        if direction == ImGuiSortDirection.Ascending then
          return delta < 0
        else
          return delta > 0
        end
      end
    end
    return false
  end)

  sortSpecs.SpecsDirty = false
  previousSortCount = #state.SearchResult
end

---@param searchResult SearchItemResult[]
local function renderRows(searchResult)
for _, result in ipairs(searchResult) do
    imgui.TableNextRow()
    
    imgui.TableNextColumn()
    result.Selected, _  = imgui.Checkbox("##row_select_" .. result.Id, result.Selected)
    
    imgui.TableNextColumn()
    if result.Online then
      imgui.PushStyleColor(ImGuiCol.Text, 0.56, 0.8, 0.32, 1)
      imgui.Text(result.CharacterName)
      imgui.PopStyleColor(1)
    else
      imgui.Text(result.CharacterName)
    end
    imgui.TableNextColumn()
      draw_item_icon(result)
    imgui.TableNextColumn()
    if #result.ItemLink > 1 then
      imgui.TextColored(ImVec4(0.0, 1.0, 1.0, 1.0), result.Name)
      if imgui.IsItemClicked(ImGuiMouseButton.Left) then
        mq.cmdf('/executelink %s', result.ItemLink)
      end
    else
      imgui.Text(result.Name)
    end
    imgui.TableNextColumn()
    imgui.Text(string.format("%d", result.Amount))
    imgui.TableNextColumn()
    imgui.Text(result:HumanInventorySlot())
    imgui.TableNextColumn()
    imgui.Text(result:HumanBagSlot())
  end
end

local function renderTable()
  local renderContent = function()
    sortResults(state.SearchResult)
    renderRows(state.SearchResult)
  end

  uiTable.RenderTable('search_result_table', columnsDefinition, tableFlags, renderContent)
end

return renderTable
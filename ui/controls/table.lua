local imgui = require 'ImGui'

---@class TableColumnDefinition
---@field label string
---@field flags? ImGuiTableColumnFlags
---@field init_width_or_weight? number
---@field user_id? integer

---@param name string
---@param columns TableColumnDefinition[]
---@param tableFlags? ImGuiTableFlags
---@param renderRows function
local function renderTable (name, columns, tableFlags, renderRows)
  local numberOfColumns = #columns
  if imgui.BeginTable(name, numberOfColumns, tableFlags) then
    for index, columnDefintion in ipairs(columns) do
      imgui.TableSetupColumn(columnDefintion.label, columnDefintion.flags or ImGuiTableColumnFlags.None, columnDefintion.init_width_or_weight or -1, columnDefintion.user_id or index-1)
    end

    imgui.TableHeadersRow()
    renderRows()
    imgui.EndTable()
  end
end

return {
  RenderTable = renderTable
}
local imgui = require('ImGui')

local ToggleSlider = {}

local function easeOutCubic(x)
    return 1 - (1 - x) ^ 3
end

--- Creates a new toggle slider instance
-- @param opts table? { id = string|number, animationSpeed = number }
function ToggleSlider.new(opts)
    opts = opts or {}

    local self = {
        id              = opts.id,
        animationSpeed  = opts.animationSpeed or 8.5,
        animationPosition = 0.0,       -- Previously: t
        animationTarget   = 0.0,       -- Previously: target
        previousValue     = false,     -- Previously: lastValue
    }

    --- Draw the slider
    function self:draw(label, currentValue)
        local style               = imgui.GetStyle()
        local frameHeight         = imgui.GetFrameHeight()
        local sliderWidth         = frameHeight * 1.55
        local radius              = frameHeight * 0.5
        local topLeftX, topLeftY  = imgui.GetCursorScreenPos()
        local topLeft             = ImVec2(topLeftX, topLeftY)
        local size                = ImVec2(sliderWidth, frameHeight)

        -- Interaction
        local pressed = imgui.InvisibleButton(label, size)
        local updatedValue = currentValue
        if pressed then
            updatedValue = not currentValue
        end

        -- Initialize animation on first run
        if self.animationPosition == 0.0 and self.animationTarget == 0.0 and self.previousValue == false then
            if updatedValue then
                self.animationPosition = 1.0
                self.animationTarget   = 1.0
            end
            self.previousValue = updatedValue
        end

        -- Update target when value changes
        if self.previousValue ~= updatedValue then
            self.animationTarget = updatedValue and 1.0 or 0.0
            self.previousValue = updatedValue
        end

        -- Move animation position toward target
        do
            local dt = imgui.GetIO().DeltaTime
            local direction = (self.animationTarget > self.animationPosition) and 1 or -1
            local step = self.animationSpeed * dt * direction
            local nextPosition = self.animationPosition + step

            -- Clamp and finalize step
            if (direction > 0 and nextPosition > self.animationTarget) or
               (direction < 0 and nextPosition < self.animationTarget) then
                self.animationPosition = self.animationTarget
            else
                self.animationPosition = nextPosition
            end
        end

        local eased = easeOutCubic(self.animationPosition)

        -- Colors
        local bgColor = imgui.GetColorU32(ImGuiCol.FrameBg, 1.0)
        local knobColor =
              imgui.IsItemClicked()  and imgui.GetColorU32(ImGuiCol.ButtonActive, 1.0)
           or imgui.IsItemHovered() and imgui.GetColorU32(ImGuiCol.ButtonHovered, 1.0)
           or                           imgui.GetColorU32(ImGuiCol.Button, 1.0)

        -- Draw
        local drawList   = imgui.GetWindowDrawList()
        local bottomRight = ImVec2(topLeft.x + sliderWidth, topLeft.y + frameHeight)
        drawList:AddRectFilled(topLeft, bottomRight, bgColor, radius)

        local travel     = sliderWidth - radius * 2.0
        local knobX      = topLeft.x + radius + eased * travel
        local knobCenter = ImVec2(knobX, topLeft.y + radius)
        drawList:AddCircleFilled(knobCenter, radius - 1.5, knobColor)

        -- Label
        if label and label ~= "" then
            local labelPos = ImVec2(
                topLeft.x + sliderWidth + style.ItemInnerSpacing.x,
                topLeft.y + style.FramePadding.y
            )
            drawList:AddText(labelPos, imgui.GetColorU32(ImGuiCol.Text, 1.0), label)
        end

        return updatedValue, pressed 
    end

    return self
end

return ToggleSlider
local imgui = require('ImGui')

local ToggleSlider = {}

-- Easing
local function easeOutCubic(x)
    return 1 - (1 - x) ^ 3
end

-- Scalar lerp
local function lerp(a, b, t) return a + (b - a) * t end

-- Vec4 lerp (ImVec4 = {x=r, y=g, z=b, w=a})
local function lerpVec4(c1, c2, t)
    return ImVec4(
        lerp(c1.x, c2.x, t),
        lerp(c1.y, c2.y, t),
        lerp(c1.z, c2.z, t),
        lerp(c1.w, c2.w, t)
    )
end

-- Helpers to get/convert colors as float4 (no bitwise needed)
local function getStyleColorVec4(idx)
    return imgui.GetStyleColorVec4(idx)
end

local function u32FromVec4(v4)
    return imgui.ColorConvertFloat4ToU32(v4)
end

-- Utility to make a color lighter/darker in RGB (simple gamma-ish scaling)
local function scaleRgb(v4, factor)
    return ImVec4(
        math.max(0.0, math.min(1.0, v4.x * factor)),
        math.max(0.0, math.min(1.0, v4.y * factor)),
        math.max(0.0, math.min(1.0, v4.z * factor)),
        v4.w
    )
end

--- Creates a new toggle slider instance
-- @param opts table? {
--   id: string|number,
--   animationSpeed: number,
--   onTrackColor: ImU32|ImVec4,   -- ON track target (bright)
--   offTrackColor: ImU32|ImVec4,  -- OFF track base (dark)
--   borderOnColor: ImU32|ImVec4,
--   borderOffColor: ImU32|ImVec4,
--   knobOnColor: ImU32|ImVec4,    -- ON knob (light)
--   knobOffColor: ImU32|ImVec4,   -- OFF knob (neutral)
--   glowStrength: number          -- 0..1, intensity of glow when ON
-- }
function ToggleSlider.new(opts)
    opts = opts or {}

    local self = {
        id                 = opts.id,
        animationSpeed     = opts.animationSpeed or 8.5,
        animationPosition  = 0.0,
        animationTarget    = 0.0,
        previousValue      = false,

        -- Style overrides (accept ImU32 or ImVec4)
        onTrackColor       = opts.onTrackColor,
        offTrackColor      = opts.offTrackColor,
        borderOnColor      = opts.borderOnColor,
        borderOffColor     = opts.borderOffColor,
        knobOnColor        = opts.knobOnColor,
        knobOffColor       = opts.knobOffColor,
        glowStrength       = (opts.glowStrength ~= nil) and opts.glowStrength or 0.55,
    }

    -- Normalize a color to vec4 (accepts ImU32 or ImVec4)
    local function toVec4(color, fallbackIdx)
        if color == nil then
            return getStyleColorVec4(fallbackIdx)
        end
        if type(color) == "table" then
            return color
        else
            return imgui.ColorConvertU32ToFloat4(color)
        end
    end

    --- Draw the slider
    -- Returns (updatedValue:boolean, pressed:boolean)
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
            self.previousValue   = updatedValue
        end

        -- Animate
        do
            local dt = imgui.GetIO().DeltaTime
            local direction = (self.animationTarget > self.animationPosition) and 1 or -1
            local step = self.animationSpeed * dt * direction
            local nextPos = self.animationPosition + step

            if (direction > 0 and nextPos > self.animationTarget) or
               (direction < 0 and nextPos < self.animationTarget) then
                self.animationPosition = self.animationTarget
            else
                self.animationPosition = nextPos
            end
        end

        local eased = easeOutCubic(self.animationPosition)

        -- ------- Colors (vec4) with stronger contrast -------
        -- OFF track: darker than FrameBg
        local frameBgV4   = toVec4(nil, ImGuiCol.FrameBg)
        local offTrackV4  = self.offTrackColor and toVec4(self.offTrackColor, ImGuiCol.FrameBg) or scaleRgb(frameBgV4, 0.6)

        -- ON track: a vivid color (use CheckMark as base, brighten)
        local checkMarkV4 = toVec4(nil, ImGuiCol.CheckMark)
        local onTrackV4   = self.onTrackColor and toVec4(self.onTrackColor, ImGuiCol.CheckMark) or scaleRgb(checkMarkV4, 1.25)

        -- Borders: darker when OFF, brighter when ON
        local borderOffV4 = self.borderOffColor and toVec4(self.borderOffColor, ImGuiCol.Border) or toVec4(nil, ImGuiCol.Border)
        local borderOnV4  = self.borderOnColor  and toVec4(self.borderOnColor,  ImGuiCol.HeaderActive) or toVec4(nil, ImGuiCol.HeaderActive)

        -- Knob: neutral/light gray when OFF, near-white when ON for contrast
        local knobOffV4   = self.knobOffColor and toVec4(self.knobOffColor, ImGuiCol.Button) or getStyleColorVec4(ImGuiCol.Button)
        local knobOnV4    = self.knobOnColor  and toVec4(self.knobOnColor,  ImGuiCol.ButtonHovered) or getStyleColorVec4(ImGuiCol.ButtonActive)

        -- Blend track and border with eased
        local trackV4     = lerpVec4(offTrackV4, onTrackV4, eased)
        local borderV4    = lerpVec4(borderOffV4, borderOnV4, eased)

        -- Knob base blends OFF→ON; apply interactive tint if any
        local knobBaseV4  = lerpVec4(knobOffV4, knobOnV4, eased)

        -- Interactive tint for knob (hover/active) – keep it subtle to preserve contrast
        local knobU32Interactive =
              imgui.IsItemClicked()  and imgui.GetColorU32(ImGuiCol.ButtonActive,  0.8)
           or imgui.IsItemHovered() and imgui.GetColorU32(ImGuiCol.ButtonHovered, 0.8)
           or nil

        local trackU32    = u32FromVec4(trackV4)
        local borderU32   = u32FromVec4(borderV4)
        local knobU32     = knobU32Interactive and knobU32Interactive or u32FromVec4(knobBaseV4)

        -- ------- Draw -------
        local drawList     = imgui.GetWindowDrawList()
        local bottomRight  = ImVec2(topLeft.x + sliderWidth, topLeft.y + frameHeight)

        -- Soft glow behind when ON (alpha scales with eased & glowStrength)
        if eased > 0.01 and self.glowStrength > 0.0 then
            -- Use the ON track hue for the glow; two passes for softness
            local glow1 = ImVec4(onTrackV4.x, onTrackV4.y, onTrackV4.z, math.min(0.22 * self.glowStrength * eased, 0.30))
            local glow2 = ImVec4(onTrackV4.x, onTrackV4.y, onTrackV4.z, math.min(0.10 * self.glowStrength * eased, 0.18))
            drawList:AddRectFilled(
                ImVec2(topLeft.x - 2, topLeft.y - 2),
                ImVec2(bottomRight.x + 2, bottomRight.y + 2),
                u32FromVec4(glow2),
                radius + 2
            )
            drawList:AddRectFilled(
                ImVec2(topLeft.x - 1, topLeft.y - 1),
                ImVec2(bottomRight.x + 1, bottomRight.y + 1),
                u32FromVec4(glow1),
                radius + 1
            )
        end

        -- Track + border
        drawList:AddRectFilled(topLeft, bottomRight, trackU32, radius)
        drawList:AddRect(topLeft, bottomRight, borderU32, radius, 0, 1.0)

        -- Knob
        local travel     = sliderWidth - radius * 2.0
        local knobX      = topLeft.x + radius + eased * travel
        local knobCenter = ImVec2(knobX, topLeft.y + radius)
        local knobRadius = radius - 1.5
        drawList:AddCircleFilled(knobCenter, knobRadius, knobU32)

        -- (Removed) inner specular highlight that looked like a white circle

        -- Label (unchanged color for readability)
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
-- switch.lua (OKLCH version)
local imgui  = require('ImGui')
local ImAnim = require('ImAnim') -- animation/colors via imanim

local ToggleSlider = {}

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
--   id: string\number,
--   animDuration: number,
--   ease: IamEaseDesc,
--   animPolicy: IamPolicy,
--   colorSpace: IamColorSpace,           -- defaults to IamColorSpace.OKLCH
--   onTrackColor: ImU32\ImVec4,          -- ON track target (bright)
--   offTrackColor: ImU32\ImVec4,         -- OFF track base (dark)
--   borderOnColor: ImU32\ImVec4,
--   borderOffColor: ImU32\ImVec4,
--   knobOnColor: ImU32\ImVec4,           -- ON knob (light)
--   knobOffColor: ImU32\ImVec4,          -- OFF knob (neutral)
--   glowStrength: number                 -- 0..1, intensity of glow when ON
-- }
function ToggleSlider.new(opts)
  opts = opts or {}
  local self = {
    id = opts.id,

    -- ImAnim configuration (durations/easing/policy/colorspace)
    animDuration = opts.animDuration or 0.16,
    ease        = opts.ease        or ImAnim.EasePreset(IamEaseType.OutCubic),
    animPolicy  = opts.animPolicy  or IamPolicy.Crossfade,
    -- OKLCH by default (you can pass OKLAB/HSV/etc. if desired)
    colorSpace  = opts.colorSpace  or IamColorSpace.OKLCH,

    -- track state (we keep this to seed initial targets cleanly)
    previousValue = false,

    -- Style overrides (accept ImU32 or ImVec4)
    onTrackColor   = opts.onTrackColor,
    offTrackColor  = opts.offTrackColor,
    borderOnColor  = opts.borderOnColor,
    borderOffColor = opts.borderOffColor,
    knobOnColor    = opts.knobOnColor,
    knobOffColor   = opts.knobOffColor,

    glowStrength = (opts.glowStrength ~= nil) and opts.glowStrength or 0.55,
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
  -- ui?: { enabled:boolean=true, disabled_blend:number? }
  function self:draw(label, currentValue, ui)
    local style = imgui.GetStyle()
    local frameHeight = imgui.GetFrameHeight()
    local sliderWidth = frameHeight * 1.55
    local radius = frameHeight * 0.5
    local topLeftX, topLeftY = imgui.GetCursorScreenPos()
    local topLeft = ImVec2(topLeftX, topLeftY)
    local size = ImVec2(sliderWidth, frameHeight)
    local dt = imgui.GetIO().DeltaTime
    local id = imgui.GetID(label)

    -- Interaction
    local pressed = imgui.InvisibleButton(label, size)
    local updatedValue = currentValue
    if pressed then
      updatedValue = not currentValue
    end

    -- --------- Animate knob position with ImAnim ---------
    -- Channels: 1=pos, 2=trackColor, 3=borderColor, 4=knobColor
    local targetPos = updatedValue and 1.0 or 0.0
    local initPos   = (currentValue and 1.0) or 0.0
    local eased = ImAnim.TweenFloat(
      id, 1, targetPos,
      self.animDuration, self.ease, self.animPolicy,
      dt, initPos
    )

    -- ------- Colors (vec4) with stronger contrast -------
    -- OFF track: darker than FrameBg
    local frameBgV4   = toVec4(nil, ImGuiCol.FrameBg)
    local offTrackV4  = self.offTrackColor and toVec4(self.offTrackColor, ImGuiCol.FrameBg) or scaleRgb(frameBgV4, 0.6)
    -- ON track: a vivid color (use CheckMark as base, brighten)
    local checkMarkV4 = toVec4(nil, ImGuiCol.CheckMark)
    local onTrackV4   = self.onTrackColor and toVec4(self.onTrackColor, ImGuiCol.CheckMark) or scaleRgb(checkMarkV4, 1.25)
    -- Borders: darker when OFF, brighter when ON
    local borderOffV4 = self.borderOffColor and toVec4(self.borderOffColor, ImGuiCol.Border) or toVec4(nil, ImGuiCol.Border)
    local borderOnV4  = self.borderOnColor and toVec4(self.borderOnColor, ImGuiCol.HeaderActive) or toVec4(nil, ImGuiCol.HeaderActive)
    -- Knob: neutral/light gray when OFF, near-white when ON for contrast
    local knobOffV4   = self.knobOffColor and toVec4(self.knobOffColor, ImGuiCol.Button) or getStyleColorVec4(ImGuiCol.Button)
    local knobOnV4    = self.knobOnColor and toVec4(self.knobOnColor, ImGuiCol.ButtonHovered) or getStyleColorVec4(ImGuiCol.ButtonActive)

    -- Animate TRACK/BORDER/KNOB colors with ImAnim (OKLCH by default)
    local trackTarget  = updatedValue and onTrackV4   or offTrackV4
    local borderTarget = updatedValue and borderOnV4  or borderOffV4
    local knobTarget   = updatedValue and knobOnV4    or knobOffV4

    local trackV4 = ImAnim.TweenColor(
      id, 2, trackTarget,
      self.animDuration, self.ease, self.animPolicy,
      self.colorSpace, dt, offTrackV4
    )
    local borderV4 = ImAnim.TweenColor(
      id, 3, borderTarget,
      self.animDuration, self.ease, self.animPolicy,
      self.colorSpace, dt, borderOffV4
    )
    local knobBaseV4 = ImAnim.TweenColor(
      id, 4, knobTarget,
      self.animDuration, self.ease, self.animPolicy,
      self.colorSpace, dt, knobOffV4
    )

    -- Interactive tint for knob (hover/active) – keep it subtle to preserve contrast
    local knobU32Interactive =
      imgui.IsItemClicked() and imgui.GetColorU32(ImGuiCol.ButtonActive, 0.8)
      or imgui.IsItemHovered() and imgui.GetColorU32(ImGuiCol.ButtonHovered, 0.8)
      or nil

    -- Optional disabled blending for knob (uses ImAnim.GetBlendedColor in OKLCH)
    local ui_state = ui or {}
    local is_enabled = (ui_state.enabled ~= false)
    local disabled_blend = ui_state.disabled_blend or style.DisabledAlpha -- how much to blend toward disabled
    local disabledRef = getStyleColorVec4(ImGuiCol.TextDisabled)

    local knobShownV4 = (is_enabled and knobBaseV4)
      or ImAnim.GetBlendedColor(knobBaseV4, disabledRef, disabled_blend, self.colorSpace)

    local trackU32  = u32FromVec4(trackV4)
    local borderU32 = u32FromVec4(borderV4)
    local knobU32   = knobU32Interactive and knobU32Interactive or u32FromVec4(knobShownV4)

    -- ------- Draw -------
    local drawList = imgui.GetWindowDrawList()
    local bottomRight = ImVec2(topLeft.x + sliderWidth, topLeft.y + frameHeight)

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
    local travel = sliderWidth - radius * 2.0
    local knobX = topLeft.x + radius + eased * travel
    local knobCenter = ImVec2(knobX, topLeft.y + radius)
    local knobRadius = radius - 1.5
    drawList:AddCircleFilled(knobCenter, knobRadius, knobU32)

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
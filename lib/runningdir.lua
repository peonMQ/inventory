local mq = require 'mq'

---@class RunningDir
---@field scriptPath string
---@field level number
local RunningDir = {scriptPath = '', level = 2}

---@param level number|nil
---@return RunningDir
function RunningDir:new(level)
  self.__index = self
  local o = setmetatable({}, self)
  o.level = level or 2
  o.scriptPath = (debug.getinfo(level or 2, "S").source:sub(2)):match("(.*[\\|/]).*$")
  return o
end

function RunningDir:RelativeToMQLuaPath()
  local relativeUrl = (self.scriptPath:sub(0, #mq.luaDir) == mq.luaDir) and self.scriptPath:sub(#mq.luaDir+1) or self.scriptPath
  if string.sub(relativeUrl, -1, -1) == "/" then
    relativeUrl=string.sub(relativeUrl, 1, -2)
  end

  if string.sub(relativeUrl, -1, -1) == "\\" then
    relativeUrl=string.sub(relativeUrl, 1, -2)
  end

  if string.sub(relativeUrl, 1, 1) == "\\" then
    relativeUrl=string.sub(relativeUrl, 2)
  end

  return relativeUrl
end

function RunningDir:GetRelativeToMQLuaPath(subDir)
  local relativeUrl = self:RelativeToMQLuaPath()
  return relativeUrl..subDir
end

function RunningDir:Parent()
  local immutable = RunningDir:new(self.level + 1)
  immutable.scriptPath = immutable.scriptPath:gsub('([a-zA-Z0-9]*)/$', '')
  return immutable
end

return RunningDir
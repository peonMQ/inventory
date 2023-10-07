--- @type Mq
local mq = require 'mq'
local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')
local doAction = require('actions/action')

---@type RunningDir
local runningDir = luaUtils.RunningDir:Parent()

local exportSearch = require('common/exportsearch')

---@param searchParams SearchParams
---@param includeOffline boolean
---@return table<string, { online: boolean, searchResult: SearchItem }>
local function search(searchParams, includeOffline)
  local searchResult = {}
  if includeOffline then
    searchResult = exportSearch(searchParams)
  end

  local command = string.format('/lua run %s %s "%s"', runningDir:GetRelativeToMQLuaPath("/search"),  mq.TLO.Me.Name(), searchParams:ToSearchString())
  doAction(command)
  return searchResult
end

return search

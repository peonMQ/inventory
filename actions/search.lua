--- @type Mq
local mq = require 'mq'
local logger = require('utils/logging')
local luaUtils = require('utils/lua-paths')
local doAction = require('actions/action')

---@type RunningDir
local runningDir = luaUtils.RunningDir:new()

local exportSearch = require('common/exportsearch')

---@param searchterms string
---@param includeOffline boolean
---@return table<string, { online: boolean, searchResult: SearchItem }>
local function search(searchterms, includeOffline)
  local searchResult = {}
  if includeOffline then
    searchResult = exportSearch(searchterms)
  end

  local command = string.format('/lua run %s %s "%s"', "inventory/search",  mq.TLO.Me.Name(), searchterms)
  doAction(command)

  return searchResult
end

return search

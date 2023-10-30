local mq = require 'mq'
local runningDir = require('lib/runningdir')
local remoteAction = require('actions/remoteAction')

---@type RunningDir
local searchScriptPath = runningDir:Parent():GetRelativeToMQLuaPath("/search")

local exportSearch = require('common/exportsearch')

---@param searchParams SearchParams
---@param includeOffline boolean
---@return table<string, { online: boolean, searchResult: SearchItem }>
local function search(searchParams, includeOffline)
  local searchResult = {}
  if includeOffline then
    searchResult = exportSearch(searchParams)
  end

  local command = string.format('/lua run %s %s "%s"', searchScriptPath,  mq.TLO.Me.Name(), searchParams:ToSearchString())
  remoteAction(command)
  return searchResult
end

return search

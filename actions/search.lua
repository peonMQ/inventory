local mq = require 'mq'
local logger = require('knightlinc/Write')
local runningDir = require('lib/runningdir')
local state = require('state')
local remoteAction = require('actions/remoteAction')
local exportSearch = require('actions/exportsearch')

---@type RunningDir
local searchScriptPath = runningDir:Parent():GetRelativeToMQLuaPath("/search")

---@param searchParams SearchParams
---@param includeOffline boolean
---@param inclAllOnline boolean
local function search(searchParams, includeOffline, inclAllOnline)
  state.ResetResult()
  if includeOffline then
    state.SearchResult = exportSearch(searchParams)
  end

  local command = string.format('/lua run %s %s "%s"', searchScriptPath,  mq.TLO.Me.Name(), searchParams:ToSearchString())
  if inclAllOnline then
    remoteAction(command)
  else
    mq.cmd(command)
  end
end

return search

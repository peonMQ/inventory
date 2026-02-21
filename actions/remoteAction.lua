local broadcaster = require('broadcast/broadcastinterface')("EQBC")

---@param command string
---@param character? string
local function executeRemoteAction(command, character)
  if character then
    broadcaster.ExecuteCommand(command, {character})
  else
    broadcaster.ExecuteAllWithSelfCommand(command)
  end
end

return executeRemoteAction
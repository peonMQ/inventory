local remoteAction = require('actions/remoteAction')

local function autoinventory()
  local command = "/autoinv"
  remoteAction(command)
end

return autoinventory
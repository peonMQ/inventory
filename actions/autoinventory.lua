local mq = require 'mq'
local logger = require('utils/logging')
local doAction = require('actions/action')

local function autoinventory()
  local command = "/autoinv"
  doAction(command)
end

return autoinventory
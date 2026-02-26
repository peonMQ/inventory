local actors = require("actors")
local logger = require 'knightlinc/Write'
local state = require('state')
local searchItem = require('common/searchitem')

---@class SearchMessage: Message
---@field content SearchItemResult
---@field reply fun()
---@field send fun(message: SearchItemResult)


---@param message SearchMessage
local function handleMessage(message)
  logger.Debug("Inventory actor message recieved.");
  if message.sender.character then
    local searchItemResult = message.content
    table.insert(state.SearchResult, searchItemResult)
  end
end

actors.register(state.SearchMailBox, handleMessage)
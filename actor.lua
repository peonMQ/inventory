local actors = require("actors")
local logger = require('knightlinc/Write')
local state = require('state')
local searchItemResult = require('common/searchitemresult')

---@class SearchMessage: Message
---@field content {Character: string, Item: SearchItem}
---@field send fun(message: SearchItemResult)


---@param message SearchMessage
local function handleMessage(message)
  logger.Debug("Inventory actor message recieved.");
  if message.sender.character then
    local searchItemResult = searchItemResult:convert(#state.SearchResult, message.content.Character, true, message.content.Item)
    table.insert(state.SearchResult, searchItemResult)
  end

  message:reply(0, {})
end

return actors.register(state.SearchMailBox, handleMessage)
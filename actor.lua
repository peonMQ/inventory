local actors = require("actors")
local logger = require 'knightlinc/Write'
local state = require('state')
local searchItem = require('common/searchitem')

---@class SearchItemResult
---@field public Id number
---@field public Name string
---@field public Type string
---@field public Icon number
---@field public Amount number
---@field public InventorySlot number
---@field public BagSlot number
---@field public Container number
---@field public Damage number
---@field public Classes string[]
---@field public WornSlots string[]
---@field public ItemLink string


---@class SearchMessage: Message
---@field content SearchItemResult
---@field reply fun()
---@field send fun(message: SearchItemResult)


---@param message SearchMessage
local function handleMessage(message)
  logger.Debug("Inventory actor message recieved.");
  if message.sender.character then
    local searchItemResult = message.content
    local searchedItem = searchItem:new(searchItemResult.Id, searchItemResult.Name, searchItemResult.Type, searchItemResult.Amount, searchItemResult.InventorySlot, searchItemResult.BagSlot, searchItemResult.Container, searchItemResult.Icon, searchItemResult.Damage, searchItemResult.Classes, searchItemResult.WornSlots, searchItemResult.ItemLink)
    local toonResult = state.SearchResult[message.sender.character] or { online = true, searchResult = {} }
    table.insert(toonResult.searchResult, searchedItem)
    if not state.SearchResult[message.sender.character] then
      state.SearchResult[message.sender.character] = toonResult
    end
  end
end

actors.register(state.SearchMailBox, handleMessage)
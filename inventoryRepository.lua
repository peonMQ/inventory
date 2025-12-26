local mq = require('mq')
local packageMan = require('mq/PackageMan')
local broadcast = require 'broadcast/broadcast'
local logger = require('knightlinc/Write')
local _searchItem = require 'common/searchitem'

local sqlite3 = packageMan.Require('lsqlite3')
local configDir = (mq.configDir.."/"):gsub("\\", "/"):gsub("%s+", "%%20")
local serverName = mq.TLO.MacroQuest.Server()
local dbFileName = configDir..serverName.."/data/inventory.db"
local connectingString = string.format("file:///%s?cache=shared&mode=rwc&_journal_mode=WAL", dbFileName)
local db = sqlite3.open(connectingString, sqlite3.OPEN_READWRITE + sqlite3.OPEN_CREATE + sqlite3.OPEN_URI)

local unpack = table.unpack or unpack

db:exec[[
  PRAGMA journal_mode=WAL;
  CREATE TABLE IF NOT EXISTS inventory (
      inventory_id INTEGER PRIMARY KEY
      , character_name TEXT NOT NULL
      , item_id INTEGER
      , item_name INTEGER
      , amount INTEGER
      , inventory_slot INTEGER
      , bag_slot INTEGER
      , item_link TEXT
  );
]]

-- Trim whitespace from both ends
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param terms string[]
local function build_and_instr_clause(terms)
  local clauses, params = {}, {}
  for _, t in ipairs(terms or {}) do
    local term = trim(t or "")
    if term ~= "" then
      table.insert(clauses, "instr(lower(item_name), lower(?)) > 0")
      table.insert(params, term)
    end
  end
  return clauses, params
end

---@param terms string[]
---@return table<string, SearchItem[]>
local function getItems(terms)
  local clauses, params = build_and_instr_clause(terms)
  if #clauses == 0 then return {} end

  local sql = "SELECT * FROM inventory WHERE " .. table.concat(clauses, " AND ")
  local stmt = assert(db:prepare(sql))
  assert(stmt:bind_values(unpack(params)))

  local results = {}
  for row in stmt:nrows() do 
    if not results[row.character_name] then
      results[row.character_name] = {_searchItem:new(row.item_id, row.item_name, row.amount, row.inventory_slot, row.bag_slot, row.item_link)}
    else
      table.insert(results[row.character_name], _searchItem:new(row.item_id, row.item_name, row.amount, row.inventory_slot, row.bag_slot, row.item_link))
    end
  end
  stmt:finalize()
  return results
end

local deleteStmt = assert(
  db:prepare([[
    DELETE FROM inventory WHERE character_name = ?
  ]]),
  db:errmsg()
)

---@param characterName string
---@return boolean
local function deleteInt(characterName)
  logger.Info("Clearing items for <" .. characterName .. ">")

  while true do
    deleteStmt:reset()
    deleteStmt:bind_values(characterName)

    local rc = deleteStmt:step()

    if rc == sqlite3.DONE then
      logger.Info("Completed clearing items for <" .. characterName .. ">")
      return true
    end

    if rc == sqlite3.BUSY or rc == sqlite3.LOCKED then
      mq.delay(5) -- short backoff
    else
      logger.Error("DELETE failed (%s): %s", tostring(rc), db:errmsg())
      broadcast.ErrorAll("DELETE failed (%s): %s", tostring(rc), db:errmsg())
      return false
    end
  end
end

---@param characterName string
local function delete(characterName)
  db:exec("BEGIN IMMEDIATE")
  deleteInt(characterName)
  db:exec("COMMIT")
end

local insertStmt = assert(
  db:prepare([[
    INSERT INTO inventory
    (character_name, item_id, item_name, amount, inventory_slot, bag_slot, item_link)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]]),
  db:errmsg()
)

---@param characterName string
---@param searchItem SearchItem
local function insert(characterName, searchItem)
  while true do
    insertStmt:reset()

    insertStmt:bind_values(
      characterName,
      searchItem.Id,
      searchItem.Name,
      searchItem.Amount,
      searchItem.InventorySlot,
      searchItem.BagSlot,
      searchItem.ItemLink
    )

    local rc = insertStmt:step()

    if rc == sqlite3.DONE then
      return true
    end

    if rc == sqlite3.BUSY or rc == sqlite3.LOCKED then
      mq.delay(5)
    else
      logger.Error("INSERT failed (%s): %s", tostring(rc), db:errmsg())
      broadcast.ErrorAll("INSERT failed (%s): %s", tostring(rc), db:errmsg())
      return false
    end
  end
end


---@param characterName string
---@param searchItems SearchItem[]
local function insertAll(characterName, searchItems)
  db:exec("BEGIN IMMEDIATE")
  for _, item in ipairs(searchItems) do
    insert(characterName, item)
  end

  db:exec("COMMIT")
  logger.Info("Completed inserting items for <" .. characterName .. ">")
end

local repository = {
  GetItems = getItems,
  Delete = delete,
  Insert = insert,
  InsertAll = insertAll
}

return repository
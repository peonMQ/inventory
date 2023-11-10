local state = require 'state'

local function clearState()
  state.Searchterms = ''
  state.SearchResult = {}
end

return clearState
local state = {
  SearchMailBox = 'search',
  Searchterms = '',
---@type SearchItemResult[]
  SearchResult = {}
}

state.Reset = function()
  state.Searchterms = ''
  state.ResetResult()
end


state.ResetResult = function()
  state.SearchResult = {}
end

return state
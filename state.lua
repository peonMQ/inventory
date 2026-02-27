local state = {
  SearchMailBox = 'searchresult',
  Searchterms = '',
  SelectionFlags = 0x0,
---@type SearchItemResult[]
  SearchResult = {}
}

state.Reset = function()
  state.Searchterms = ''
  state.ResetResult()
end


state.ResetResult = function()
  state.SelectionFlags = 0x0
  state.SearchResult = {}
end

return state
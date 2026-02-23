local state = {
  SearchMailBox = 'search',
  Searchterms = '',
---@type table<string, { online: boolean, searchResult: SearchItem[] }>
  SearchResult = {}
}

return state
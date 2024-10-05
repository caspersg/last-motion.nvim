-- helpers to reproduce the original search behaviour for / ? * #
local state = require("last-motion.state")

local M = {}

local function set_searching()
  if state.get(0) then
    -- store this on last, as it automatically gets reset
    state.get(0).searching = true
  end
end

local function is_searching()
  return state.get(0) and state.get(0).searching
end

--- The same as default behaviour of * and n/N, but in one function
M.next_search = function()
  if is_searching() then
    M.next_for_recent_search()
  else
    -- a new search since we have a fresh state.last value
    vim.cmd("normal! *")
    set_searching()
  end
end

--- The same as default behaviour of # and n/N, but in one function
M.prev_search = function()
  if is_searching() then
    M.prev_for_recent_search()
  else
    -- a new search since we have a fresh state.last value
    vim.cmd("normal! #")
    set_searching()
  end
end

--- Any movement after a search will override state.last, so that search is forgotten and highlights may be off.
--- So we need a way to get back whatever the most recent search was, and continue through results.
--- The last count is lost, but you can add count to this keymap.
M.next_for_recent_search = function()
  local recent_search = vim.fn.getreg("/")
  if not recent_search then
    return
  end
  vim.fn.search(recent_search)
  vim.opt.hlsearch = true
end

--- Same as next_for_recent_search, but in reverse direction.
M.prev_for_recent_search = function()
  local recent_search = vim.fn.getreg("/")
  if not recent_search then
    return
  end
  vim.fn.search(recent_search, "b")
  vim.opt.hlsearch = true
end

return M

-- helpers to reproduce the original search behaviour for / ? * #
local state = require("last-motion.state")

local M = {
    -- FIXME: make this work with history
}

local function set_last_search()
    state.last().last_search = vim.fn.getreg("/")
end

local function find_last_search()
    if state.last().last_search then
        return vim.fn.getreg("/")
    end
    return nil
end

--- The same as default behaviour of * and n/N, but in one function
M.next_search = function()
    local last_search = find_last_search()
    if last_search then
        -- use the last search, not a new one
        vim.fn.search(last_search)
        vim.opt.hlsearch = true
    else
        -- a new search since we have a fresh state.last value
        vim.cmd("normal! *")
        set_last_search()
    end
end

--- The same as default behaviour of # and n/N, but in one function
M.prev_search = function()
    local last_search = find_last_search()
    if last_search then
        -- use the last search, not a new one
        vim.fn.search(last_search, "b")
        vim.opt.hlsearch = true
    else
        -- a new search since we have a fresh state.last value
        vim.cmd("normal! #")
        set_last_search()
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
    set_last_search()
    vim.fn.search(recent_search)
    vim.opt.hlsearch = true
end

--- Same as next_for_recent_search, but in reverse direction.
M.prev_for_recent_search = function()
    local recent_search = vim.fn.getreg("/")
    if not recent_search then
        return
    end
    set_last_search()
    vim.fn.search(recent_search, "b")
    vim.opt.hlsearch = true
end

return M

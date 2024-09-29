-- helpers to reproduce the original search behaviour for / ? * #

local M = {
    --- State which stores the last motion, to be repeated
    last_search = nil,
}

local function set_last_search()
    M.last_search = vim.fn.getreg("/")
end

--- The same as default behaviour of * and n/N, but in one function
M.next_search = function()
    if M.last and M.last_search then
        -- use the last search, not a new one
        vim.fn.search(M.last_search)
    else
        -- a new search since we have a fresh state.last value
        vim.cmd("normal! *")
        set_last_search()
    end
end

--- The same as default behaviour of # and n/N, but in one function
M.prev_search = function()
    if M.last and M.last_search then
        -- use the last search, not a new one
        vim.fn.search(M.last_search, "b")
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
    if not M.last_search then
        return
    end
    set_last_search()
    vim.fn.search(M.last_search)
    vim.opt.hlsearch = true
end

--- Same as next_for_recent_search, but in reverse direction.
M.prev_for_recent_search = function()
    if not M.last_search then
        return
    end
    set_last_search()
    vim.fn.search(M.last_search, "b")
    vim.opt.hlsearch = true
end

return M

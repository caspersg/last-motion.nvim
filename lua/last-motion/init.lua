-- try to log every motion, so we can remember and then repeat them
-- adds count to the repeats, and maintains any existing counts
-- conditionally can deal with operator pending keys too
local M = {
    -- remember the last motion
    last = nil,

    -- internal functions
    utils = {},
}

M.utils.notify_last_motion = function()
    vim.notify("last motion" .. vim.inspect(M.last))
end

M.utils.exec = function(count, action, pending_chars)
    if type(action) == "string" then
        -- Handle motion command
        local countstr = count > 0 and count or ""
        local cmd = countstr .. action .. (pending_chars or "")
        -- vim.cmd can't handle control and other special keys
        -- vim.cmd("normal! "..cmd)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n", false)
    -- vim.notify("cmd " .. cmd)
    elseif type(action) == "function" then
        -- add count to any repeated motion
        for _ = 1, math.max(count, 1) do
            action()
        end
    else
        error("Invalid action type: " .. type(action))
    end
end

M.utils.remember = function(def, reverse)
    return function()
        local count = vim.v.count
        local charstr = nil
        if def.pending then
            -- this motion has operator pending mode, so get those chars
            charstr = vim.fn.nr2char(vim.fn.getchar())
        end
        M.last = {
            count = count,
            charstr = charstr,
            desc = def.desc, -- just for debugging
            command = def.command, -- just for debugging
            forward = def.next,
            backward = def.prev,
        }
        if reverse then
            -- maintain the current direction, so if moving backwards, next continues backwards
            M.last.forward = def.prev
            M.last.backward = def.next
        end

        if not def.command then
            -- commands are detected with hooks, so they've already been called
            M.utils.exec(M.last.count, M.last.forward, M.last.charstr)
        end
    end
end

--[[
  The same as default behaviour of * and n/N, but in one function
]]
M.utils.next_search = function()
    if M.last.search then
        -- use the last search, not a new one
        vim.fn.search(M.last.search)
    else
        -- a new search since we have a fresh M.last value
        vim.cmd("normal! *")
        M.last.search = vim.fn.getreg("/")
    end
end

--[[
  The same as default behaviour of # and n/N, but in one function
]]
M.utils.prev_search = function()
    if M.last.search then
        -- use the last search, not a new one
        vim.fn.search(M.last.search, "b")
    else
        -- a new search since we have a fresh M.last value
        vim.cmd("normal! #")
        M.last.search = vim.fn.getreg("/")
    end
end

--[[
  Any movement after a search will override M.last, so that search is forgotten and highlights may be off.
  So we need a way to get back whatever the most recent search was, and continue through results.
  The last count is lost, but you can add count to this keymap.
]]
M.utils.next_for_recent_search = function()
    M.last.search = vim.fn.getreg("/")
    vim.fn.search(M.last.search)
    vim.opt.hlsearch = true
end

--[[
  Same as next_for_recent_search, but in reverse direction.
]]
M.utils.prev_for_recent_search = function()
    M.last.search = vim.fn.getreg("/")
    vim.fn.search(M.last.search, "b")
    vim.opt.hlsearch = true
end

local group = vim.api.nvim_create_augroup("last-motion", {})

M.register = function(def)
    if def.command then
        vim.api.nvim_create_autocmd("CmdlineLeave", {
            group = group,
            callback = function()
                if not vim.v.event.abort and vim.fn.expand("<afile>") == def.command then
                    -- call the closure immediately
                    M.utils.remember(def, false)()
                end
            end,
        })
        -- commands are a hook, so we don't need a new keymap
        return
    end

    -- always add keymaps for existing keys
    def.next_keys = def.next_keys or {}
    def.prev_keys = def.prev_keys or {}
    if type(def.next) == "string" then
        table.insert(def.next_keys, def.next)
    end
    if type(def.prev) == "string" then
        table.insert(def.prev_keys, def.prev)
    end

    -- add new keymaps
    local mapopts = { desc = def.desc, noremap = true, silent = true }
    for _, key in ipairs(def.next_keys) do
        vim.keymap.set("n", key, M.utils.remember(def, false), mapopts)
    end
    if def.prev_keys then
        for _, key in ipairs(def.prev_keys) do
            vim.keymap.set("n", key, M.utils.remember(def, true), mapopts)
        end
    end
    -- print("last-motion registered " .. vim.inspect(def))
end

M.forward = function()
    if M.last then
        M.utils.exec(M.last.count, M.last.forward, M.last.charstr)
    end
end

M.backward = function()
    if M.last then
        M.utils.exec(M.last.count, M.last.backward, M.last.charstr)
    end
end

-- it doesn't matter which key in a pair is next or prev, as direction is preserved
M.default_definitions = {
    -- obvious ones
    { next = "h", prev = "l" },
    { next = "j", prev = "k" },
    { next = "w", prev = "b" },
    { next = "W", prev = "B" },
    { next = "}", prev = "{" },
    { next = ")", prev = "(" },
    { next = "<C-d>", prev = "<C-u>" },
    { next = "<C-f>", prev = "<C-b>" },
    { next = "<C-i>", prev = "<C-o>" },

    -- non obvious ones
    { next = "e", prev = "ge" },
    { next = "E", prev = "gE" },
    { next = "g_", prev = "^" },
    { next = "$", prev = "0" },
    { next = "G", prev = "gg" },

    -- operator pending motions
    { next = "f", prev = "F", pending = true },
    { next = "t", prev = "T", pending = true },

    -- default commands, these are a special case as they use command mode
    { command = "/", next = "n", prev = "N" },
    { command = "?", next = "n", prev = "N" },

    -- some other functions
    {
        desc = "search",
        next_keys = { "*" },
        prev_keys = { "#" },
        next = M.utils.next_search,
        prev = M.utils.prev_search,
    },
    {
        -- adds being able to get back to recent search results after other movements
        desc = "recent [s]earch",
        next_keys = { ",s" },
        next = M.utils.next_for_recent_search,
        prev = M.utils.prev_for_recent_search,
    },

    {
        desc = "[d]iagnostic",
        next_keys = { ",d" },
        next = vim.diagnostic.goto_next,
        prev = vim.diagnostic.goto_prev,
    },
    {
        desc = "fo[l]d",
        next_keys = { ",l" },
        next = "zj",
        prev = "zk",
    },

    {
        desc = "[w]indow",
        next_keys = { ",w" },
        next = "<C-w>w",
        prev = "<C-w>W",
    },

    {
        desc = "[q]uickfix item",
        next_keys = { ",q" },
        next = vim.cmd.cnext,
        prev = vim.cmd.cprevious,
    },

    -- I use bufferline specific commands instead
    -- {
    --   desc = "[b]uffer",
    --   next_keys = { ",b", "]b" },
    --   prev_keys = { "[b" },
    --   next = vim.cmd.bnext,
    --   prev = vim.cmd.bprevious,
    -- },

    {
        desc = "[t]ab",
        next_keys = { ",t", "]t" },
        prev_keys = { "[t" },
        next = vim.cmd.tabnext,
        prev = vim.cmd.tabprevious,
    },
}

M.setup = function(opts)
    for _, definition in ipairs(M.default_definitions) do
        M.register(definition)
    end

    vim.keymap.set("n", "n", M.forward, { desc = "repeat last motion", noremap = true, silent = true })
    vim.keymap.set("n", "N", M.backward, { desc = "reverse last motion", noremap = true, silent = true })
end

return M

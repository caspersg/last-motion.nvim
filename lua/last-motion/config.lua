local search = require("last-motion.search")
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_move = require("nvim-treesitter.textobjects.move")

local function ts_next(query)
    return function()
        ts_move.goto_next_start(query)
    end
end

local function ts_prev(query)
    return function()
        ts_move.goto_previous_start(query)
    end
end

return {
    max_motions = 10,

    -- it doesn't matter which key in a pair is next or prev, as direction is preserved
    definitions = {
        -- character motions are maybe pointless
        { next = "h", prev = "l" },
        { next = "j", prev = "k" },

        -- obvious ones
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
        -- { command = ":bnext", next = ":bnext", prev = ":bprev" },

        -- some other functions
        {
            desc = "search",
            next_keys = { "*" },
            prev_keys = { "#" },
            next = search.next_search,
            prev = search.prev_search,
        },
        {
            -- adds being able to get back to recent search results after other movements
            desc = "recent [s]earch",
            next_keys = { ",s" },
            next = search.next_for_recent_search,
            prev = search.prev_for_recent_search,
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

        -- treesitter functions

        {
            desc = "[a]ttribute",
            next_keys = { ",ta" },
            next = ts_next("@attribute.inner"),
            prev = ts_prev("@attribute.inner"),
        },

        {
            desc = "fra[m]e",
            next_keys = { ",tm" },
            next = ts_next("@frame.inner"),
            prev = ts_prev("@frame.inner"),
        },

        {
            desc = "c[o]mment",
            next_keys = { ",to" },
            next = ts_next("@comment.outer"),
            prev = ts_prev("@comment.outer"),
        },

        {
            desc = "[b]lock",
            next_keys = { ",tb" },
            next = ts_next("@block.inner"),
            prev = ts_prev("@block.inner"),
        },

        {
            desc = "[r]eturn",
            next_keys = { ",tr" },
            next = ts_next("@return.inner"),
            prev = ts_prev("@return.inner"),
        },

        {
            desc = "[p]arameter",
            next_keys = { ",tp" },
            next = ts_next("@parameter.inner"),
            prev = ts_prev("@parameter.inner"),
        },

        {
            desc = "ca[l]l",
            next_keys = { ",tl" },
            next = ts_next("@call.outer"),
            prev = ts_prev("@call.outer"),
        },

        {
            desc = "[a]ssignment",
            next_keys = { ",ta" },
            next = ts_next("@assignment.rhs"),
            prev = ts_prev("@assignment.rhs"),
        },

        {
            desc = "con[d]itional",
            next_keys = { ",td" },
            next = ts_next("@conditional.inner"),
            prev = ts_prev("@conditional.inner"),
        },

        {
            desc = "[c]lass",
            next_keys = { ",tc" },
            next = ts_next("@class.inner"),
            prev = ts_prev("@class.inner"),
        },

        {
            desc = "[f]unction",
            next_keys = { ",tf" },
            next = ts_next("@function.outer"),
            prev = ts_prev("@function.outer"),
        },

        {
            desc = "[n]ode",
            next_keys = { ",tn" },
            next = function()
                local node = ts_utils.get_node_at_cursor()
                if node == nil then
                    error("No Treesitter parser found.")
                    return
                end
                local next = ts_utils.get_next_node(node, true, false)
                if next == nil then
                    -- vim.notify("No next node found.")
                end
                ts_utils.goto_node(next, true, false)
            end,
            prev = function()
                local node = ts_utils.get_node_at_cursor()
                if node == nil then
                    error("No Treesitter parser found.")
                    return
                end
                local prev = ts_utils.get_previous_node(node, true, false)
                if prev == nil then
                    -- vim.notify("No prev node found.")
                end
                ts_utils.goto_node(prev, true, false)
            end,
        },
    },
}

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
            next_key = "*",
            prev_key = "#",
            next = search.next_search,
            prev = search.prev_search,
        },
        {
            -- adds key to get back to recent search results after other movements
            -- this is needed if you override n and N with repeating motions
            desc = "recent [s]earch",
            next_key = "]s",
            prev_key = "[s",
            next = search.next_for_recent_search,
            prev = search.prev_for_recent_search,
        },

        {
            desc = "[d]iagnostic",
            next_key = "]d",
            prev_key = "[d",
            next = vim.diagnostic.goto_next,
            prev = vim.diagnostic.goto_prev,
        },

        {
            desc = "fo[l]d",
            next_key = "]l",
            prev_key = "[l",
            next = "zj",
            prev = "zk",
        },

        {
            desc = "[w]indow",
            next_key = "]w",
            prev_key = "[w",
            next = "<C-w>w",
            prev = "<C-w>W",
        },

        {
            desc = "[q]uickfix item",
            next_key = "]q",
            prev_key = "[q",
            next = vim.cmd.cnext,
            prev = vim.cmd.cprevious,
        },

        {
            desc = "[b]uffer",
            next_key = "]b",
            prev_key = "[b",
            next = vim.cmd.bnext,
            prev = vim.cmd.bprevious,
        },

        {
            desc = "[t]ab",
            next_key = "]t",
            prev_key = "[t",
            next = vim.cmd.tabnext,
            prev = vim.cmd.tabprevious,
        },

        -- treesitter functions

        {
            desc = "[a]ttribute",
            next_key = "]a",
            prev_key = "[a",
            next = ts_next("@attribute.inner"),
            prev = ts_prev("@attribute.inner"),
        },

        {
            desc = "fram[e]",
            next_key = "]e",
            prev_key = "[e",
            next = ts_next("@frame.inner"),
            prev = ts_prev("@frame.inner"),
        },

        {
            desc = "c[o]mment",
            next_key = "]o",
            prev_key = "[o",
            next = ts_next("@comment.outer"),
            prev = ts_prev("@comment.outer"),
        },

        {
            desc = "bloc[k]",
            next_key = "]k",
            prev_key = "[k",
            next = ts_next("@block.inner"),
            prev = ts_prev("@block.inner"),
        },

        {
            desc = "[r]eturn",
            next_key = "]r",
            prev_key = "[r",
            next = ts_next("@return.inner"),
            prev = ts_prev("@return.inner"),
        },

        {
            desc = "[p]arameter",
            next_key = "]p",
            prev_key = "[p",
            next = ts_next("@parameter.inner"),
            prev = ts_prev("@parameter.inner"),
        },

        {
            desc = "[c]all",
            next_key = "]c",
            prev_key = "[c",
            next = ts_next("@call.outer"),
            prev = ts_prev("@call.outer"),
        },

        {
            desc = "[a]ssignment",
            next_key = "]a",
            prev_key = "[a",
            next = ts_next("@assignment.rhs"),
            prev = ts_prev("@assignment.rhs"),
        },

        {
            desc = "co[N]ditional",
            next_key = "]N",
            prev_key = "[N",
            next = ts_next("@conditional.inner"),
            prev = ts_prev("@conditional.inner"),
        },

        {
            desc = "[C]lass",
            next_key = "]C",
            prev_key = "[C",
            next = ts_next("@class.inner"),
            prev = ts_prev("@class.inner"),
        },

        {
            desc = "[f]unction",
            next_key = "]f",
            prev_key = "[f",
            next = ts_next("@function.outer"),
            prev = ts_prev("@function.outer"),
        },

        {
            desc = "[n]ode",
            next_key = "]n",
            prev_key = "[n",
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

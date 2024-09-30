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
            next = "*",
            prev = "#",
            next_func = search.next_search,
            prev_func = search.prev_search,
        },
        {
            -- adds key to get back to recent search results after other movements
            -- this is needed if you override n and N with repeating motions
            desc = "recent [s]earch",
            next = "]s",
            prev = "[s",
            next_func = search.next_for_recent_search,
            prev_func = search.prev_for_recent_search,
        },

        {
            desc = "[d]iagnostic",
            next = "]d",
            prev = "[d",
            next_func = vim.diagnostic.goto_next,
            prev_func = vim.diagnostic.goto_prev,
        },

        {
            desc = "fo[l]d",
            next = "]l",
            prev = "[l",
            next_key = "zj",
            prev_key = "zk",
        },

        {
            desc = "[w]indow",
            next = "]w",
            prev = "[w",
            next_key = "<C-w>w",
            prev_key = "<C-w>W",
        },

        {
            desc = "[q]uickfix item",
            next = "]q",
            prev = "[q",
            next_func = vim.cmd.cnext,
            prev_func = vim.cmd.cprevious,
        },

        {
            desc = "[b]uffer",
            next = "]b",
            prev = "[b",
            next_func = vim.cmd.bnext,
            prev_func = vim.cmd.bprevious,
        },

        {
            desc = "[t]ab",
            next = "]t",
            prev = "[t",
            next_func = vim.cmd.tabnext,
            prev_func = vim.cmd.tabprevious,
        },

        -- treesitter functions

        {
            desc = "[a]ttribute",
            next = "]a",
            prev = "[a",
            next_func = ts_next("@attribute.inner"),
            prev_func = ts_prev("@attribute.inner"),
        },

        {
            desc = "fram[e]",
            next = "]e",
            prev = "[e",
            next_func = ts_next("@frame.inner"),
            prev_func = ts_prev("@frame.inner"),
        },

        {
            desc = "c[o]mment",
            next = "]o",
            prev = "[o",
            next_func = ts_next("@comment.outer"),
            prev_func = ts_prev("@comment.outer"),
        },

        {
            desc = "bloc[k]",
            next = "]k",
            prev = "[k",
            next_func = ts_next("@block.inner"),
            prev_func = ts_prev("@block.inner"),
        },

        {
            desc = "[r]eturn",
            next = "]r",
            prev = "[r",
            next_func = ts_next("@return.inner"),
            prev_func = ts_prev("@return.inner"),
        },

        {
            desc = "[p]arameter",
            next = "]p",
            prev = "[p",
            next_func = ts_next("@parameter.inner"),
            prev_func = ts_prev("@parameter.inner"),
        },

        {
            desc = "[c]all",
            next = "]c",
            prev = "[c",
            next_func = ts_next("@call.outer"),
            prev_func = ts_prev("@call.outer"),
        },

        {
            desc = "[a]ssignment",
            next = "]a",
            prev = "[a",
            next_func = ts_next("@assignment.rhs"),
            prev_func = ts_prev("@assignment.rhs"),
        },

        {
            desc = "co[N]ditional",
            next = "]N",
            prev = "[N",
            next_func = ts_next("@conditional.inner"),
            prev_func = ts_prev("@conditional.inner"),
        },

        {
            desc = "[C]lass",
            next = "]C",
            prev = "[C",
            next_func = ts_next("@class.inner"),
            prev_func = ts_prev("@class.inner"),
        },

        {
            desc = "[f]unction",
            next = "]f",
            prev = "[f",
            next_func = ts_next("@function.outer"),
            prev_func = ts_prev("@function.outer"),
        },

        {
            desc = "[n]ode",
            next = "]n",
            prev = "[n",
            next_func = function()
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
            prev_func = function()
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

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
            -- adds key to get back to recent search results after other movements
            -- this is needed if you override n and N with repeating motions
            desc = "recent [s]earch",
            next_keys = { "]s", ",s" },
            prev_keys = { "[s", ",S" },
            next = search.next_for_recent_search,
            prev = search.prev_for_recent_search,
        },

        {
            desc = "[d]iagnostic",
            next_keys = { "]d", ",d" },
            prev_keys = { "[d", ",D" },
            next = vim.diagnostic.goto_next,
            prev = vim.diagnostic.goto_prev,
        },
        {
            desc = "fo[l]d",
            next_keys = { "]l", ",l" },
            prev_keys = { "[l", ",L" },
            next = "zj",
            prev = "zk",
        },

        {
            desc = "[w]indow",
            next_keys = { "]w", ",w" },
            prev_keys = { "[w", ",W" },
            next = "<C-w>w",
            prev = "<C-w>W",
        },

        {
            desc = "[q]uickfix item",
            next_keys = { "]q", ",q" },
            prev_keys = { "[q", ",Q" },
            next = vim.cmd.cnext,
            prev = vim.cmd.cprevious,
        },

        {
            desc = "[b]uffer",
            next_keys = { "]b", ",b" },
            prev_keys = { "[b", ",B" },
            next = vim.cmd.bnext,
            prev = vim.cmd.bprevious,
        },

        {
            desc = "[t]ab",
            next_keys = { "]t", ",t" },
            prev_keys = { "[t", ",T" },
            next = vim.cmd.tabnext,
            prev = vim.cmd.tabprevious,
        },

        -- treesitter functions

        {
            desc = "[a]ttribute",
            next_keys = { "]a", ",ta" },
            prev_keys = { "[a", ",tA" },
            next = ts_next("@attribute.inner"),
            prev = ts_prev("@attribute.inner"),
        },

        {
            desc = "fram[e]",
            next_keys = { "]e", ",te" },
            prev_keys = { "[e", ",tE" },
            next = ts_next("@frame.inner"),
            prev = ts_prev("@frame.inner"),
        },

        {
            desc = "c[o]mment",
            next_keys = { "]o", ",to" },
            prev_keys = { "[o", ",tO" },
            next = ts_next("@comment.outer"),
            prev = ts_prev("@comment.outer"),
        },

        {
            desc = "bloc[k]",
            next_keys = { "]k", ",tk" },
            prev_keys = { "[k", ",tK" },
            next = ts_next("@block.inner"),
            prev = ts_prev("@block.inner"),
        },

        {
            desc = "[r]eturn",
            next_keys = { "]r", ",tr" },
            prev_keys = { "[r", ",tR" },
            next = ts_next("@return.inner"),
            prev = ts_prev("@return.inner"),
        },

        {
            desc = "[p]arameter",
            next_keys = { "]p", ",tp" },
            prev_keys = { "[p", ",tP" },
            next = ts_next("@parameter.inner"),
            prev = ts_prev("@parameter.inner"),
        },

        {
            desc = "[c]all",
            next_keys = { "]c", ",tl" },
            prev_keys = { "[c", ",tL" },
            next = ts_next("@call.outer"),
            prev = ts_prev("@call.outer"),
        },

        {
            desc = "[a]ssignment",
            next_keys = { "]a", ",ta" },
            prev_keys = { "[a", ",tA" },
            next = ts_next("@assignment.rhs"),
            prev = ts_prev("@assignment.rhs"),
        },

        {
            desc = "co[N]ditional",
            next_keys = { "]N", ",tn" },
            prev_keys = { "[N", ",tN" },
            next = ts_next("@conditional.inner"),
            prev = ts_prev("@conditional.inner"),
        },

        {
            desc = "[C]lass",
            next_keys = { "]C", ",tc" },
            prev_keys = { "[C", ",tC" },
            next = ts_next("@class.inner"),
            prev = ts_prev("@class.inner"),
        },

        {
            desc = "[f]unction",
            next_keys = { "]f", ",tf" },
            prev_keys = { "[f", ",tF" },
            next = ts_next("@function.outer"),
            prev = ts_prev("@function.outer"),
        },

        {
            desc = "[n]ode",
            next_keys = { "]n", ",tn" },
            prev_keys = { "[n", ",tN" },
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

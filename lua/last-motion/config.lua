local search = require("last-motion.search")
local ts_utils = require("nvim-treesitter.ts_utils") -- from nvim-treesitter/nvim-treesitter-textobjects
local utils = require("last-motion.utils")

return {
    -- how many motions to remember
    max_motions = 10,

    definitions = {
        -- Ideally this would have every pair of motions

        -- it doesn't matter which key in a pair is next or prev, as direction is preserved

        -- with just next and prev, those keys should behave as normal
        -- as they will be replaced with new keymaps, that just call those keys and remember the motion
        -- There is no reason to have new keymaps for such basic motions.
        { next = "w", prev = "b" },
        { next = "W", prev = "B" },
        { next = "}", prev = "{" },
        { next = ")", prev = "(" },
        { next = "e", prev = "ge" },
        { next = "E", prev = "gE" },

        -- next_key and prev_key: can process control keys too
        { next = "<C-d>", prev = "<C-u>" },
        { next = "<C-f>", prev = "<C-b>" },
        { next = "<C-i>", prev = "<C-o>" },

        -- character motions probably aren't very useful
        { next = "h", prev = "l" },
        { next = "j", prev = "k" },

        -- these ones only go back and forth between two positions, so pretty pointless
        { next = "g_", prev = "^" },
        { next = "$", prev = "0" },
        { next = "G", prev = "gg" },

        -- next_key and prev_key: when there's existing keys to override
        -- default keymaps are with [ and ] prefixes, as that's an established pattern in neovim
        -- New keymaps are added to be more consistent
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

        -- next_func and prev_func: when there's a function to call instead of a key
        -- These need new keymaps, as they don't already ones
        {
            desc = "[d]iagnostic",
            next = "]d",
            prev = "[d",
            next_func = vim.diagnostic.goto_next,
            prev_func = vim.diagnostic.goto_prev,
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

        -- pending: for operator pending, it will wait until the following key is entered
        -- maybe it's only a special case for fFtT ?
        { next = "f", prev = "F", pending = true },
        { next = "t", prev = "T", pending = true },

        -- search has a few special cases
        -- command: for commands that are a special case and don't need to create any keymaps
        { command = "/", next = "n", prev = "N" },
        { command = "?", next = "n", prev = "N" },
        -- existing keys, but need to use a new implementation function to deal with starting a new search vs continuing a search
        -- local search = require("last-motion.search") -- import is required
        {
            desc = "search",
            next = "*",
            prev = "#",
            next_func = search.next_search,
            prev_func = search.prev_search,
        },
        -- adds key to get back to recent search results after other movements
        -- this is needed if you override n and N with repeating motions
        {
            desc = "recent [s]earch",
            next = "]s",
            prev = "[s",
            next_func = search.next_for_recent_search,
            prev_func = search.prev_for_recent_search,
        },

        -- TODO: can actual command motions be repeated?
        -- { command = ":bnext", next = ":bnext", prev = ":bprev" },

        -- treesitter functions that are builtin to neovim
        -- local utils = require("last-motion.utils") -- import is required
        {
            desc = "[a]ttribute",
            next = "]a",
            prev = "[a",
            next_func = utils.ts_next("@attribute.inner"),
            prev_func = utils.ts_prev("@attribute.inner"),
        },
        {
            desc = "fram[e]",
            next = "]e",
            prev = "[e",
            next_func = utils.ts_next("@frame.inner"),
            prev_func = utils.ts_prev("@frame.inner"),
        },
        {
            desc = "c[o]mment",
            next = "]o",
            prev = "[o",
            next_func = utils.ts_next("@comment.outer"),
            prev_func = utils.ts_prev("@comment.outer"),
        },
        {
            desc = "bloc[k]",
            next = "]k",
            prev = "[k",
            next_func = utils.ts_next("@block.inner"),
            prev_func = utils.ts_prev("@block.inner"),
        },
        {
            desc = "[r]eturn",
            next = "]r",
            prev = "[r",
            next_func = utils.ts_next("@return.inner"),
            prev_func = utils.ts_prev("@return.inner"),
        },
        {
            desc = "[p]arameter",
            next = "]p",
            prev = "[p",
            next_func = utils.ts_next("@parameter.inner"),
            prev_func = utils.ts_prev("@parameter.inner"),
        },
        {
            desc = "[c]all",
            next = "]c",
            prev = "[c",
            next_func = utils.ts_next("@call.outer"),
            prev_func = utils.ts_prev("@call.outer"),
        },
        {
            desc = "[a]ssignment",
            next = "]a",
            prev = "[a",
            next_func = utils.ts_next("@assignment.rhs"),
            prev_func = utils.ts_prev("@assignment.rhs"),
        },
        {
            desc = "co[N]ditional",
            next = "]N",
            prev = "[N",
            next_func = utils.ts_next("@conditional.inner"),
            prev_func = utils.ts_prev("@conditional.inner"),
        },
        {
            desc = "[C]lass",
            next = "]C",
            prev = "[C",
            next_func = utils.ts_next("@class.inner"),
            prev_func = utils.ts_prev("@class.inner"),
        },
        {
            desc = "[f]unction",
            next = "]f",
            prev = "[f",
            next_func = utils.ts_next("@function.outer"),
            prev_func = utils.ts_prev("@function.outer"),
        },

        -- An attempt at moving through abstract treesitter nodes
        -- local ts_utils = require("nvim-treesitter.ts_utils") -- import is required
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

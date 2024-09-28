local search = require("last-motion.search")

return {
    -- it doesn't matter which key in a pair is next or prev, as direction is preserved
    default_definitions = {
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
    },
}

local ts_utils = require("nvim-treesitter.ts_utils") -- from nvim-treesitter/nvim-treesitter-textobjects
local search = require("last-motion.search")
local utils = require("last-motion.utils")

return {
  -- how many motions to remember
  max_motions = 10,
  -- use n and N for next and previous
  default_next_previous_keys = true,

  -- Ideally this would have every pair of motions
  -- it doesn't matter which key in a pair is next or prev, as direction is preserved

  --- motions that have existing keymaps
  --- for just basic keys
  --- with just next and prev, those keys should behave as normal
  --- as they will be replaced with new keymaps, that just call those keys and remember the motion
  key_motions = {
    { next = "w", prev = "b" },
    { next = "W", prev = "B" },
    { next = "}", prev = "{" },
    { next = ")", prev = "(" },
    { next = "e", prev = "ge" },
    { next = "E", prev = "gE" },
    { next = "h", prev = "l" },
    { next = "j", prev = "k" },

    -- next and prev can process control keys too
    { next = "<C-d>", prev = "<C-u>" },
    { next = "<C-f>", prev = "<C-b>" },
    { next = "zj", prev = "zk" },
    { next = "<C-w>w", prev = "<C-w>W" },

    -- these ones only go back and forth between two positions, so pretty pointless
    { next = "g_", prev = "^" },
    { next = "$", prev = "0" },
    { next = "G", prev = "gg" },
  },

  --- motions that are operator pending
  pending_key_motions = {
    -- use pending for operator pending keys, so it will wait until the following key is entered
    -- maybe it's only a special case for fFtT ?
    { next = "f", prev = "F" },
    { next = "t", prev = "T" },
  },

  --- motions that trigger CmdLineLeave events, pretty much just search
  cmd_motions = {
    -- search has a few special cases
    -- uses command for keys that are a special case that don't need to create new keymaps
    { command = "/", next = "n", prev = "N" },
    { command = "?", next = "n", prev = "N" },
  },

  --- motions that are called with functions
  --- desc is only to work with which-key
  --- next/prev are just used as the name of the motion for history
  --- new keymaps are assumed to use [ and ] prefixes, inspired by vim-unimpaired
  func_motions = {
    {
      next = "<C-i>",
      prev = "<C-o>",
      next_func = function()
        -- C-i is a special case, it's the same as tab, so it requires feedkeys
        local cmd = vim.api.nvim_replace_termcodes("<C-i>", true, true, true)
        vim.api.nvim_feedkeys(cmd, "n", true)
      end,
      prev_func = function()
        local cmd = vim.api.nvim_replace_termcodes("<C-o>", true, true, true)
        vim.cmd("normal! " .. cmd)
      end,
    },
    {
      -- search has existing keys, but need to use a new implementation function to deal with starting a new search vs continuing a search
      -- local search = require("last-motion.search") -- import is required
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

    -- these will be default keymaps soon, so could be moved to key_motions
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
  },

  --- treesitter functions from nvim-treesitter-textobjects
  treesitter_motions = {
    -- already taken
    -- ib iB ip is it iw iW i<brackets and quotes>
    -- ab aB ap as at aw aW a<brackets and quotes>

    { key = "ia", desc = "[a]ssignment", query = "@assignment.inner" },
    { key = "aa", desc = "[a]ssignment", query = "@assignment.outer" },
    -- TODO find better keys for rhs/lhs
    { key = "iR", desc = "assignment [R]hs", query = "@assignment.rhs" },
    { key = "iL", desc = "assignment [L]hs", query = "@assignment.lhs" },

    { key = "iA", desc = "[a]ttribute", query = "@attribute.inner" },
    { key = "aA", desc = "[a]ttribute", query = "@attribute.outer" },

    { key = "ik", desc = "bloc[k]", query = "@block.inner" },
    { key = "ak", desc = "bloc[k]", query = "@block.outer" },

    { key = "ic", desc = "[c]all", query = "@call.inner" },
    { key = "ac", desc = "[c]all", query = "@call.outer" },

    { key = "iC", desc = "[C]lass", query = "@class.inner" },
    { key = "aC", desc = "[C]lass", query = "@class.outer" },

    { key = "io", desc = "c[o]mment", query = "@comment.inner" },
    { key = "ao", desc = "c[o]mment", query = "@comment.outer" },

    { key = "in", desc = "co[n]ditional", query = "@conditional.inner" },
    { key = "an", desc = "co[n]ditional", query = "@conditional.outer" },

    { key = "ie", desc = "fram[e]", query = "@frame.inner" },
    { key = "ae", desc = "fram[e]", query = "@frame.outer" },

    { key = "if", desc = "[f]unction", query = "@function.inner" },
    { key = "af", desc = "[f]unction", query = "@function.outer" },

    { key = "il", desc = "[l]oop", query = "@loop.inner" },
    { key = "al", desc = "[l]oop", query = "@loop.outer" },

    { key = "iN", desc = "[N]umber", query = "@number.inner" },

    { key = "iP", desc = "[P]arameter", query = "@parameter.inner" },
    { key = "aP", desc = "[P]arameter", query = "@parameter.outer" },

    { key = "ig", desc = "re[g]ex", query = "@regex.inner" },
    { key = "ag", desc = "pe[g]ex", query = "@regex.outer" },

    { key = "ir", desc = "[r]eturn", query = "@return.inner" },
    { key = "ar", desc = "[r]eturn", query = "@return.outer" },

    { key = "iO", desc = "sc[O]pename", query = "@scopename.inner" },

    { key = "aS", desc = "[S]tatement", query = "@statement.outer" },
  },
}

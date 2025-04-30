local search = require("last-motion.search")

return {
  -- how many motions to remember
  max_motions = 10,
  -- use n and N for next and previous
  default_next_previous_keys = true,
  -- if true, imports keymaps from caspersg/square-motions.nvim
  square_motions = true,
  -- if true, imports textobject keymaps from caspersg/square-motions.nvim
  textobjects = true,
  -- if true, adds operator pending keymaps, unless operator_pending = true
  add_operator_pending_keymaps = true,

  -- Ideally this would have every pair of motions
  -- it doesn't matter which key in a pair is next or prev, as direction is preserved

  --- motions that have existing keymaps
  --- for just basic keys
  --- with just next and prev, those keys should behave as normal
  --- as they will be replaced with new keymaps, that just call those keys and remember the motion
  key_motions = {
    -- not very useful
    -- { next = "w", prev = "b", operator_pending = true },
    -- { next = "W", prev = "B", operator_pending = true },
    -- { next = "e", prev = "ge", operator_pending = true },
    -- { next = "E", prev = "gE", operator_pending = true },
    -- do you really want to remember single character movements? Could be useful with counts
    -- { next = "h", prev = "l", operator_pending = true },
    -- { next = "j", prev = "k", operator_pending = true },

    { next = "}", prev = "{", operator_pending = true },
    { next = ")", prev = "(", operator_pending = true },

    -- new default keymaps from neovim 0.11
    { next = "]b", prev = "[b", desc = "[b]uffer", operator_pending = true },
    { next = "]q", prev = "[q", desc = "[q]uickfix", operator_pending = true },
    -- other new default keymaps are overridden by square-motions.nvim

    { next = "]m", prev = "[m", desc = "[m]ethod", operator_pending = true },

    { next = "g,", prev = "g;", operator_pending = true },

    -- next and prev can process control keys too
    { next = "<C-d>", prev = "<C-u>", desc = "half scroll" },
    { next = "<C-f>", prev = "<C-b>", desc = "scroll" },

    -- these ones only go back and forth between two positions, so pretty pointless
    -- { next = "g_", prev = "^", operator_pending = true },
    -- { next = "$", prev = "0", operator_pending = true },
    -- { next = "G", prev = "gg", operator_pending = true },
  },

  --- motions that wait for another char
  read_char_motions = {
    -- it will wait until the following key is entered
    -- maybe it's only a special case for fFtT ?
    { next = "f", prev = "F", operator_pending = true },
    { next = "t", prev = "T", operator_pending = true },
  },

  --- motions that trigger CmdLineLeave events, pretty much just search
  cmd_motions = {
    -- search has a few special cases
    -- uses command for keys that are a special case that don't need to create new keymaps
    { command = "/", next = "n", prev = "N", operator_pending = true },
    { command = "?", next = "n", prev = "N", operator_pending = true },
  },

  --- motions that are called with functions
  --- desc is only to work with which-key
  --- next/prev are just used as the name of the motion for history
  --- new keymaps are assumed to use [ and ] prefixes, inspired by vim-unimpaired
  func_motions = {
    {
      -- search has existing keys, but need to use a new implementation function to deal with starting a new search vs continuing a search
      -- local search = require("last-motion.search") -- import is required
      next = "*",
      prev = "#",
      next_func = search.next_search,
      prev_func = search.prev_search,
      operator_pending = true,
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
  },
}

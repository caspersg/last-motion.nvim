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
    { next = "]m", prev = "[m", desc = "[m]ethod" },

    -- next and prev can process control keys too
    { next = "<C-d>", prev = "<C-u>" },
    { next = "<C-f>", prev = "<C-b>" },

    -- these ones only go back and forth between two positions, so pretty pointless
    { next = "g_", prev = "^" },
    { next = "$", prev = "0" },
    { next = "G", prev = "gg" },
  },

  --- motions that wait for another char
  read_char_motions = {
    -- it will wait until the following key is entered
    -- maybe it's only a special case for fFtT ?
    -- TODO: fix off by one error
    { next = "f", prev = "F", operator_pending = true },
    { next = "t", prev = "T", operator_pending = true },
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
  },
}

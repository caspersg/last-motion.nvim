# last-motion.nvim
Repeat the last motion or reverse the last motion in Neovim.

Like . (dot) repeat, but for motions.

So you can:
- repeat the last motion
- reverse the last motion
- view motion history
- repeat numbered motion from history
- add a count prefix to a repeat

Motion keymaps are replaced with next/prev pairs of keymaps that remember a history of previous motions.
It remembers direction, so for example 'n' after '?' will continue search upwards through the document.

Some uses:
- ']b' (:bnext keymap), then use n and N to move backwards and forwards through buffers
- '2}' then scroll by 2 paragraphs with 'n' and 'N', or scroll by 4 paragraphs with '2n'
- ']s' continue the most recent search

I've done my best to add every motion in neovim, including treesitter motions like "@attribute.inner".
hjkl seem pretty pointless to include, but you can repeat '10j' with 'n', go back up by 10 lines with N.

TODO add usage and a video

## Installation

**[Lazy.nvim](https://github.com/folke/lazy.nvim)**

```lua
{
  "caspersg/last-motion.nvim",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter" },
    { "nvim-treesitter/nvim-treesitter-textobjects" },
  },
  config = function()
    local lm = require("last-motion")
    lm.setup({
        -- empty to keep default config
    })
  end
}

```

### Additional keymaps

I also add these keymaps, which assume [ and ] prefixes from the default config

```lua
-- I add keymaps for repeating numbered motions from the history, default is 0-9
for i = 0, 9 do
  vim.keymap.set({ "n", "v" }, "]" .. i, function()
    lm.forward(i)
  end, { desc = "repeat " .. i })
  vim.keymap.set({ "n", "v" }, "[" .. i, function()
    lm.backward(i)
  end, { desc = "repeat " .. i })
end

vim.keymap.set("n", "],", "<cmd>LastMotionsNotify<CR>", { desc = "last motions" })

-- comma "," is not needed anymore, so I like to use it instead of ] as a motion prefix
vim.keymap.set("n", ",", "]", { remap = true })

-- if you want to directly manipulate history, you can get the 1-indexed underlying array
-- eg pop the last motion
table.remove(require("last-motion").history(), 1)
```

## Usage

TODO


## Default Configuration

The default config has definitions for all the builtin motions I could figure out.

Some of the definitions need to import helper functions that you'll need to import.


```lua
local ts_utils = require("nvim-treesitter.ts_utils") -- from nvim-treesitter/nvim-treesitter-textobjects
local search = require("last-motion.search")
local utils = require("last-motion.utils")

require("last-motion").setup({
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
    { next = "<C-i>", prev = "<C-o>" },
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
  --- desc is to work with which-key
  --- next/prev are just used as the name of the motion for history
  --- new keymaps are assumed to use [ and ] prefixes, inspired by vim-unimpaired
  func_motions = {
    {
      -- search has existing keys, but need to use a new implementation function to deal with starting a new search vs continuing a search
      -- local search = require("last-motion.search") -- import is required
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
})
```

## Manual Configuration

If you don't want to use any of the default configurations or keymaps, you can register each motion manually.

```lua
require("last-motion").setup({
  max_motions = 10,
  default_next_previous_keys = false,
  key_motions = {},
  pending_key_motions = {},
  cmd_motions = {},
  func_motions = {},
})
-- Add keymaps for at least forward and backward to do anything useful.
vim.keymap.set({ "n", "v" }, "n", require("last-motion").forward, { desc = "repeat last motion" })
vim.keymap.set({ "n", "v" }, "N", require("last-motion").backward, { desc = "reverse last motion" })

-- add your own keymaps
local mem = require("last-motion").func_motion(
  -- it needs names for next/prev to be shown in the history
  "]T",
  "[T",
  require("todo-comments").jump_next,
  require("todo-comments").jump_prev
)
vim.keymap.set({ "n", "v" }, "]T", mem.next, { desc = "[T]odo" })
vim.keymap.set({ "n", "v" }, "[T", mem.prev, { desc = "[T]odo" })
```


## TODO



## Inspirations

- [vim-unimpaired](https://github.com/tpope/vim-unimpaired)
- [nvim-better-n](https://github.com/jonatan-branting/nvim-better-n)

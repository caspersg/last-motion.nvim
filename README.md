# last-motion.nvim
Repeat the last motion or reverse the last motion in Neovim.

Like . (dot) repeat, but for motions.

So you can:
- repeat the last motion
- reverse the last motion
- view motion history
- repeat motion from history
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

    -- Add keymaps for at least forward and backward to do anything useful.
    vim.keymap.set({ "n", "v" }, "n", lm.forward, { desc = "repeat last motion", noremap = true, silent = true })
    vim.keymap.set({ "n", "v" }, "N", lm.backward, { desc = "reverse last motion", noremap = true, silent = true })

    -- the following optional keymaps assume the default [ and ] prefixes from the default config

    -- I add keymaps for repeating numbered motions from the history, default is 0-9
    for i = 0, 9 do
      vim.keymap.set({ "n", "v" }, "]" .. i, function()
        lm.nth(i)
      end, { desc = "repeat " .. i, noremap = true, silent = true })
    end

    -- I also add a keymap to view the history
    vim.keymap.set("n", "],", function()
      vim.notify(lm.get_last_motions(), vim.log.levels.INFO, { title = "Last Motions" })
    end, { desc = "last motions", noremap = true, silent = true })

    -- comma "," is not needed anymore, so I like to use it instead of ] as a motion prefix
    vim.keymap.set("n", ",", "]", { remap = true })
  end,
}
```

## Usage

TODO


## Default Configuration

The default config has definitions for all the builtin motions I could figure out.

So you'll probably want to exclude some of them, hjkl for example.

Some of the definitions need to import helper functions that you'll need to import.


```lua
local ts_utils = require("nvim-treesitter.ts_utils") -- from nvim-treesitter/nvim-treesitter-textobjects
local search = require("last-motion.search")
local utils = require("last-motion.utils")

require("last-motion").setup({
    -- how many motions to remember
    max_motions = 10,

    definitions = {
        -- Ideally this would have every pair of motions

        -- it doesn't matter which key in a pair is next or prev, as direction is preserved

        -- with just next and prev, those keys should behave as normal
        -- as they will be replaced with new keymaps, that just call those keys and remember the motion
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

        -- these ones only go back and forth between two positions, so pretty pointless
        { next = "g_", prev = "^" },
        { next = "$", prev = "0" },
        { next = "G", prev = "gg" },

        -- use next_key and prev_key when there's existing keys to override
        -- new keymaps are with [ and ] prefixes, inspired by vim-unimpaired
        -- desc is to work with which-key
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

        -- use next_func and prev_func when there's a function to call instead of a key
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

        -- use pending for operator pending keys, so it will wait until the following key is entered
        -- maybe it's only a special case for fFtT ?
        { next = "f", prev = "F", pending = true },
        { next = "t", prev = "T", pending = true },

        -- search has a few special cases
        -- uses command for keys that are a special case that don't need to create new keymaps
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

If you don't want to use any of the default configurations or keymaps, you can register each pair manually.


```lua
require("last-motion").setup({
    max_motions = 10,
    definitions = {}
})

-- you can explicitly register pairs, and write your own keymaps
local mem = require("last-motion").register(
    {
      -- next/prev are still required to name it
      next = ",m",
      prev = ",M",
      next_func = recall.goto_next,
      prev_func = recall.goto_prev,
    },
    true -- this skips adding keymaps
)
if mem then
  vim.keymap.set("n", ",m", mem.next, { desc = "next mark" })
  vim.keymap.set("n", ",M", mem.prev, { desc = "prev mark" })
end

```


## TODO

- recent edits
    - Is there similar for . repeat? show the recent edits and allow to pick from them



## Inspirations

- [vim-unimpaired](https://github.com/tpope/vim-unimpaired)
- [nvim-better-n](https://github.com/jonatan-branting/nvim-better-n)
